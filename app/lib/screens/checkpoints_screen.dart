import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/threads_state.dart';
import '../state/sequencer_state.dart';

import '../services/threads_service.dart';
import '../services/users_service.dart';
import 'user_profile_screen.dart';

// Telephone book color scheme - same as users screen
class PhoneBookColors {
  static const Color pageBackground = Color.fromARGB(255, 250, 248, 236); // Aged paper yellow
  static const Color entryBackground = Color.fromARGB(255, 251, 247, 231); // Slightly lighter
  static const Color text = Color(0xFF2C2C2C); // Dark gray/black text
  static const Color lightText = Color.fromARGB(255, 161, 161, 161); // Lighter text
  static const Color border = Color(0xFFE8E0C7); // Aged border
  static const Color onlineIndicator = Color(0xFF8B4513); // Brown instead of purple
  static const Color buttonBackground = Color.fromARGB(255, 246, 244, 226); // Khaki for main button
  static const Color buttonBorder = Color.fromARGB(255, 248, 246, 230); // Golden border
  static const Color checkpointBackground = Color.fromARGB(255, 248, 245, 228); // Checkpoint cards
  static const Color currentUserCheckpoint = Color.fromARGB(255, 240, 235, 210); // Current user checkpoints
}

class CheckpointsScreen extends StatefulWidget {
  final String threadId;
  final bool highlightNewest;
  
  const CheckpointsScreen({
    super.key,
    required this.threadId,
    this.highlightNewest = false,
  });

  @override
  State<CheckpointsScreen> createState() => _CheckpointsScreenState();
}

