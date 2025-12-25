/**
 * \file ios/SilViewController.m
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

#import "SilViewController.h"

// Import the Term_keypress function from z-term
extern void Term_keypress(int k);

// Singleton instance
static SilViewController *_sharedController = nil;

// Key queue for the game (backup, but we mainly use Term_keypress now)
#define KEY_QUEUE_SIZE 256
static unichar _keyQueue[KEY_QUEUE_SIZE];
static int _keyQueueHead = 0;
static int _keyQueueTail = 0;

// Movement key mapping for 3x3 touch grid
// Screen is divided into 9 regions:
// 7 8 9
// 4 5 6
// 1 2 3
static const unichar kMovementKeyMap[9] = {
    '7', '8', '9',  // Top row: NW, N, NE
    '4', '5', '6',  // Middle row: W, wait, E
    '1', '2', '3'   // Bottom row: SW, S, SE
};

@implementation SilViewController {
    UIScrollView *_scrollView;
    UIView *_containerView;
    UITapGestureRecognizer *_tapGesture;
    UISwipeGestureRecognizer *_swipeUpGesture;
    UISwipeGestureRecognizer *_swipeDownGesture;
    UILongPressGestureRecognizer *_longPressGesture;
    
    NSLayoutConstraint *_keyboardBottomConstraint;
    NSLayoutConstraint *_noKeyboardConstraint;
    NSLayoutConstraint *_keyboardHeightConstraint;
    UIButton *_keyboardToggleButton;
    BOOL _didSetInitialZoom;
    BOOL _gameRunning;
}

+ (instancetype)sharedController {
    return _sharedController;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sharedController = self;
        _touchMode = SilTouchModeMovement;
        _gameRunning = NO;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _sharedController = self;
        _touchMode = SilTouchModeMovement;
        _gameRunning = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupScrollView];
    [self setupTerminalView];
    [self setupKeyboardView];
    [self setupKeyboardToggleButton];
    [self setupGestures];
    [self setupNotifications];
}

- (void)setupKeyboardToggleButton {
    _keyboardToggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _keyboardToggleButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_keyboardToggleButton setTitle:@"KB" forState:UIControlStateNormal];
    _keyboardToggleButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    [_keyboardToggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _keyboardToggleButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    _keyboardToggleButton.layer.cornerRadius = 8;
    _keyboardToggleButton.contentEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10);
    [_keyboardToggleButton addTarget:self action:@selector(toggleKeyboard) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_keyboardToggleButton];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_keyboardToggleButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [_keyboardToggleButton.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-12],
    ]];
}

- (void)setupScrollView {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.bounces = YES;
    _scrollView.minimumZoomScale = 0.5;
    _scrollView.maximumZoomScale = 2.0;
    _scrollView.delegate = (id<UIScrollViewDelegate>)self;
    [self.view addSubview:_scrollView];
    
    _containerView = [[UIView alloc] init];
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    _containerView.backgroundColor = [UIColor blackColor];
    [_scrollView addSubview:_containerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        
        [_containerView.topAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.topAnchor],
        [_containerView.leadingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.leadingAnchor],
        [_containerView.trailingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.trailingAnchor],
        [_containerView.bottomAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.bottomAnchor],
    ]];
}

- (void)setupTerminalView {
    _terminalView = [[SilTerminalView alloc] initWithCols:80 rows:24];
    _terminalView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Calculate optimal font size to fill the screen width in landscape
    CGFloat screenWidth = MAX(UIScreen.mainScreen.bounds.size.width, 
                               UIScreen.mainScreen.bounds.size.height);
    CGFloat screenHeight = MIN(UIScreen.mainScreen.bounds.size.width, 
                                UIScreen.mainScreen.bounds.size.height);
    
    // Leave some margin and account for safe areas
    CGFloat availableWidth = screenWidth - 40;
    CGFloat availableHeight = screenHeight - 60; // Room for keyboard toggle
    
    // Calculate font size based on fitting 80 columns
    CGFloat fontSizeForWidth = availableWidth / 80.0 * 1.7; // Approximate width factor
    CGFloat fontSizeForHeight = availableHeight / 24.0 * 0.9; // Approximate height factor
    CGFloat optimalFontSize = MIN(fontSizeForWidth, fontSizeForHeight);
    optimalFontSize = MAX(10.0, MIN(optimalFontSize, 24.0)); // Clamp between 10-24pt
    
    UIFont *scaledFont = [UIFont fontWithName:@"Menlo-Regular" size:optimalFontSize];
    if (!scaledFont) {
        scaledFont = [UIFont monospacedSystemFontOfSize:optimalFontSize weight:UIFontWeightRegular];
    }
    _terminalView.terminalFont = scaledFont;
    
    [_containerView addSubview:_terminalView];
    
    [NSLayoutConstraint activateConstraints:@[
        [_terminalView.topAnchor constraintEqualToAnchor:_containerView.topAnchor],
        [_terminalView.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor],
        [_terminalView.widthAnchor constraintEqualToConstant:_terminalView.cellWidth * 80],
        [_terminalView.heightAnchor constraintEqualToConstant:_terminalView.cellHeight * 24],
    ]];
}

- (void)setupKeyboardView {
    _keyboardView = [[SilKeyboardView alloc] init];
    _keyboardView.translatesAutoresizingMaskIntoConstraints = NO;
    _keyboardView.delegate = self;
    _keyboardView.mode = SilKeyboardModeMovement; // Default to movement mode
    _keyboardView.hidden = YES;
    [self.view addSubview:_keyboardView];
    
    _keyboardBottomConstraint = [_scrollView.bottomAnchor constraintEqualToAnchor:_keyboardView.topAnchor];
    _keyboardBottomConstraint.active = NO;
    _noKeyboardConstraint = [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
    _noKeyboardConstraint.priority = UILayoutPriorityRequired;
    _noKeyboardConstraint.active = YES;
    
    [NSLayoutConstraint activateConstraints:@[
        [_keyboardView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_keyboardView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_keyboardView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    _keyboardHeightConstraint = [_keyboardView.heightAnchor constraintEqualToConstant:0];
    _keyboardHeightConstraint.active = YES;
}

- (void)setupGestures {
    // Single tap for movement or selection
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _tapGesture.numberOfTapsRequired = 1;
    [_terminalView addGestureRecognizer:_tapGesture];
    
    // Double tap to toggle keyboard
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] 
        initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    // Attach to the full view so it still works when the terminal doesn't fill the screen
    [self.view addGestureRecognizer:doubleTap];
    [_tapGesture requireGestureRecognizerToFail:doubleTap];
    
    // Swipe up to show keyboard
    _swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    _swipeUpGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:_swipeUpGesture];
    
    // Swipe down to hide keyboard
    _swipeDownGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
    _swipeDownGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:_swipeDownGesture];
    
    // Long press for context menu / look command
    _longPressGesture = [[UILongPressGestureRecognizer alloc] 
        initWithTarget:self action:@selector(handleLongPress:)];
    _longPressGesture.minimumPressDuration = 0.5;
    [_terminalView addGestureRecognizer:_longPressGesture];
}

- (void)setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self 
               selector:@selector(handleGameWillBackground:) 
                   name:@"SilGameWillBackground" 
                 object:nil];
    
    [center addObserver:self 
               selector:@selector(handleGameDidForeground:) 
                   name:@"SilGameDidForeground" 
                 object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Lifecycle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Update scroll view content size
    _scrollView.contentSize = _terminalView.intrinsicContentSize;

    // Auto-fit content to the available area once (and when size changes)
    CGSize contentSize = _terminalView.intrinsicContentSize;
    CGSize scrollSize = _scrollView.bounds.size;
    if (contentSize.width > 0 && contentSize.height > 0 && scrollSize.width > 0 && scrollSize.height > 0) {
        CGFloat scaleX = scrollSize.width / contentSize.width;
        CGFloat scaleY = scrollSize.height / contentSize.height;
        CGFloat fitScale = MIN(scaleX, scaleY);
        fitScale = MAX(_scrollView.minimumZoomScale, MIN(fitScale, _scrollView.maximumZoomScale));

        if (!_didSetInitialZoom || fabs(_scrollView.zoomScale - fitScale) > 0.25) {
            _scrollView.zoomScale = fitScale;
            _didSetInitialZoom = YES;
        }

        CGSize scaledSize = CGSizeMake(contentSize.width * _scrollView.zoomScale, contentSize.height * _scrollView.zoomScale);
        CGFloat offsetX = MAX(0, (scrollSize.width - scaledSize.width) / 2);
        CGFloat offsetY = MAX(0, (scrollSize.height - scaledSize.height) / 2);
        _scrollView.contentInset = UIEdgeInsetsMake(offsetY, offsetX, offsetY, offsetX);
        return;
    }
    
    // Center content if smaller than scroll view
    CGSize fallbackContentSize = _terminalView.intrinsicContentSize;
    CGSize fallbackScrollSize = _scrollView.bounds.size;
    CGFloat fallbackOffsetX = MAX(0, (fallbackScrollSize.width - fallbackContentSize.width) / 2);
    CGFloat fallbackOffsetY = MAX(0, (fallbackScrollSize.height - fallbackContentSize.height) / 2);
    _scrollView.contentInset = UIEdgeInsetsMake(fallbackOffsetY, fallbackOffsetX, fallbackOffsetY, fallbackOffsetX);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Gesture Handlers

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;
    
    CGPoint point = [gesture locationInView:_terminalView];
    
    switch (_touchMode) {
        case SilTouchModeMovement:
            [self handleMovementTap:point];
            break;
        case SilTouchModeTarget:
            [self handleTargetTap:point];
            break;
        case SilTouchModeDisabled:
            break;
    }
}

- (void)handleMovementTap:(CGPoint)point {
    // Divide the terminal into a 3x3 grid for movement
    CGSize termSize = _terminalView.bounds.size;
    
    int col = (int)(point.x / (termSize.width / 3));
    int row = (int)(point.y / (termSize.height / 3));
    
    col = MIN(2, MAX(0, col));
    row = MIN(2, MAX(0, row));
    
    int index = row * 3 + col;
    unichar movementKey = kMovementKeyMap[index];
    
    [self queueKey:movementKey modifiers:0];
}

- (void)handleTargetTap:(CGPoint)point {
    // Convert to terminal coordinates
    int col, row;
    if ([_terminalView terminalCoordinatesForPoint:point col:&col row:&row]) {
        // Queue movement to target position
        // This is a simplified version - full implementation would
        // calculate the direction and queue appropriate keys
        [self queueKey:'*' modifiers:0]; // Enter targeting mode
        // Additional targeting logic would go here
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    [self toggleKeyboard];
}

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)gesture {
    [self setKeyboardVisible:YES animated:YES];
}

- (void)handleSwipeDown:(UISwipeGestureRecognizer *)gesture {
    [self setKeyboardVisible:NO animated:YES];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gesture locationInView:_terminalView];
        
        // Convert to terminal coordinates and trigger look command
        int col, row;
        if ([_terminalView terminalCoordinatesForPoint:point col:&col row:&row]) {
            [self queueKey:'l' modifiers:0]; // Look command
        }
    }
}

#pragma mark - Keyboard Management

- (BOOL)keyboardVisible {
    return !_keyboardView.hidden;
}

- (void)setKeyboardVisible:(BOOL)show animated:(BOOL)animated {
    // Keep the toggle button out of the way when the keyboard is visible.
    _keyboardToggleButton.hidden = show;

    // When hidden, collapse keyboard height and let the scroll view use the full screen.
    _keyboardBottomConstraint.active = show;
    _noKeyboardConstraint.active = !show;
    _keyboardHeightConstraint.constant = show ? 220 : 0;

    if (show) {
        [_keyboardView showAnimated:animated];
    } else {
        [_keyboardView hideAnimated:animated];
    }
    
    [self.view setNeedsLayout];
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)toggleKeyboard {
    [self setKeyboardVisible:!self.keyboardVisible animated:YES];
}

#pragma mark - SilKeyboardViewDelegate

- (void)keyboardView:(SilKeyboardView *)keyboard 
          didPressKey:(unichar)key
           modifiers:(UIKeyModifierFlags)modifiers {
    [self queueKey:key modifiers:modifiers];
}

- (void)keyboardView:(SilKeyboardView *)keyboard didChangeMode:(SilKeyboardMode)mode {
    // Could update UI or behavior based on keyboard mode
}

#pragma mark - Key Queue

- (void)queueKey:(unichar)key modifiers:(UIKeyModifierFlags)modifiers {
    // Apply modifiers if needed
    unichar finalKey = key;
    
    if (modifiers & UIKeyModifierControl) {
        if (key >= 'a' && key <= 'z') {
            finalKey = key - 'a' + 1;
        } else if (key >= 'A' && key <= 'Z') {
            finalKey = key - 'A' + 1;
        }
    }
    
    // Push the key directly into the Term's key queue
    Term_keypress((int)finalKey);
    
    // Also keep in our local queue as backup
    int nextTail = (_keyQueueTail + 1) % KEY_QUEUE_SIZE;
    if (nextTail != _keyQueueHead) {
        _keyQueue[_keyQueueTail] = finalKey;
        _keyQueueTail = nextTail;
    }
}

- (void)queueString:(NSString *)string {
    for (NSUInteger i = 0; i < string.length; i++) {
        [self queueKey:[string characterAtIndex:i] modifiers:0];
    }
}

// Called from the game's key checking function
int sil_ios_get_key(void) {
    if (_keyQueueHead == _keyQueueTail) {
        return 0; // No key available
    }
    
    unichar key = _keyQueue[_keyQueueHead];
    _keyQueueHead = (_keyQueueHead + 1) % KEY_QUEUE_SIZE;
    return key;
}

// Check if a key is available
int sil_ios_check_key(void) {
    return (_keyQueueHead != _keyQueueTail) ? 1 : 0;
}

#pragma mark - Display

- (void)refreshDisplay {
    [_terminalView refreshDisplay];
}

#pragma mark - Background/Foreground Handling

- (void)handleGameWillBackground:(NSNotification *)notification {
    // Save game state if needed
    // The game's main loop should handle this
}

- (void)handleGameDidForeground:(NSNotification *)notification {
    // Refresh display
    [self refreshDisplay];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _containerView;
}

#pragma mark - Hardware Keyboard Support

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray<UIKeyCommand *> *)keyCommands {
    static NSMutableArray *commands = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        commands = [NSMutableArray array];
        
        // Add key commands for all printable ASCII characters
        for (unichar c = ' '; c <= '~'; c++) {
            NSString *key = [NSString stringWithCharacters:&c length:1];
            
            // Regular key
            [commands addObject:[UIKeyCommand keyCommandWithInput:key
                                                    modifierFlags:0
                                                           action:@selector(handleKeyCommand:)]];
            
            // With shift
            [commands addObject:[UIKeyCommand keyCommandWithInput:key
                                                    modifierFlags:UIKeyModifierShift
                                                           action:@selector(handleKeyCommand:)]];
            
            // With control
            [commands addObject:[UIKeyCommand keyCommandWithInput:key
                                                    modifierFlags:UIKeyModifierControl
                                                           action:@selector(handleKeyCommand:)]];
        }
        
        // Arrow keys
        [commands addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)]];
        [commands addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)]];
        [commands addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)]];
        [commands addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)]];
        
        // Escape
        [commands addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)]];
        
        // Return
        [commands addObject:[UIKeyCommand keyCommandWithInput:@"\r"
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)]];
    });
    
    return commands;
}

- (void)handleKeyCommand:(UIKeyCommand *)command {
    NSString *input = command.input;
    UIKeyModifierFlags modifiers = command.modifierFlags;
    
    unichar key = 0;
    
    if ([input isEqualToString:UIKeyInputUpArrow]) {
        key = '8'; // Numpad up
    } else if ([input isEqualToString:UIKeyInputDownArrow]) {
        key = '2'; // Numpad down
    } else if ([input isEqualToString:UIKeyInputLeftArrow]) {
        key = '4'; // Numpad left
    } else if ([input isEqualToString:UIKeyInputRightArrow]) {
        key = '6'; // Numpad right
    } else if ([input isEqualToString:UIKeyInputEscape]) {
        key = 27; // Escape
    } else if (input.length > 0) {
        key = [input characterAtIndex:0];
    }
    
    if (key != 0) {
        [self queueKey:key modifiers:modifiers];
    }
}

@end
