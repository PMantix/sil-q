/**
 * \file ios/SilTerminalView.h
 * \brief Terminal rendering view for iOS Sil-Q
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

/**
 * Terminal cell structure for storing character and attribute data
 */
typedef struct {
    wchar_t character;
    uint8_t attribute;
    BOOL dirty;
} SilTerminalCell;

/**
 * SilTerminalView renders the game's terminal output.
 * It displays an 80x24 grid of characters with colored attributes.
 */
@interface SilTerminalView : UIView

/** Number of columns in the terminal (default 80) */
@property (nonatomic, readonly) int cols;

/** Number of rows in the terminal (default 24) */
@property (nonatomic, readonly) int rows;

/** Width of each character cell in points */
@property (nonatomic, readonly) CGFloat cellWidth;

/** Height of each character cell in points */
@property (nonatomic, readonly) CGFloat cellHeight;

/** Current cursor column position */
@property (nonatomic) int cursorCol;

/** Current cursor row position */
@property (nonatomic) int cursorRow;

/** Whether the cursor is visible */
@property (nonatomic) BOOL cursorVisible;

/** The font used for terminal rendering */
@property (nonatomic, strong) UIFont *terminalFont;

/**
 * Initialize the terminal with specified dimensions.
 * @param cols Number of columns
 * @param rows Number of rows
 * @return Initialized terminal view
 */
- (instancetype)initWithCols:(int)cols rows:(int)rows;

/**
 * Clear the entire terminal.
 */
- (void)clearTerminal;

/**
 * Clear a region of the terminal.
 * @param x Starting column
 * @param y Starting row
 * @param width Number of columns to clear
 * @param height Number of rows to clear
 */
- (void)clearRegionAtX:(int)x y:(int)y width:(int)width height:(int)height;

/**
 * Set a character at a specific position.
 * @param character The character to display
 * @param attribute The color/attribute for the character
 * @param x Column position
 * @param y Row position
 */
- (void)setCharacter:(wchar_t)character attribute:(uint8_t)attribute atX:(int)x y:(int)y;

/**
 * Draw a string at a specific position.
 * @param string The string to display
 * @param attribute The color/attribute for the string
 * @param x Starting column position
 * @param y Row position
 */
- (void)drawString:(const char *)string attribute:(uint8_t)attribute atX:(int)x y:(int)y;

/**
 * Get the color for a terminal attribute.
 * @param attribute The terminal attribute (0-15)
 * @return UIColor for the attribute
 */
- (UIColor *)colorForAttribute:(uint8_t)attribute;

/**
 * Refresh the display (marks view for redraw).
 */
- (void)refreshDisplay;

/**
 * Convert a touch point to terminal coordinates.
 * @param point Touch point in view coordinates
 * @param outCol Output column (nullable)
 * @param outRow Output row (nullable)
 * @return YES if point is within terminal bounds
 */
- (BOOL)terminalCoordinatesForPoint:(CGPoint)point col:(int *)outCol row:(int *)outRow;

@end
