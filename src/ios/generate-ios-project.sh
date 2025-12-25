#!/bin/bash
#
# generate-ios-project.sh
# Creates an Xcode project for Sil-Q iOS using xcodegen
#
# Prerequisites:
#   brew install xcodegen
#
# Usage:
#   cd sil-q
#   ./src/ios/generate-ios-project.sh
#

set -e

echo "Generating Sil-Q iOS Xcode project..."

# Check for xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing via Homebrew..."
    brew install xcodegen
fi

# Create project.yml for xcodegen
cat > src/ios/project.yml << 'EOF'
name: Sil-Q-iOS
options:
  bundleIdPrefix: com.silq
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "15.0"
  
settings:
  base:
    HEADER_SEARCH_PATHS: 
      - "$(SRCROOT)/../"
    GCC_PREPROCESSOR_DEFINITIONS:
      - USE_IOS=1
      - MACH_O_CARBON=1
    OTHER_LDFLAGS: -ObjC
    
targets:
  Sil-Q:
    type: application
    platform: iOS
    sources:
      # iOS-specific sources
      - path: .
        type: group
        excludes:
          - "*.sh"
          - "*.yml"
          - "README.md"
      # Core game sources
      - path: ../birth.c
      - path: ../cave.c
      - path: ../cmd1.c
      - path: ../cmd2.c
      - path: ../cmd3.c
      - path: ../cmd4.c
      - path: ../cmd5.c
      - path: ../cmd6.c
      - path: ../dungeon.c
      - path: ../files.c
      - path: ../generate.c
      - path: ../init1.c
      - path: ../init2.c
      - path: ../load.c
      - path: ../melee1.c
      - path: ../melee2.c
      - path: ../monster1.c
      - path: ../monster2.c
      - path: ../obj-info.c
      - path: ../object1.c
      - path: ../object2.c
      - path: ../randart.c
      - path: ../save.c
      - path: ../spells1.c
      - path: ../spells2.c
      - path: ../squelch.c
      - path: ../tables.c
      - path: ../use-obj.c
      - path: ../util.c
      - path: ../variable.c
      - path: ../wizard1.c
      - path: ../wizard2.c
      - path: ../xtra1.c
      - path: ../xtra2.c
      - path: ../z-form.c
      - path: ../z-rand.c
      - path: ../z-term.c
      - path: ../z-util.c
      - path: ../z-virt.c
      # Headers (for indexing)
      - path: ../angband.h
        type: file
        buildPhase: none
      - path: ../config.h
        type: file
        buildPhase: none
      - path: ../defines.h
        type: file
        buildPhase: none
      - path: ../externs.h
        type: file
        buildPhase: none
      - path: ../types.h
        type: file
        buildPhase: none
      - path: ../init.h
        type: file
        buildPhase: none
      - path: ../h-basic.h
        type: file
        buildPhase: none
      - path: ../h-config.h
        type: file
        buildPhase: none
      - path: ../h-define.h
        type: file
        buildPhase: none
      - path: ../h-system.h
        type: file
        buildPhase: none
      - path: ../h-type.h
        type: file
        buildPhase: none
      - path: ../z-form.h
        type: file
        buildPhase: none
      - path: ../z-rand.h
        type: file
        buildPhase: none
      - path: ../z-term.h
        type: file
        buildPhase: none
      - path: ../z-util.h
        type: file
        buildPhase: none
      - path: ../z-virt.h
        type: file
        buildPhase: none
      # Game data
      - path: ../../lib
        type: folder
        buildPhase: resources
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.silq.sil-q-ios
      INFOPLIST_FILE: Info.plist
      CODE_SIGN_STYLE: Automatic
      ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
      TARGETED_DEVICE_FAMILY: 1  # iPhone only
      IPHONEOS_DEPLOYMENT_TARGET: "17.0"
      ENABLE_BITCODE: NO
EOF

# Generate the project
cd src/ios
xcodegen generate

echo ""
echo "✅ Xcode project generated: src/ios/Sil-Q-iOS.xcodeproj"
echo ""
echo "Next steps:"
echo "1. Open Sil-Q-iOS.xcodeproj in Xcode"
echo "2. Select your development team in Signing & Capabilities"
echo "3. Build and run on your device"
echo ""
