/**
 * \file ios/SilViewController.h
 * \brief Main view controller for iOS Sil-Q
 *
 * Copyright (c) 2024 Sil-Q Contributors
 *
 * This work is free software; you can redistribute it and/or modify it
 * under the terms of either:
 *
 * a) the GNU General Public License as published by the Free Software
 *    Foundation, version 2, or
 *
 * b) the "Angband licence":
 *    This software may be copied and distributed for educational, research,
 *    and not for profit purposes provided that this copyright and statement
 *    are included in all such copies.  Other copyrights may also apply.
 */

#import <UIKit/UIKit.h>
#import "SilTerminalView.h"
#import "SilKeyboardView.h"

/**
 * Touch input mode for the terminal view
 */
typedef NS_ENUM(NSInteger, SilTouchMode) {
    SilTouchModeMovement,   // Taps translate to movement keys
    SilTouchModeTarget,     // Taps select a target location
    SilTouchModeDisabled    // Touch input disabled
};

/**
 * SilViewController is the main view controller for the game.
 * It manages the terminal view, keyboard, and touch input.
 */
@interface SilViewController : UIViewController <SilKeyboardViewDelegate>

/** The terminal view displaying the game */
@property (nonatomic, strong, readonly) SilTerminalView *terminalView;

/** The virtual keyboard */
@property (nonatomic, strong, readonly) SilKeyboardView *keyboardView;

/** Current touch input mode */
@property (nonatomic) SilTouchMode touchMode;

/** Whether the keyboard is currently showing */
@property (nonatomic, readonly) BOOL keyboardVisible;

/**
 * Queue a key input to the game.
 * @param key The key character or code
 * @param modifiers Modifier flags
 */
- (void)queueKey:(unichar)key modifiers:(UIKeyModifierFlags)modifiers;

/**
 * Queue a string of keys to the game.
 * @param string The string to queue as key presses
 */
- (void)queueString:(NSString *)string;

/**
 * Show or hide the virtual keyboard.
 * @param show YES to show, NO to hide
 * @param animated Whether to animate the change
 */
- (void)setKeyboardVisible:(BOOL)show animated:(BOOL)animated;

/**
 * Toggle the virtual keyboard.
 */
- (void)toggleKeyboard;

/**
 * Refresh the terminal display.
 */
- (void)refreshDisplay;

/**
 * Get the shared instance of the view controller.
 * Used by the game's Term hooks to access the view.
 */
+ (instancetype)sharedController;

@end
