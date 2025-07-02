#!/bin/bash

SOURCE="./AnimeViewMP"
DEST="./mediapipe/mediapipe/examples"

SOURCE_MODELS="./models"
DEST_MODELS="./mediapipe/mediapipe/models"

LINE='  ImageFormat::Format Format() const { return mediapipe::ImageFormatForGpuBufferFormat(gpu_buffer_.format()); }'
FILE="./mediapipe/mediapipe/framework/formats/image.h"

BUILD_FILE="./mediapipe/third_party/opencv_macos.BUILD"
WORKSPACE_FILE="./mediapipe/WORKSPACE"

FOLDER_NAME=$(basename "$SOURCE")
DEST_PATH="$DEST/$FOLDER_NAME"

# Detect Homebrew Cellar path (Intel or Apple Silicon)
if [ -d "/usr/local/Cellar" ]; then
  CELLAR="/usr/local/Cellar"
elif [ -d "/opt/homebrew/Cellar" ]; then
  CELLAR="/opt/homebrew/Cellar"
else
  echo -e "\033[0;31m[ERROR] Homebrew Cellar directory not found.\033[0m"
  exit 1
fi

# Check if the source folder exists
if [ ! -d "$SOURCE" ]; then
  echo -e "\033[0;31m[ERROR] Source folder $SOURCE does not exist. Exiting.\033[0"
  exit 1
fi

echo -e "\033[0;32mMove AnimeViewMP folder:\033[0m"
# Move the main folder
cp -r "$SOURCE" "$DEST"
if [ $? -eq 0 ]; then
    echo "  AnimeViewMP folder moved successfully to $DEST"
else
    echo -e "  \033[0;31m[ERROR] Failed to move the folder AnimeViewMP.\033[0m"
    exit 1
fi
echo ""

echo -e "\033[0;32mMove models folder:\033[0m"

# Ensure models destination directory exists
mkdir -p "$DEST_MODELS"

# Copy .tflite files
for file in "$SOURCE_MODELS"/*.tflite; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    if [[ "$filename" == "face_detection_short_range.tflite" ]]; then
        cp "$file" "./mediapipe/mediapipe/modules/face_detection/"
        echo "  Copied $filename to $./mediapipe/mediapipe/modules/face_detection/"
    else
        dest_file="$DEST_MODELS/$filename"
        if [ -e "$dest_file" ]; then
            echo "  Skipping $filename — already exists in $DEST_MODELS"
        else
            cp "$file" "$DEST_MODELS"
            echo "  Copied $filename to $DEST_MODELS"
        fi
    fi
  fi
done

# Copy BUILD directory if it exists
if [ -f "$SOURCE_MODELS/BUILD" ]; then
  cp -f "$SOURCE_MODELS/BUILD" "$DEST_MODELS/"
  echo "  Copied (and possibly replaced) BUILD file to $DEST_MODELS"
else
  echo -e "  \033[0;31m[ERROR] No BUILD file found in $SOURCE_MODELS\033[0m"
  exit 1
fi
echo ""

# Add OpenCV
echo -e "\033[0;32mChange OpenCV path:\033[0m"

# Find the latest installed opencv* directory (full path)
FULL_OPENCV_DIR=$(ls -1dt "$CELLAR"/opencv/* | head -n 1)

if [ -z "$FULL_OPENCV_DIR" ]; then
  echo -e "  \033[0;31m[ERROR] No OpenCV installation found in $CELLAR.\033[0m"
  exit 1
fi
echo "  Found full OpenCV directory: $FULL_OPENCV_DIR"

PREFIX_RELATIVE=$(basename "$(dirname "$FULL_OPENCV_DIR")")/$(basename "$FULL_OPENCV_DIR")
echo "  Relative PREFIX path: $PREFIX_RELATIVE"

awk -v new_path="$CELLAR" '
BEGIN { in_block=0 }
/new_local_repository\(/ { in_block=1 }
in_block && /name = "macos_opencv"/ { target_block=1 }
in_block && target_block && match($0, /^[ \t]*path = .*/) {
  print "    path = \"" new_path "\",  # e.g. /usr/local/Cellar for HomeBrew"
  next
}
in_block && /^\)/ {
  in_block=0
  target_block=0
}
{ print }
' "$WORKSPACE_FILE" > "$WORKSPACE_FILE.tmp" && mv "$WORKSPACE_FILE.tmp" "$WORKSPACE_FILE"
echo "  Updated path inside new_local_repository block for macos_opencv."

PREFIX_STR="PREFIX = \"$PREFIX_RELATIVE\""

sed -i '' -E "s|^PREFIX = \".*\"|$PREFIX_STR|" "$BUILD_FILE"
echo "  Replaced PREFIX line in $BUILD_FILE with: $PREFIX_STR"

# Extract major version from folder name
VERSION_STR=$(basename "$FULL_OPENCV_DIR" | sed 's/^opencv@*//')
MAJOR_VERSION=$(echo "$VERSION_STR" | cut -d. -f1)

# Update hdrs glob line if version >= 4
if [ "$MAJOR_VERSION" -ge 4 ]; then
  sed -i '' -E 's|hdrs = glob\(\[paths\.join\(PREFIX, "include/opencv2/\*\*/\*\.h\*"\)\]\),|hdrs = glob([paths.join(PREFIX, "include/opencv4/opencv2/**/*.h*")]),|' "$BUILD_FILE"
  sed -i '' -E 's|includes = \[paths\.join\(PREFIX, "include/"\)\],|includes = [paths.join(PREFIX, "include/opencv4/")],|' "$BUILD_FILE"
  echo "  Updated hdrs glob line for OpenCV 4+"
else
  echo "  No change to hdrs glob line needed for OpenCV < 4"
fi
echo ""
# End OpenCV

# Add Format()
echo -e "\033[0;32mAdd Format() function to the image class\033[0m"

if ! grep -Fxq "$LINE" "$FILE"; then
  sed -i '' '/\/\/ Returns image properties\./i\
'"$LINE"'\
\
' "$FILE"
  echo "  Line and empty line added to $FILE"
else
  echo "  Line already exists in $FILE"
fi
echo ""
# End Format()
