/**
 * \file ios/SilKeyboardView.h
 * \brief Virtual keyboard for iOS Sil-Q
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

@class SilKeyboardView;

/**
 * Keyboard mode enumeration
 */
typedef NS_ENUM(NSInteger, SilKeyboardMode) {
    SilKeyboardModeAlpha,       // Standard alpha keys
    SilKeyboardModeNumeric,     // Numbers and symbols
    SilKeyboardModeMovement,    // Numpad-style movement keys
    SilKeyboardModeCommand      // Common game commands
};

/**
 * Delegate protocol for keyboard input events
 */
@protocol SilKeyboardViewDelegate <NSObject>

/**
 * Called when a key is pressed.
 * @param keyboard The keyboard view
 * @param key The key character or code
 * @param modifiers Modifier flags (shift, control, etc.)
 */
- (void)keyboardView:(SilKeyboardView *)keyboard
          didPressKey:(unichar)key
           modifiers:(UIKeyModifierFlags)modifiers;

@optional

/**
 * Called when the keyboard mode changes.
 * @param keyboard The keyboard view
 * @param mode The new keyboard mode
 */
- (void)keyboardView:(SilKeyboardView *)keyboard didChangeMode:(SilKeyboardMode)mode;

@end

/**
 * SilKeyboardView provides a virtual keyboard tailored for roguelike games.
 * It supports multiple modes including movement, commands, and standard input.
 */
@interface SilKeyboardView : UIView

/** The delegate for keyboard events */
@property (nonatomic, weak) id<SilKeyboardViewDelegate> delegate;

/** Current keyboard mode */
@property (nonatomic) SilKeyboardMode mode;

/** Whether shift is active */
@property (nonatomic) BOOL shiftActive;

/** Whether control is active */
@property (nonatomic) BOOL controlActive;

/** Height of the keyboard view */
@property (nonatomic, readonly) CGFloat keyboardHeight;

/** Whether the keyboard is currently visible */
@property (nonatomic, readonly) BOOL isVisible;

/**
 * Show the keyboard with animation.
 */
- (void)showAnimated:(BOOL)animated;

/**
 * Hide the keyboard with animation.
 */
- (void)hideAnimated:(BOOL)animated;

/**
 * Toggle keyboard visibility.
 */
- (void)toggle;

/**
 * Configure keyboard appearance.
 * @param backgroundColor Background color for the keyboard
 * @param keyColor Background color for keys
 * @param textColor Text color for key labels
 */
- (void)setBackgroundColor:(UIColor *)backgroundColor
                  keyColor:(UIColor *)keyColor
                 textColor:(UIColor *)textColor;

@end
