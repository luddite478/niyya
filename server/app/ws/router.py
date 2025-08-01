import asyncio
import websockets
import json
import time
import logging
from collections import defaultdict
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Constants
API_TOKEN = os.getenv("API_TOKEN")
print(f"🔑 WebSocket server loaded API_TOKEN: {API_TOKEN}")
MAX_CONNECTIONS_PER_MINUTE = 10
MAX_TOTAL_CLIENTS = 100
MAX_MESSAGE_RATE = 60

# State
clients = {}  # Maps user IDs to WebSocket connections
client_message_rates = defaultdict(lambda: {'count': 0, 'reset_time': time.time() + 60})
connection_attempts = defaultdict(lambda: {'count': 0, 'reset_time': time.time() + 60})

# Chat storage: maps (user1, user2) tuple to list of messages
chats = defaultdict(list)

# --- Utility Functions ---

def is_valid_token(token):
    return token == API_TOKEN

def sanitize_input(text):
    if not isinstance(text, str):
        return ""
    return text.replace('\x00', '').strip()[:1000]

async def send_json(websocket, data, timeout=5.0):
    try:
        await asyncio.wait_for(websocket.send(json.dumps(data)), timeout=timeout)
    except Exception as e:
        logger.debug(f"Failed to send message: {e}")

async def send_error(websocket, error_msg):
    await send_json(websocket, {"type": "error", "message": error_msg})

# --- Rate Limiting ---

def check_connection_rate_limit(client_ip):
    current_time = time.time()
    client_limit = connection_attempts[client_ip]

    if current_time > client_limit['reset_time']:
        client_limit['count'] = 0
        client_limit['reset_time'] = current_time + 60

    if client_limit['count'] >= MAX_CONNECTIONS_PER_MINUTE:
        return False

    client_limit['count'] += 1
    return True

def check_message_rate_limit(client_id):
    current_time = time.time()
    client_limit = client_message_rates[client_id]

    if current_time > client_limit['reset_time']:
        client_limit['count'] = 0
        client_limit['reset_time'] = current_time + 60

    if client_limit['count'] >= MAX_MESSAGE_RATE:
        return False

    client_limit['count'] += 1
    return True

# --- Authentication ---

async def authenticate_client(websocket, client_ip):
    if len(clients) >= MAX_TOTAL_CLIENTS:
        await send_error(websocket, "Server at capacity. Please try again later.")
        return None

    if not check_connection_rate_limit(client_ip):
        await send_error(websocket, "Too many connection attempts. Please wait.")
        return None

    try:
        auth_message = await asyncio.wait_for(websocket.recv(), timeout=10.0)
        if len(auth_message) > 1000:
            await send_error(websocket, "Authentication message too large")
            return None

        auth_data = json.loads(auth_message)
        token = auth_data.get('token')
        client_id = sanitize_input(auth_data.get('client_id', ''))

        if not token or not client_id:
            await send_error(websocket, "Invalid authentication format")
            return None

        if not is_valid_token(token):
            await send_error(websocket, "Invalid authentication token")
            return None

        if len(client_id) < 3 or len(client_id) > 50:
            await send_error(websocket, "Client ID must be between 3-50 characters")
            return None

        if client_id in clients:
            await send_error(websocket, "Client ID already in use")
            return None

        return client_id
    except (asyncio.TimeoutError, json.JSONDecodeError):
        await send_error(websocket, "Authentication failed")
        return None
    except Exception as e:
        logger.debug(f"Authentication error: {e}")
        await send_error(websocket, "Authentication error")
        return None

# --- Chat Utilities ---

def chat_key(user1, user2):
    return tuple(sorted([user1, user2]))

def store_message(sender, recipient, message):
    key = chat_key(sender, recipient)
    chats[key].append({
        "from": sender,
        "to": recipient,
        "message": message,
        "timestamp": int(time.time())
    })

def store_thread_message(sender, recipient, thread_id, thread_title):
    key = chat_key(sender, recipient)
    chats[key].append({
        "from": sender,
        "to": recipient,
        "type": "thread_message",
        "thread_id": thread_id,
        "thread_title": thread_title,
        "message": f"🎵 Shared thread: {thread_title}",
        "timestamp": int(time.time())
    })

def get_chat_history(user1, user2):
    key = chat_key(user1, user2)
    return chats.get(key, [])

# --- Message Handling ---

async def handle_direct_message(websocket, client_id, message):
    if "::" not in message:
        await send_error(websocket, "Invalid format. Use: target_id::your_message")
        return

    target_id, real_msg = map(sanitize_input, message.split("::", 1))
    if not target_id or not real_msg:
        await send_error(websocket, "Target ID and message cannot be empty")
        return

    store_message(client_id, target_id, real_msg)

    target_ws = clients.get(target_id)
    if target_ws:
        try:
            await send_json(target_ws, {
                "type": "message",
                "from": client_id,
                "message": real_msg,
                "timestamp": int(time.time())
            })
        except Exception as e:
            logger.error(f"Delivery error from {client_id} to {target_id}: {e}")

    await send_json(websocket, {
        "type": "delivered",
        "to": target_id,
        "message": "Message stored and sent (if user online)"
    })

