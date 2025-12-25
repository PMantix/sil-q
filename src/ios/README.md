# Sil-Q iOS Port

This directory contains the iOS port of Sil-Q, a roguelike game.

## Requirements

- macOS with Xcode 16+ installed (tested with Xcode 26.1)
- iOS 18+ device or simulator
- Apple Developer account (free account works for personal use)

## Quick Start (Recommended)

Use the XcodeGen script to automatically generate the iOS project:

```bash
cd sil-q
./src/ios/generate-ios-project.sh
```

This creates `src/ios/Sil-Q-iOS.xcodeproj`. Then:

1. Open `Sil-Q-iOS.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities  
3. Build and run on your device

## Manual Project Setup

Since Xcode project files are complex, you'll need to create the iOS target manually:

### Option 1: Add iOS Target to Existing Project

1. Open `Sil.xcodeproj` in Xcode
2. File → New → Target
3. Choose "iOS" → "App"
4. Product Name: `Sil-Q-iOS`
5. Organization Identifier: `com.yourname` (or your identifier)
6. Interface: Storyboard
7. Language: Objective-C
8. Click Finish

### Option 2: Create New iOS Project

1. Open Xcode
2. Create New Project → iOS → App
3. Product Name: `Sil-Q-iOS`
4. Bundle Identifier: `com.yourname.sil-q-ios`
5. Interface: Storyboard
6. Language: Objective-C
7. Save in the sil-q folder

## Adding Source Files

After creating the target/project:

### iOS-Specific Files (in src/ios/)
Add these files to the iOS target:
- `main-ios.m` - Main entry point and Term hooks
- `SilAppDelegate.h/.m` - App delegate
- `SilViewController.h/.m` - Main view controller  
- `SilTerminalView.h/.m` - Terminal rendering
- `SilKeyboardView.h/.m` - Virtual keyboard
- `Info.plist` - App configuration
- `LaunchScreen.storyboard` - Launch screen

### Core Game Files (from src/)
Add these C files to the iOS target (Compile Sources):
- `birth.c`
- `cave.c`
- `cmd1.c` through `cmd6.c`
- `dungeon.c`
- `files.c`
- `generate.c`
- `init1.c`, `init2.c`
- `load.c`, `save.c`
- `melee1.c`, `melee2.c`
- `monster1.c`, `monster2.c`
- `obj-info.c`
- `object1.c`, `object2.c`
- `randart.c`
- `spells1.c`, `spells2.c`
- `squelch.c`
- `tables.c`
- `use-obj.c`
- `util.c`
- `variable.c`
- `wizard1.c`, `wizard2.c`
- `xtra1.c`, `xtra2.c`
- `z-form.c`, `z-rand.c`, `z-term.c`, `z-util.c`, `z-virt.c`

### Header Files
Make sure these headers are accessible:
- `angband.h`
- `config.h`, `defines.h`, `externs.h`, `types.h`
- `h-basic.h`, `h-config.h`, `h-define.h`, `h-system.h`, `h-type.h`
- `init.h`
- `z-form.h`, `z-rand.h`, `z-term.h`, `z-util.h`, `z-virt.h`

### Game Data (lib folder)
Add the entire `lib` folder to Copy Bundle Resources:
- Right-click on the project → Add Files to "Sil-Q-iOS"
- Select the `lib` folder
- Make sure "Create folder references" is selected (blue folder icon)
- Check the iOS target

## Build Settings

In the iOS target Build Settings:

1. **Header Search Paths**:
   - `$(SRCROOT)/src`

2. **Preprocessor Macros** (for Debug and Release):
   - `USE_IOS=1`
   - `MACH_O_CARBON=1`

3. **Other Linker Flags**:
   - `-ObjC`

4. **Info.plist File**:
   - Set to `src/ios/Info.plist`

5. **Deployment Target**:
   - iOS 18.0 or later

6. **Architectures**:
   - Standard (arm64)

7. **Code Signing**:
   - For personal testing: Sign with your Apple ID
   - Development Team: Your personal team

## Running on Device

1. Connect your iPhone
2. Select your device as the run destination
3. Build and Run (⌘R)
4. Trust the developer certificate on your iPhone:
   - Settings → General → VPN & Device Management
   - Tap your Developer App certificate
   - Tap "Trust"

## Touch Controls

The iOS port uses touch-based input:

### Movement (3x3 Grid)
Tap the screen to move:
```
┌───┬───┬───┐
│NW │ N │NE │
│ 7 │ 8 │ 9 │
├───┼───┼───┤
│ W │ . │ E │
│ 4 │ 5 │ 6 │
├───┼───┼───┤
│SW │ S │SE │
│ 1 │ 2 │ 3 │
└───┴───┴───┘
```

### Keyboard
- Double-tap to toggle virtual keyboard
- Swipe up from bottom to show keyboard
- Swipe down to hide keyboard
- Keyboard modes: Movement, Alpha, Numeric, Commands

### Other Gestures
- Long press: Look at location
- Pinch: Zoom terminal display

## Known Issues

- This is an MVP (Minimum Viable Product) port
- Some features from the desktop version may not work
- Graphics mode not yet supported (ASCII only)
- Sound not yet implemented

## File Structure

```
src/ios/
├── Info.plist              # iOS app configuration
├── LaunchScreen.storyboard # Launch screen
├── main-ios.m              # iOS main & Term hooks
├── SilAppDelegate.h/m      # App lifecycle
├── SilViewController.h/m   # Main UI controller
├── SilTerminalView.h/m     # Terminal rendering
├── SilKeyboardView.h/m     # Virtual keyboard
└── README.md               # This file
```

## Contributing

This iOS port is part of the Sil-Q project. Contributions welcome!

## License

Same as Sil-Q - see LICENSE.md in the project root.
