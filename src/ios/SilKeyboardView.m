/**
 * \file ios/SilKeyboardView.m
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

#import "SilKeyboardView.h"

// Key definitions for different modes
static NSString * const kAlphaRow1 = @"qwertyuiop";
static NSString * const kAlphaRow2 = @"asdfghjkl";
static NSString * const kAlphaRow3 = @"zxcvbnm";

static NSString * const kNumericRow1 = @"1234567890";
static NSString * const kNumericRow2 = @"-=[]\\;'`,./";
static NSString * const kSymbolRow1 = @"!@#$%^&*()";
static NSString * const kSymbolRow2 = @"_+{}|:\"~<>?";

// Movement key layout (numpad style)
// 7 8 9
// 4 5 6
// 1 2 3
static const unichar kMovementKeys[9] = {'7', '8', '9', '4', '5', '6', '1', '2', '3'};
static NSString * const kMovementLabels[9] = {@"↖", @"↑", @"↗", @"←", @"·", @"→", @"↙", @"↓", @"↘"};

// Common command keys
static NSString * const kCommandKeys = @"<>,.:;!?*@#";
static NSString * const kCommandLabels[] = {@"<Up", @">Down", @",Pick", @".Rest", @":Cmd", @";Walk", @"!Potion", @"?Scroll", @"*Target", @"@Info", @"#Toggle"};

#pragma mark - Key Button

@interface SilKeyButton : UIButton
@property (nonatomic) unichar keyCode;
@property (nonatomic) BOOL isModifier;
@property (nonatomic) BOOL isSpecial;
@end

@implementation SilKeyButton
@end

#pragma mark - SilKeyboardView

@implementation SilKeyboardView {
    UIStackView *_mainStack;
    NSMutableArray<SilKeyButton *> *_keyButtons;
    UIColor *_keyColor;
    UIColor *_textColor;
    
    UIButton *_shiftButton;
    UIButton *_ctrlButton;
    UIButton *_modeButton;
    UIButton *_spaceButton;
    UIButton *_returnButton;
    UIButton *_escapeButton;
    
    CGFloat _baseKeyHeight;
    CGFloat _keySpacing;
    CGFloat _keyCornerRadius;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _mode = SilKeyboardModeAlpha;
    _shiftActive = NO;
    _controlActive = NO;
    _isVisible = NO;
    
    _keyButtons = [NSMutableArray array];
    _baseKeyHeight = 44.0;
    _keySpacing = 4.0;
    _keyCornerRadius = 6.0;
    
    // Default colors (dark theme)
    self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    _keyColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    _textColor = [UIColor whiteColor];
    
    [self setupKeyboard];
    [self updateForMode];
}

- (CGFloat)keyboardHeight {
    return _baseKeyHeight * 4 + _keySpacing * 5 + self.safeAreaInsets.bottom;
}

- (void)setupKeyboard {
    _mainStack = [[UIStackView alloc] init];
    _mainStack.axis = UILayoutConstraintAxisVertical;
    _mainStack.distribution = UIStackViewDistributionFillEqually;
    _mainStack.spacing = _keySpacing;
    _mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_mainStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [_mainStack.topAnchor constraintEqualToAnchor:self.topAnchor constant:_keySpacing],
        [_mainStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:_keySpacing],
        [_mainStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-_keySpacing],
        [_mainStack.bottomAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.bottomAnchor constant:-_keySpacing]
    ]];
    
    // Create 4 rows
    for (int i = 0; i < 4; i++) {
        UIStackView *row = [[UIStackView alloc] init];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.distribution = UIStackViewDistributionFillEqually;
        row.spacing = _keySpacing;
        [_mainStack addArrangedSubview:row];
    }
}

- (void)updateForMode {
    // Clear existing keys
    for (UIView *row in _mainStack.arrangedSubviews) {
        if ([row isKindOfClass:[UIStackView class]]) {
            for (UIView *subview in [(UIStackView *)row arrangedSubviews]) {
                [subview removeFromSuperview];
            }
        }
    }
    [_keyButtons removeAllObjects];
    
    switch (_mode) {
        case SilKeyboardModeAlpha:
            [self layoutAlphaKeyboard];
            break;
        case SilKeyboardModeNumeric:
            [self layoutNumericKeyboard];
            break;
        case SilKeyboardModeMovement:
            [self layoutMovementKeyboard];
            break;
        case SilKeyboardModeCommand:
            [self layoutCommandKeyboard];
            break;
    }
}

- (void)layoutAlphaKeyboard {
    NSArray<UIStackView *> *rows = (NSArray<UIStackView *> *)_mainStack.arrangedSubviews;
    
    // Row 1: qwertyuiop
    [self addKeysFromString:kAlphaRow1 toRow:rows[0]];
    
    // Row 2: asdfghjkl
    [self addKeysFromString:kAlphaRow2 toRow:rows[1]];
    
    // Row 3: shift, zxcvbnm, backspace
    [self addModifierKey:@"⇧" action:@selector(shiftPressed:) toRow:rows[2] width:1.5];
    [self addKeysFromString:kAlphaRow3 toRow:rows[2]];
    [self addSpecialKey:@"⌫" keyCode:'\b' toRow:rows[2] width:1.5];
    
    // Row 4: mode, ctrl, space, return, escape
    [self addModeButton:@"123" toRow:rows[3] width:1.2];
    [self addModifierKey:@"^" action:@selector(ctrlPressed:) toRow:rows[3] width:1.0];
    [self addSpaceKeyToRow:rows[3] width:4.0];
    [self addSpecialKey:@"↵" keyCode:'\r' toRow:rows[3] width:1.2];
    [self addSpecialKey:@"ESC" keyCode:27 toRow:rows[3] width:1.2];
}

- (void)layoutNumericKeyboard {
    NSArray<UIStackView *> *rows = (NSArray<UIStackView *> *)_mainStack.arrangedSubviews;
    
    // Row 1: 1234567890
    [self addKeysFromString:kNumericRow1 toRow:rows[0]];
    
    // Row 2: symbols
    [self addKeysFromString:(_shiftActive ? kSymbolRow1 : kNumericRow2) toRow:rows[1]];
    
    // Row 3: more symbols with shift
    [self addModifierKey:@"⇧" action:@selector(shiftPressed:) toRow:rows[2] width:1.5];
    NSString *row3 = _shiftActive ? kSymbolRow2 : @"-=[]',.";
    [self addKeysFromString:row3 toRow:rows[2]];
    [self addSpecialKey:@"⌫" keyCode:'\b' toRow:rows[2] width:1.5];
    
    // Row 4: mode, ctrl, space, return, escape
    [self addModeButton:@"ABC" toRow:rows[3] width:1.2];
    [self addModifierKey:@"^" action:@selector(ctrlPressed:) toRow:rows[3] width:1.0];
    [self addSpaceKeyToRow:rows[3] width:4.0];
    [self addSpecialKey:@"↵" keyCode:'\r' toRow:rows[3] width:1.2];
    [self addSpecialKey:@"ESC" keyCode:27 toRow:rows[3] width:1.2];
}

- (void)layoutMovementKeyboard {
    NSArray<UIStackView *> *rows = (NSArray<UIStackView *> *)_mainStack.arrangedSubviews;
    
    // Row 0: 7 8 9 (NW N NE) + common actions
    [self addMovementKey:0 toRow:rows[0]]; // 7 - NW
    [self addMovementKey:1 toRow:rows[0]]; // 8 - N
    [self addMovementKey:2 toRow:rows[0]]; // 9 - NE
    [self addSpecialKey:@"<" keyCode:'<' toRow:rows[0] width:1.0]; // Up stairs
    [self addSpecialKey:@">" keyCode:'>' toRow:rows[0] width:1.0]; // Down stairs
    
    // Row 1: 4 5 6 (W wait E) + actions
    [self addMovementKey:3 toRow:rows[1]]; // 4 - W
    [self addMovementKey:4 toRow:rows[1]]; // 5 - Wait
    [self addMovementKey:5 toRow:rows[1]]; // 6 - E
    [self addSpecialKey:@"g" keyCode:'g' toRow:rows[1] width:1.0]; // Get
    [self addSpecialKey:@"i" keyCode:'i' toRow:rows[1] width:1.0]; // Inventory
    
    // Row 2: 1 2 3 (SW S SE) + actions  
    [self addMovementKey:6 toRow:rows[2]]; // 1 - SW
    [self addMovementKey:7 toRow:rows[2]]; // 2 - S
    [self addMovementKey:8 toRow:rows[2]]; // 3 - SE
    [self addSpecialKey:@"m" keyCode:'m' toRow:rows[2] width:1.0]; // Magic/abilities
    [self addSpecialKey:@"f" keyCode:'f' toRow:rows[2] width:1.0]; // Fire
    
    // Row 3: mode switch, run toggle, space, return, escape
    [self addModeButton:@"ABC" toRow:rows[3] width:1.2];
    [self addSpecialKey:@"Run" keyCode:'.' toRow:rows[3] width:1.0]; // Run/rest
    [self addSpaceKeyToRow:rows[3] width:3.0];
    [self addSpecialKey:@"↵" keyCode:'\r' toRow:rows[3] width:1.2];
    [self addSpecialKey:@"ESC" keyCode:27 toRow:rows[3] width:1.2];
}

- (void)layoutCommandKeyboard {
    NSArray<UIStackView *> *rows = (NSArray<UIStackView *> *)_mainStack.arrangedSubviews;
    
    // Row 0: Common actions
    [self addSpecialKey:@"Inv" keyCode:'i' toRow:rows[0] width:1.0];
    [self addSpecialKey:@"Equip" keyCode:'e' toRow:rows[0] width:1.0];
    [self addSpecialKey:@"Drop" keyCode:'d' toRow:rows[0] width:1.0];
    [self addSpecialKey:@"Get" keyCode:'g' toRow:rows[0] width:1.0];
    [self addSpecialKey:@"Look" keyCode:'l' toRow:rows[0] width:1.0];
    
    // Row 1: More actions
    [self addSpecialKey:@"Use" keyCode:'u' toRow:rows[1] width:1.0];
    [self addSpecialKey:@"Fire" keyCode:'f' toRow:rows[1] width:1.0];
    [self addSpecialKey:@"Throw" keyCode:'v' toRow:rows[1] width:1.0];
    [self addSpecialKey:@"Ability" keyCode:'m' toRow:rows[1] width:1.0];
    [self addSpecialKey:@"Rest" keyCode:'R' toRow:rows[1] width:1.0];
    
    // Row 2: Interface
    [self addSpecialKey:@"Map" keyCode:'M' toRow:rows[2] width:1.0];
    [self addSpecialKey:@"Char" keyCode:'C' toRow:rows[2] width:1.0];
    [self addSpecialKey:@"Msgs" keyCode:16 toRow:rows[2] width:1.0]; // Ctrl-P
    [self addSpecialKey:@"Help" keyCode:'?' toRow:rows[2] width:1.0];
    [self addSpecialKey:@"Save" keyCode:'S' toRow:rows[2] width:1.0]; // Ctrl-S
    
    // Row 3: mode switch and navigation
    [self addModeButton:@"Move" toRow:rows[3] width:1.2];
    [self addModeButton:@"ABC" toRow:rows[3] width:1.2];
    [self addSpaceKeyToRow:rows[3] width:2.5];
    [self addSpecialKey:@"↵" keyCode:'\r' toRow:rows[3] width:1.2];
    [self addSpecialKey:@"ESC" keyCode:27 toRow:rows[3] width:1.2];
}

#pragma mark - Key Creation Helpers

- (SilKeyButton *)createKeyWithTitle:(NSString *)title {
    SilKeyButton *key = [SilKeyButton buttonWithType:UIButtonTypeCustom];
    [key setTitle:title forState:UIControlStateNormal];
    [key setTitleColor:_textColor forState:UIControlStateNormal];
    key.backgroundColor = _keyColor;
    key.layer.cornerRadius = _keyCornerRadius;
    key.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    [key addTarget:self action:@selector(keyPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_keyButtons addObject:key];
    return key;
}

- (void)addKeysFromString:(NSString *)keys toRow:(UIStackView *)row {
    for (NSUInteger i = 0; i < keys.length; i++) {
        unichar c = [keys characterAtIndex:i];
        NSString *title = _shiftActive ? [[NSString stringWithCharacters:&c length:1] uppercaseString] 
                                       : [NSString stringWithCharacters:&c length:1];
        SilKeyButton *key = [self createKeyWithTitle:title];
        key.keyCode = _shiftActive ? [title characterAtIndex:0] : c;
        [row addArrangedSubview:key];
    }
}

- (void)addMovementKey:(int)index toRow:(UIStackView *)row {
    SilKeyButton *key = [self createKeyWithTitle:kMovementLabels[index]];
    key.keyCode = kMovementKeys[index];
    key.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    [row addArrangedSubview:key];
}

- (void)addSpecialKey:(NSString *)title keyCode:(unichar)code toRow:(UIStackView *)row width:(CGFloat)widthMultiplier {
    SilKeyButton *key = [self createKeyWithTitle:title];
    key.keyCode = code;
    key.isSpecial = YES;
    key.backgroundColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    
    // Add to row first - UIStackView with fillEqually handles sizing
    [row addArrangedSubview:key];
}

- (void)addModifierKey:(NSString *)title action:(SEL)action toRow:(UIStackView *)row width:(CGFloat)widthMultiplier {
    UIButton *key = [UIButton buttonWithType:UIButtonTypeCustom];
    [key setTitle:title forState:UIControlStateNormal];
    [key setTitleColor:_textColor forState:UIControlStateNormal];
    key.backgroundColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    key.layer.cornerRadius = _keyCornerRadius;
    key.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    [key addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    if ([title isEqualToString:@"⇧"]) {
        _shiftButton = key;
    } else if ([title isEqualToString:@"^"]) {
        _ctrlButton = key;
    }
    
    [row addArrangedSubview:key];
}

- (void)addModeButton:(NSString *)title toRow:(UIStackView *)row width:(CGFloat)widthMultiplier {
    UIButton *key = [UIButton buttonWithType:UIButtonTypeCustom];
    [key setTitle:title forState:UIControlStateNormal];
    [key setTitleColor:_textColor forState:UIControlStateNormal];
    key.backgroundColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    key.layer.cornerRadius = _keyCornerRadius;
    key.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [key addTarget:self action:@selector(modePressed:) forControlEvents:UIControlEventTouchUpInside];
    _modeButton = key;
    [row addArrangedSubview:key];
}

- (void)addSpaceKeyToRow:(UIStackView *)row width:(CGFloat)widthMultiplier {
    SilKeyButton *key = [self createKeyWithTitle:@"space"];
    key.keyCode = ' ';
    key.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    _spaceButton = key;
    [row addArrangedSubview:key];
}

#pragma mark - Key Actions

- (void)keyPressed:(SilKeyButton *)sender {
    unichar keyCode = sender.keyCode;
    
    // Apply control modifier
    if (_controlActive && keyCode >= 'a' && keyCode <= 'z') {
        keyCode = keyCode - 'a' + 1; // Convert to control character
    }
    
    UIKeyModifierFlags modifiers = 0;
    if (_shiftActive) modifiers |= UIKeyModifierShift;
    if (_controlActive) modifiers |= UIKeyModifierControl;
    
    [self.delegate keyboardView:self didPressKey:keyCode modifiers:modifiers];
    
    // Reset modifiers after key press (except for sticky mode)
    if (!sender.isModifier) {
        _shiftActive = NO;
        _controlActive = NO;
        [self updateModifierButtonStates];
    }
}

- (void)shiftPressed:(UIButton *)sender {
    _shiftActive = !_shiftActive;
    [self updateModifierButtonStates];
    [self updateForMode]; // Refresh to show shifted characters
}

- (void)ctrlPressed:(UIButton *)sender {
    _controlActive = !_controlActive;
    [self updateModifierButtonStates];
}

- (void)modePressed:(UIButton *)sender {
    NSString *title = sender.titleLabel.text;
    
    if ([title isEqualToString:@"123"]) {
        self.mode = SilKeyboardModeNumeric;
    } else if ([title isEqualToString:@"ABC"]) {
        self.mode = SilKeyboardModeAlpha;
    } else if ([title isEqualToString:@"Move"]) {
        self.mode = SilKeyboardModeMovement;
    } else if ([title isEqualToString:@"Cmd"]) {
        self.mode = SilKeyboardModeCommand;
    } else {
        // Cycle through modes
        self.mode = (self.mode + 1) % 4;
    }
}

- (void)setMode:(SilKeyboardMode)mode {
    if (_mode != mode) {
        _mode = mode;
        [self updateForMode];
        
        if ([self.delegate respondsToSelector:@selector(keyboardView:didChangeMode:)]) {
            [self.delegate keyboardView:self didChangeMode:mode];
        }
    }
}

- (void)updateModifierButtonStates {
    _shiftButton.backgroundColor = _shiftActive ? 
        [UIColor colorWithRed:0.3 green:0.5 blue:0.8 alpha:1.0] : 
        [UIColor colorWithWhite:0.35 alpha:1.0];
    
    _ctrlButton.backgroundColor = _controlActive ? 
        [UIColor colorWithRed:0.3 green:0.5 blue:0.8 alpha:1.0] : 
        [UIColor colorWithWhite:0.35 alpha:1.0];
}

#pragma mark - Visibility

- (void)showAnimated:(BOOL)animated {
    if (_isVisible) return;
    _isVisible = YES;
    
    if (animated) {
        self.transform = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
        self.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    } else {
        self.hidden = NO;
        self.transform = CGAffineTransformIdentity;
    }
}

- (void)hideAnimated:(BOOL)animated {
    if (!_isVisible) return;
    _isVisible = NO;
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.transform = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
        } completion:^(BOOL finished) {
            self.hidden = YES;
        }];
    } else {
        self.hidden = YES;
    }
}

- (void)toggle {
    if (_isVisible) {
        [self hideAnimated:YES];
    } else {
        [self showAnimated:YES];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
                  keyColor:(UIColor *)keyColor
                 textColor:(UIColor *)textColor {
    [super setBackgroundColor:backgroundColor];
    _keyColor = keyColor;
    _textColor = textColor;
    [self updateForMode];
}

@end