async def handle_special_command(websocket, client_id, message_obj):
    msg_type = message_obj.get("type")
    if msg_type == "list_users":
        await send_json(websocket, {
            "type": "online_users",
            "users": list(clients.keys())
        })
        return True
    elif msg_type == "chat_history":
        with_user = sanitize_input(message_obj.get("with", ""))
        if not with_user:
            await send_error(websocket, "Missing 'with' field in chat_history request")
            return True
        history = get_chat_history(client_id, with_user)
        await send_json(websocket, {
            "type": "chat_history",
            "with": with_user,
            "messages": history
        })
        return True
    elif msg_type == "thread_invitation":
        # Handle thread invitation notification
        target_user = sanitize_input(message_obj.get("target_user", ""))
        thread_id = sanitize_input(message_obj.get("thread_id", ""))
        thread_title = sanitize_input(message_obj.get("thread_title", ""))
        from_user_name = sanitize_input(message_obj.get("from_user_name", ""))
        
        if not target_user or not thread_id:
            await send_error(websocket, "Missing required fields for thread invitation")
            return True
            
        # Send real-time notification to target user if online
        target_ws = clients.get(target_user)
        if target_ws:
            try:
                await send_json(target_ws, {
                    "type": "thread_invitation",
                    "from_user_id": client_id,
                    "from_user_name": from_user_name,
                    "thread_id": thread_id,
                    "thread_title": thread_title,
                    "timestamp": int(time.time())
                })
                logger.info(f"Sent thread invitation notification from {client_id} to {target_user}")
            except Exception as e:
                logger.error(f"Failed to send thread invitation to {target_user}: {e}")
        else:
            logger.info(f"User {target_user} not online, invitation stored in database")
        
        # Confirm to sender
        await send_json(websocket, {
            "type": "invitation_sent",
            "to": target_user,
            "thread_id": thread_id,
            "message": "Invitation sent successfully"
        })
        return True
    elif msg_type == "thread_message":
        # Handle thread sharing notification
        target_user = sanitize_input(message_obj.get("target_user", ""))
        thread_id = sanitize_input(message_obj.get("thread_id", ""))
        thread_title = sanitize_input(message_obj.get("thread_title", ""))
        
        if not target_user or not thread_id:
            await send_error(websocket, "Missing required fields for thread message")
            return True
            
        # Store as a special message type
        store_thread_message(client_id, target_user, thread_id, thread_title)
        
        # Send real-time notification to target user if online
        target_ws = clients.get(target_user)
        if target_ws:
            try:
                await send_json(target_ws, {
                    "type": "thread_message",
                    "from": client_id,
                    "thread_id": thread_id,
                    "thread_title": thread_title,
                    "timestamp": int(time.time())
                })
            except Exception as e:
                logger.error(f"Failed to send thread message to {target_user}: {e}")
        
        # Confirm to sender
        await send_json(websocket, {
            "type": "message_sent",
            "to": target_user,
            "thread_id": thread_id,
            "message": "Thread shared successfully"
        })
        return True
    return False

async def process_message(websocket, client_id, message):
    if not check_message_rate_limit(client_id):
        await send_error(websocket, "Message rate limit exceeded. Please slow down.")
        return

    if len(message) > 2000:
        await send_error(websocket, "Message too large")
        return

    try:
        parsed = json.loads(message)
        if isinstance(parsed, dict):
            handled = await handle_special_command(websocket, client_id, parsed)
            if handled:
                return
    except Exception:
        pass  # Not a JSON object — treat as a string message

    await handle_direct_message(websocket, client_id, sanitize_input(message))

# --- Connection Lifecycle ---

async def register_client(client_id, websocket):
    clients[client_id] = websocket
    logger.info(f"{client_id} connected (total: {len(clients)})")
    await send_json(websocket, {
        "type": "connected",
        "message": f"Successfully connected as {client_id}",
        "active_clients": len(clients)
    })

def unregister_client(client_id):
    if client_id in clients:
        del clients[client_id]
        logger.info(f"{client_id} disconnected (remaining: {len(clients)})")

async def handler(websocket):
    client_id = None
    client_ip = websocket.remote_address[0] if websocket.remote_address else "unknown"
    logger.info(f"New connection from {client_ip}")

    try:
        client_id = await authenticate_client(websocket, client_ip)
        if not client_id:
            return

        await register_client(client_id, websocket)

        async for message in websocket:
            await process_message(websocket, client_id, message)

    except websockets.exceptions.ConnectionClosed:
        pass
    except Exception as e:
        logger.error(f"Handler error for {client_id or client_ip}: {e}")
    finally:
        if client_id:
            unregister_client(client_id)

# --- API Integration Functions ---

async def send_thread_invitation_notification(target_user_id, from_user_id, from_user_name, thread_id, thread_title):
    """Send thread invitation notification to user if they're online"""
    target_ws = clients.get(target_user_id)
    if target_ws:
        try:
            await send_json(target_ws, {
                "type": "thread_invitation",
                "from_user_id": from_user_id,
                "from_user_name": from_user_name,
                "thread_id": thread_id,
                "thread_title": thread_title,
                "timestamp": int(time.time())
            })
            logger.info(f"Sent thread invitation notification from {from_user_id} to {target_user_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to send thread invitation to {target_user_id}: {e}")
            return False
    else:
        logger.info(f"User {target_user_id} not online, invitation notification not sent")
        return False

def get_online_clients():
    """Get list of online client IDs"""
    return list(clients.keys())

def is_user_online(user_id):
    """Check if a user is currently online"""
    return user_id in clients

# --- Entry Point ---

async def start_websocket_server():
    logger.info("Starting WebSocket server at ws://0.0.0.0:8765")
    async with websockets.serve(
        handler,
        "0.0.0.0",
        8765,
        close_timeout=10,
        max_size=2**20,
        max_queue=32,
        compression=None,
        ping_interval=20,
        ping_timeout=10
    ):
        await asyncio.Future()
