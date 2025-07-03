#!/bin/bash

# Run the first setup script
./setup.sh

# Check if it succeeded
if [ $? -eq 0 ]; then
  echo -e "\033[0;32mSetup script executed successfully. Proceeding with build...\033[0m"
else
  echo -e "\033[0;31m[ERROR] Setup script failed. Aborting build.\033[0m"
  exit 1
fi

# Navigate to mediapipe directory
cd mediapipe || { echo -e "\033[0;31m[ERROR] mediapipe directory not found\033[0m"; exit 1; }

# Try to find Bazel
BAZEL_PATH=$(command -v bazel)
if [ -z "$BAZEL_PATH" ]; then
  echo -e "\033[0;31m[ERROR] Bazel was not found in the PATH environment variable. Please install it or add it to your PATH.\033[0m"
  echo -e "\033[0;31m        If neither of these work, please change the line 'BAZEL_PATH=\$(command -v bazel)' on line 18 of\033[0m"
  echo -e "\033[0;31m        the file 'build.sh' to 'BAZEL_PATH=/path/to/your/bazel/bin/installation'.\033[0m"
  exit 1
fi

# Try to find Python 3
PYTHON_PATH=$(command -v python3)
if [ -z "$PYTHON_PATH" ]; then
  echo -e "\033[0;31m[ERROR] Python3 not found in PATH. Please install it or add it to your PATH.\033[0m"
  exit 1
fi

# Print resolved paths
echo "Using Bazel:  $BAZEL_PATH"
echo "Using Python: $PYTHON_PATH"
echo ""

echo -e "\033[0;32mStart building iOS framework with mediapipe:\033[0m"

# Run the build command
"$BAZEL_PATH" build \
  --config=ios_arm64 \
  --action_env=PYTHON_BIN_PATH="$PYTHON_PATH" \
  mediapipe/examples/AnimeViewMP/ios:AnimeViewMP
   
# Check if Bazel build succeeded
if [ $? -eq 0 ]; then
  echo ""
  echo -e "\033[0;32mEnd building iOS framework with mediapipe.\033[0m"
  echo -e "\033[0;32mPostprocess iOS framework and move it to the xcode project:\033[0m"
else
  echo -e "\033[0;31m[ERROR] Bazel build failed. Aborting postprocessing.\033[0m"
  exit 1
fi

# Framework patching logic
FRAMEWORK_ZIP_PATH="bazel-bin/mediapipe/examples/AnimeViewMP/ios/AnimeViewMP.zip"
HEADER_FILES=("ObjcppLib.h")  # Add more headers here if needed
   
# Adds modulemap & header files to an iOS Framework
# generated with bazel and encapsulating Mediapipe.
#
# This makes it so that the patched .framework can be imported into Xcode.
# For a long term solution track the following issue:
#   https://github.com/bazelbuild/rules_apple/issues/355

zipped=$(python3 -c "import os; print(os.path.realpath('$FRAMEWORK_ZIP_PATH'))");
name=$(basename "$zipped" .zip)
parent=$(dirname "$zipped")
named="$parent"/"$name".framework

unzip -o "$zipped" -d "$parent" | sed $'s/^/  /'

mkdir -p "$named"/Modules
cat << EOF >"$named"/Modules/module.modulemap
framework module $name {
  umbrella header "$name.h"

  export *
  module * { export * }

  link framework "AVFoundation"
  link framework "Accelerate"
  link framework "AssetsLibrary"
  link framework "CoreFoundation"
  link framework "CoreGraphics"
  link framework "CoreImage"
  link framework "CoreMedia"
  link framework "CoreVideo"
  link framework "GLKit"
  link framework "Metal"
  link framework "MetalKit"
  link framework "OpenGLES"
  link framework "QuartzCore"
  link framework "UIKit"
}
EOF
# NOTE: All these linked frameworks are required by mediapipe/objc.

cat << EOF >"$named"/Headers/$name.h
//
//  $name.h
//  $name
//

#import <Foundation/Foundation.h>

//! Project version number for $name.
FOUNDATION_EXPORT double ${name}VersionNumber;

//! Project version string for $name.
FOUNDATION_EXPORT const unsigned char ${name}VersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <$name/PublicHeader.h>

EOF
for hdr in "${HEADER_FILES[@]}"; do
    echo "#import \"$hdr\"" >> "$named/Headers/$name.h"
done

XCODE_FRAMEWORK_DEST="../AnimeView/AnimeView"

# Copy the final patched framework to the Xcode project
cp -R "$named" "$XCODE_FRAMEWORK_DEST"

# Check if build succeeded
if [ $? -eq 0 ]; then
  echo ""
  echo -e "\033[0;32mAnimeView iOS build completed successfully.\033[0m"
else
  echo -e "\033[0;31m[ERROR] Build failed.\033[0m"
  exit 1
fi