class _CheckpointsScreenState extends State<CheckpointsScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  AnimationController? _colorAnimationController;
  Animation<Color?>? _colorAnimation;
  String? _highlightCheckpointId;

  // Chat layout configuration - easily adjustable percentages
  static const double _currentUserLeftMarginPercent = 0.25;   // 25% margin on left for current user messages
  static const double _otherUserRightMarginPercent = 0.25;    // 25% margin on right for other user messages
  static const double _messageMaxWidthPercent = 0.7;         // 70% max width for message bubbles
  static const double _baseMarginPercent = 0.02;             // 2% base margin (minimum spacing)

  @override
  void initState() {
    super.initState();
    
    // Set up color transition animation if highlighting newest checkpoint
    if (widget.highlightNewest) {
      _colorAnimationController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );
      
      // Define colors for the animation
      final Color originalColor = PhoneBookColors.checkpointBackground;
      final Color highlightColor = Colors.lightBlue.withOpacity(0.3);
      
      _colorAnimation = ColorTween(
        begin: originalColor,
        end: highlightColor,
      ).animate(CurvedAnimation(
        parent: _colorAnimationController!,
        curve: Curves.easeInOut,
      ));
      
      // Start color transition after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Forward to light blue, then reverse back to original
          _colorAnimationController?.forward().then((_) {
            if (mounted) {
              _colorAnimationController?.reverse();
            }
          });
        }
      });
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshThreadData();
      _scrollToBottom();
    });
  }

  Future<void> _refreshThreadData() async {
    try {
      final threadsState = context.read<ThreadsState>();
      
      // Fetch latest thread data from server
      final latestThread = await ThreadsService.getThread(widget.threadId);
      if (latestThread != null) {
        // Update the current thread in ThreadsState with fresh data
        threadsState.setActiveThread(latestThread);
        debugPrint('✅ Refreshed thread data: ${latestThread.checkpoints.length} checkpoints');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to refresh thread data: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }



  void _playCheckpointRender(ProjectCheckpoint checkpoint) {
    // Check if there are any renders available
    if (checkpoint.snapshot.audio.renders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No audio renders available for this checkpoint'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get the latest render
    final latestRender = checkpoint.snapshot.audio.renders.last;
    
    // Show a message that playback would start (placeholder for actual audio playback)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing render: ${latestRender.url ?? 'Latest render'}'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: Implement actual audio playback
    // This would typically involve:
    // 1. Loading the audio file from the render URL
    // 2. Using an audio player package like audioplayers
    // 3. Starting playback
    
    debugPrint('🎵 Playing checkpoint render: ${latestRender.url}');
  }

  bool _isUserComment(String comment) {
    // Filter out auto-generated comments
    final autoGeneratedPatterns = [
      'Published from mobile app',
      'Created project',
      'Started collaboration',
      'Started working on sequencer project',
    ];
    
    // Check if comment matches auto-generated patterns
    for (final pattern in autoGeneratedPatterns) {
      if (comment.contains(pattern)) {
        return false;
      }
    }
    
    // Filter out timestamp-based comments (like "update 28/06/2025 14:00")
    final timestampPattern = RegExp(r'^update \d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$', caseSensitive: false);
    if (timestampPattern.hasMatch(comment.trim())) {
      return false;
    }
    
    // Filter out very short generic comments
    if (comment.trim().length < 3) {
      return false;
    }
    
    return true; // Show meaningful user comments
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomHeader(context),
      backgroundColor: PhoneBookColors.pageBackground,
      body: Consumer2<ThreadsState, SequencerState>(
        builder: (context, threadsState, sequencerState, child) {
          final thread = threadsState.currentThread;
          
          if (thread == null) {
            return Center(
              child: Text(
                'Project not found',
                style: GoogleFonts.sourceSans3(
                  color: PhoneBookColors.lightText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          if (thread.checkpoints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: PhoneBookColors.lightText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No checkpoints yet',
                    style: GoogleFonts.sourceSans3(
                      color: PhoneBookColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save your progress to create checkpoints',
                    style: GoogleFonts.sourceSans3(
                      color: PhoneBookColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: thread.checkpoints.length,
            itemBuilder: (context, index) {
              final checkpoint = thread.checkpoints[index];
              final isCurrentUser = checkpoint.userId == threadsState.currentUserId;
              final isNewest = index == thread.checkpoints.length - 1;
              final shouldHighlight = widget.highlightNewest && isNewest && _colorAnimation != null;
              
              // Apply color animation to newest checkpoint if highlighting enabled
              return shouldHighlight
                  ? AnimatedBuilder(
                      animation: _colorAnimation!,
                      builder: (context, child) {
                        return _buildCheckpointMessage(
                          context,
                          checkpoint,
                          isCurrentUser,
                          sequencerState,
                          threadsState,
                          highlightColor: _colorAnimation!.value,
                        );
                      },
                    )
                  : _buildCheckpointMessage(
                      context,
                      checkpoint,
                      isCurrentUser,
                      sequencerState,
                      threadsState,
                    );
            },
          );
        },
      ),
    );
  }

  Widget _buildCheckpointMessage(
    BuildContext context,
    ProjectCheckpoint checkpoint,
    bool isCurrentUser,
    SequencerState sequencerState,
    ThreadsState threadsState,
    {Color? highlightColor}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Regular messenger spacing
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: highlightColor ?? (isCurrentUser 
              ? PhoneBookColors.currentUserCheckpoint 
              : PhoneBookColors.checkpointBackground),
          borderRadius: BorderRadius.circular(2), // Sharp corners
          border: Border.all(
            color: PhoneBookColors.border,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(12), // Regular messenger padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User name and timestamp header
            Row(
              children: [
                Text(
                  checkpoint.userName,
                  style: GoogleFonts.sourceSans3(
                    color: PhoneBookColors.text,
                    fontSize: 14, // Regular size
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(checkpoint.timestamp),
                  style: GoogleFonts.sourceSans3(
                    color: PhoneBookColors.lightText,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8), // Regular spacing
            
            // Checkpoint content (clickable)
            GestureDetector(
              onTap: () => _applyCheckpoint(context, checkpoint, sequencerState),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sound grid preview
                  _buildSoundGridPreview(checkpoint.snapshot),
                  
                  const SizedBox(height: 8), // Regular spacing
                  
                  // Media controls and info
                  Container(
                    padding: const EdgeInsets.all(8), // Regular padding
                    decoration: BoxDecoration(
                      color: PhoneBookColors.buttonBackground,
                      borderRadius: BorderRadius.circular(2), // Sharp corners
                      border: Border.all(
                        color: PhoneBookColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Play button for latest render
                        GestureDetector(
                          onTap: () => _playCheckpointRender(checkpoint),
                          child: Container(
                            width: 28, // Regular size
                            height: 28,
                            decoration: BoxDecoration(
                              color: PhoneBookColors.onlineIndicator,
                              borderRadius: BorderRadius.circular(2), // Sharp corners
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Duration info
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: PhoneBookColors.lightText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(checkpoint.snapshot.audio.duration),
                          style: GoogleFonts.sourceSans3(
                            color: PhoneBookColors.lightText,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Renders count (if any)
                        if (checkpoint.snapshot.audio.renders.isNotEmpty) ...[
                          Icon(
                            Icons.audiotrack,
                            size: 14,
                            color: PhoneBookColors.lightText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${checkpoint.snapshot.audio.renders.length}',
                            style: GoogleFonts.sourceSans3(
                              color: PhoneBookColors.lightText,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundGridPreview(SequencerSnapshot snapshot) {
    if (snapshot.audio.sources.isEmpty || 
        snapshot.audio.sources.first.scenes.isEmpty ||
        snapshot.audio.sources.first.scenes.first.layers.isEmpty) {
      return Container(
        height: 80, // Regular messenger size
        decoration: BoxDecoration(
          color: PhoneBookColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2), // Sharp corners
          border: Border.all(
            color: PhoneBookColors.border,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            'Empty Project',
            style: GoogleFonts.sourceSans3(
              color: PhoneBookColors.lightText,
              fontSize: 12, // Regular text size
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    final scene = snapshot.audio.sources.first.scenes.first;
    final layers = scene.layers;
    
    return Container(
      height: 80, // Regular messenger size
      decoration: BoxDecoration(
        color: PhoneBookColors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2), // Sharp corners
        border: Border.all(
          color: PhoneBookColors.border,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8), // Regular padding
        child: Column(
          children: [
            Text(
              'Sound Grid Preview',
              style: GoogleFonts.sourceSans3(
                color: PhoneBookColors.lightText,
                fontSize: 10, // Small header text
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4), // Regular spacing
            Expanded(
              child: Row(
                children: List.generate(
                  layers.length.clamp(0, 4), // Show max 4 layers
                  (layerIndex) {
                    final layer = layers[layerIndex];
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _getLayerColor(layerIndex),
                          borderRadius: BorderRadius.circular(2), // Sharp corners
                        ),
                        child: Column(
                          children: List.generate(
                            layer.rows.length.clamp(0, 8), // Show max 8 rows
                            (rowIndex) {
                              final row = layer.rows[rowIndex];
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(0.5),
                                  decoration: BoxDecoration(
                                    color: row.cells.isNotEmpty && row.cells.any((cell) => cell.sample?.hasSample == true)
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Color _getLayerColor(int layerIndex) {
    final colors = [
      const Color(0xFF3b82f6),
      const Color(0xFF10b981),
      const Color(0xFFf59e0b),
      const Color(0xFFef4444),
    ];
    return colors[layerIndex % colors.length];
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDuration(double duration) {
    final minutes = (duration / 60).floor();
    final seconds = (duration % 60).floor();
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void _applyCheckpoint(
    BuildContext context,
    ProjectCheckpoint checkpoint,
    SequencerState sequencerState,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PhoneBookColors.entryBackground,
        title: Text(
          'Apply Checkpoint',
          style: GoogleFonts.sourceSans3(
            color: PhoneBookColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will replace your current project with this checkpoint.\n\nYour current work will be lost unless saved.',
          style: GoogleFonts.sourceSans3(
            color: PhoneBookColors.lightText,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.sourceSans3(
                color: PhoneBookColors.lightText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              sequencerState.applySnapshot(checkpoint.snapshot);
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to sequencer
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Applied checkpoint successfully',
                    style: GoogleFonts.sourceSans3(fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: PhoneBookColors.onlineIndicator,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PhoneBookColors.buttonBackground,
              foregroundColor: PhoneBookColors.text,
              side: BorderSide(color: PhoneBookColors.buttonBorder),
            ),
            child: Text(
              'Apply',
              style: GoogleFonts.sourceSans3(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }



  PreferredSizeWidget _buildCustomHeader(BuildContext context) {
    return AppBar(
      backgroundColor: PhoneBookColors.entryBackground,
      foregroundColor: PhoneBookColors.text,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: PhoneBookColors.text),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Invite Collaborators button (User + plus icon)
        IconButton(
          icon: Icon(Icons.person_add, color: PhoneBookColors.text),
          onPressed: () => _showInviteCollaboratorsModal(context),
        ),
        // Publish button
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: ElevatedButton(
            onPressed: () => _showPublishModal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: PhoneBookColors.buttonBackground,
              foregroundColor: PhoneBookColors.text,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(
                color: PhoneBookColors.buttonBorder,
                width: 1,
              ),
              elevation: 1,
            ),
            child: Text(
              'Publish',
              style: GoogleFonts.sourceSans3(
                color: PhoneBookColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showPublishModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: const _PublishModalBottomSheet(),
      ),
    );
  }

  void _showInviteCollaboratorsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: const _InviteCollaboratorsModalBottomSheet(),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _colorAnimationController?.dispose();
    super.dispose();
  }
}

// Enhanced version that shows user context and common threads
class CheckpointsScreenWithUserContext extends StatefulWidget {
  final String threadId;
  final String targetUserId;
  final String targetUserName;
  final List<Thread> commonThreads;
  
  const CheckpointsScreenWithUserContext({
    super.key,
    required this.threadId,
    required this.targetUserId,
    required this.targetUserName,
    required this.commonThreads,
  });

  @override
  State<CheckpointsScreenWithUserContext> createState() => _CheckpointsScreenWithUserContextState();
}

class _CheckpointsScreenWithUserContextState extends State<CheckpointsScreenWithUserContext> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PhoneBookColors.pageBackground,
      body: Column(
        children: [
          // User header with threads button
          _buildUserHeader(),
          
          // Common threads pinned section (if more than 1 common thread)
          if (widget.commonThreads.length > 1)
            _buildCommonThreadsSection(),
          
          // Checkpoints content
          Expanded(
            child: CheckpointsScreen(threadId: widget.threadId),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
      decoration: BoxDecoration(
        color: PhoneBookColors.entryBackground,
        border: Border(
          bottom: BorderSide(color: PhoneBookColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, color: PhoneBookColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          
          // User name with online indicator
          Expanded(
            child: Row(
              children: [
                Text(
                  widget.targetUserName,
                  style: GoogleFonts.sourceSans3(
                    color: PhoneBookColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                // Online indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: PhoneBookColors.onlineIndicator,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          
          // Threads button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userId: widget.targetUserId,
                    userName: widget.targetUserName,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PhoneBookColors.buttonBackground,
              foregroundColor: PhoneBookColors.text,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: PhoneBookColors.buttonBorder),
            ),
            child: Text(
              'Profile',
              style: GoogleFonts.sourceSans3(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommonThreadsSection() {
    // Filter out the current thread from common threads
    final otherCommonThreads = widget.commonThreads
        .where((thread) => thread.id != widget.threadId)
        .toList();
    
    if (otherCommonThreads.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PhoneBookColors.checkpointBackground,
        border: Border(
          bottom: BorderSide(color: PhoneBookColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📌 Other Common Threads',
            style: GoogleFonts.sourceSans3(
              color: PhoneBookColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...otherCommonThreads.map((thread) => _buildPinnedThread(thread)),
        ],
      ),
    );
  }
  
  Widget _buildPinnedThread(Thread thread) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PhoneBookColors.entryBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: PhoneBookColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin, color: PhoneBookColors.lightText, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              thread.title,
              style: GoogleFonts.sourceSans3(
                color: PhoneBookColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Switch to this thread
              final threadsState = Provider.of<ThreadsState>(context, listen: false);
              threadsState.setActiveThread(thread);
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckpointsScreenWithUserContext(
                    threadId: thread.id,
                    targetUserId: widget.targetUserId,
                    targetUserName: widget.targetUserName,
                    commonThreads: widget.commonThreads,
                  ),
                ),
              );
            },
            child: Text(
              'Switch',
              style: GoogleFonts.sourceSans3(
                color: PhoneBookColors.onlineIndicator,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 

// Modal bottom sheet for publish options
class _PublishModalBottomSheet extends StatefulWidget {
  const _PublishModalBottomSheet();

  @override
  State<_PublishModalBottomSheet> createState() => _PublishModalBottomSheetState();
}

class _PublishModalBottomSheetState extends State<_PublishModalBottomSheet> {
  bool _isPublishing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PhoneBookColors.entryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PhoneBookColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Help message
              Text(
                'Publish this thread to show others what you\'re working on or to share the composing history. It will be visible on your profile to selected groups.',
                style: GoogleFonts.sourceSans3(
                  color: PhoneBookColors.lightText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              
              // Option 1: For everyone (working)
              _buildPublishOption(
                context,
                'For everyone',
                'Anyone can discover and view this thread',
                true,
                () => _publishForEveryone(context),
              ),
              
              const SizedBox(height: 12),
              
              // Option 2: For followers (disabled)
              _buildPublishOption(
                context,
                'For followers',
                'Only users who follow you can see this',
                false,
                null,
              ),
              
              const SizedBox(height: 12),
              
              // Option 3: For users... (disabled)
              _buildPublishOption(
                context,
                'For users...',
                'Share with specific users or groups',
                false,
                null,
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishOption(
    BuildContext context,
    String title,
    String description,
    bool enabled,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? PhoneBookColors.buttonBackground : PhoneBookColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? PhoneBookColors.buttonBorder : PhoneBookColors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.sourceSans3(
                color: enabled ? PhoneBookColors.text : PhoneBookColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.sourceSans3(
                color: PhoneBookColors.lightText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _publishForEveryone(BuildContext context) async {
    if (_isPublishing) return;
    
    setState(() {
      _isPublishing = true;
    });

    try {
      final sequencerState = Provider.of<SequencerState>(context, listen: false);
      final threadsState = Provider.of<ThreadsState>(context, listen: false);
      
      // Close modal
      Navigator.of(context).pop();
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publishing thread...'),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 2),
        ),
      );

      // Use the same publish logic as in share widget
      final success = await sequencerState.publishToDatabase(
        description: 'Published from mobile app',
        isPublic: true,
      );
      
      if (success) {
        // Refresh threads to make sure we have the latest data
        await threadsState.loadThreads();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thread published successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to publish thread'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }
}

// Modal bottom sheet for inviting collaborators
class _InviteCollaboratorsModalBottomSheet extends StatefulWidget {
  const _InviteCollaboratorsModalBottomSheet();

  @override
  State<_InviteCollaboratorsModalBottomSheet> createState() => _InviteCollaboratorsModalBottomSheetState();
}

class _InviteCollaboratorsModalBottomSheetState extends State<_InviteCollaboratorsModalBottomSheet> {
  final Set<String> _selectedContacts = {};
  List<UserProfile> _userProfiles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfiles();
  }

  Future<void> _loadUserProfiles() async {
    try {
      final response = await UsersService.getUserProfiles(limit: 50);
      final threadsState = Provider.of<ThreadsState>(context, listen: false);
      final currentUserId = threadsState.currentUserId;
      
      setState(() {
        // Filter out current user from the list
        _userProfiles = response.profiles
            .where((user) => user.id != currentUserId)
            .toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PhoneBookColors.entryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PhoneBookColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Invite Collaborators',
                    style: GoogleFonts.sourceSans3(
                      color: PhoneBookColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select users to invite to this thread',
                    style: GoogleFonts.sourceSans3(
                      color: PhoneBookColors.lightText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contacts list
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading users...',
                            style: GoogleFonts.sourceSans3(
                              color: PhoneBookColors.lightText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: PhoneBookColors.lightText,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: GoogleFonts.sourceSans3(
                                  color: PhoneBookColors.lightText,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadUserProfiles,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PhoneBookColors.buttonBackground,
                                  side: BorderSide(color: PhoneBookColors.buttonBorder),
                                ),
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.sourceSans3(
                                    color: PhoneBookColors.text,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _userProfiles.length,
                          itemBuilder: (context, index) {
                            final user = _userProfiles[index];
                            final isSelected = _selectedContacts.contains(user.id);
                            final isOnline = user.isOnline;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                                                    setState(() {
                              if (isSelected) {
                                _selectedContacts.remove(user.id);
                              } else {
                                _selectedContacts.add(user.id);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? PhoneBookColors.currentUserCheckpoint : PhoneBookColors.checkpointBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? PhoneBookColors.onlineIndicator : PhoneBookColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Online indicator
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isOnline ? PhoneBookColors.onlineIndicator : PhoneBookColors.lightText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Username only
                                Expanded(
                                  child: Text(
                                    user.username,
                                    style: GoogleFonts.sourceSans3(
                                      color: PhoneBookColors.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            
                            // Checkbox
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? PhoneBookColors.onlineIndicator : PhoneBookColors.lightText,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Bottom actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    '${_selectedContacts.length} selected',
                    style: GoogleFonts.sourceSans3(
                      color: PhoneBookColors.lightText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.sourceSans3(
                        color: PhoneBookColors.lightText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedContacts.isNotEmpty ? () => _inviteSelectedContacts() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PhoneBookColors.buttonBackground,
                      foregroundColor: PhoneBookColors.text,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: PhoneBookColors.buttonBorder),
                    ),
                    child: Text(
                      'Invite',
                      style: GoogleFonts.sourceSans3(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _inviteSelectedContacts() async {
    Navigator.of(context).pop();
    
    if (_selectedContacts.isEmpty) return;
    
    final threadsState = Provider.of<ThreadsState>(context, listen: false);
    final currentThread = threadsState.currentThread;
    final currentUserId = threadsState.currentUserId;
    
    if (currentThread == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send invitations at this time'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sending ${_selectedContacts.length} invitation(s)...',
          style: GoogleFonts.sourceSans3(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
    
    int successCount = 0;
    int failureCount = 0;
    
    // Send invitations to all selected users
    for (final contactId in _selectedContacts) {
      try {
        // Find the user profile to get the name
        final userProfile = _userProfiles.where((profile) => profile.id == contactId).firstOrNull;
        final userName = userProfile?.username ?? 'Unknown User';
        
        await threadsState.sendInvitation(
          threadId: currentThread.id,
          userId: contactId,
          userName: userName,
          invitedBy: currentUserId,
        );
        
        successCount++;
      } catch (e) {
        failureCount++;
        debugPrint('Failed to invite user $contactId: $e');
      }
    }
    
    // Show result message
    if (mounted) {
      String message;
      Color backgroundColor;
      
      if (failureCount == 0) {
        message = 'Successfully invited $successCount user(s)!';
        backgroundColor = Colors.green;
      } else if (successCount == 0) {
        message = 'Failed to send all invitations';
        backgroundColor = Colors.red;
      } else {
        message = 'Invited $successCount user(s), $failureCount failed';
        backgroundColor = Colors.orange;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.sourceSans3(fontWeight: FontWeight.w500),
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
} 