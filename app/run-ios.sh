#!/bin/bash

set -e

ENVIRONMENT="$1"
DEVICE_TYPE="$2"
IPHONE_MODEL="$3"

# Set default iPhone model if not provided for simulator
if [[ "$DEVICE_TYPE" == "simulator" && -z "$IPHONE_MODEL" ]]; then
  IPHONE_MODEL="iPhone 15"
  echo "No iPhone model specified, using default: $IPHONE_MODEL"
fi

# Copy appropriate environment file
if [[ "$ENVIRONMENT" == "stage" ]]; then
  cp .stage.env .env
  echo "Using stage environment (.stage.env)"
elif [[ "$ENVIRONMENT" == "prod" ]]; then
  cp .prod.env .env
  echo "Using production environment (.prod.env)"
fi

# Step 1: Find all directories (including empty ones) in samples folder
ASSET_DIRS=$(find samples/ -type d | sort)

# Step 2: Create temporary file with directory list
TEMP_ASSETS=$(mktemp)
echo "$ASSET_DIRS" > "$TEMP_ASSETS"

# Step 3: Use yq to update pubspec.yaml with proper array format
yq eval '.flutter.assets = []' -i pubspec.yaml

# Step 4: Add each directory individually with trailing slash
while IFS= read -r asset_dir; do
  if [[ -n "$asset_dir" && "$asset_dir" != "samples/" ]]; then
    # Normalize path by removing double slashes and add trailing slash
    normalized_path=$(echo "$asset_dir" | sed 's|//|/|g')
    yq eval ".flutter.assets += [\"$normalized_path/\"]" -i pubspec.yaml
  fi
done < "$TEMP_ASSETS"

# Step 5: Add .env file to assets if it exists
yq eval '.flutter.assets += [".env"]' -i pubspec.yaml

# Step 6: Add samples_manifest.json to assets
yq eval '.flutter.assets += ["samples_manifest.json"]' -i pubspec.yaml

# Clean up temp file
rm "$TEMP_ASSETS"

# Step 6: Run based on target
if [[ "$DEVICE_TYPE" == "simulator" ]]; then
  echo "Running on iPhone Simulator ($IPHONE_MODEL)..."
  # iPhone SE (3rd generation)
  # iPhone 15
  flutter run -d "$IPHONE_MODEL" --debug
else
  echo "Building for physical device..."
  flutter build ios --release

  echo "Deploying to physical device..."
  ios-deploy --bundle build/ios/iphoneos/Runner.app --id 00008110-000251422E02601E
fi
