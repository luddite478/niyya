#!/bin/bash

set -e

DEVICE_TYPE="$1"

if [[ "$DEVICE_TYPE" != "simulator" && "$DEVICE_TYPE" != "physical" ]]; then
  echo "Usage: $0 [simulator|physical]"
  exit 1
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
if [[ -f ".env" ]]; then
  yq eval '.flutter.assets += [".env"]' -i pubspec.yaml
fi

# Clean up temp file
rm "$TEMP_ASSETS"

# Step 6: Run based on target
if [[ "$DEVICE_TYPE" == "simulator" ]]; then
  echo "Running on iPhone 15 Simulator..."
  flutter run -d 'iPhone 15' --debug
  #open -a Simulator
else
  echo "Building for physical device..."
  flutter build ios --release

  echo "Deploying to physical device..."
  ios-deploy --bundle build/ios/iphoneos/Runner.app --id 00008110-000251422E02601E
fi
