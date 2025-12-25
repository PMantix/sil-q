/**
 * \file ios/SilTerminalView.m
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

#import "SilTerminalView.h"

/** Standard Angband/Sil color palette */
static const uint32_t sil_colors[16] = {
    0x000000,  // TERM_DARK (black)
    0xFFFFFF,  // TERM_WHITE
    0x9D9D9D,  // TERM_SLATE (gray)
    0xFF8D00,  // TERM_ORANGE
    0xB70000,  // TERM_RED
    0x009D44,  // TERM_GREEN
    0x0000FF,  // TERM_BLUE
    0x8D6600,  // TERM_UMBER (brown)
    0x747474,  // TERM_L_DARK (dark gray)
    0xD0D0D0,  // TERM_L_WHITE (light gray)
    0xFF00FF,  // TERM_VIOLET
    0xFFFF00,  // TERM_YELLOW
    0xFF4040,  // TERM_L_RED
    0x00FF00,  // TERM_L_GREEN
    0x00FFFF,  // TERM_L_BLUE
    0xC79D55,  // TERM_L_UMBER (light brown)
};

@implementation SilTerminalView {
    SilTerminalCell *_cells;
    CGSize _contentSize;
    NSMutableDictionary<NSNumber *, UIColor *> *_colorCache;
    NSDictionary<NSAttributedStringKey, id> *_textAttributes;
}

- (instancetype)initWithCols:(int)cols rows:(int)rows {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _cols = cols;
        _rows = rows;
        _cursorCol = 0;
        _cursorRow = 0;
        _cursorVisible = NO;
        
        // Allocate cell buffer
        _cells = calloc(cols * rows, sizeof(SilTerminalCell));
        
        // Initialize color cache
        _colorCache = [NSMutableDictionary dictionary];
        
        // Set up default font - use a monospace font
        _terminalFont = [UIFont fontWithName:@"Menlo-Regular" size:14.0];
        if (!_terminalFont) {
            _terminalFont = [UIFont monospacedSystemFontOfSize:14.0 weight:UIFontWeightRegular];
        }
        
        [self updateCellSize];
        [self clearTerminal];
        
        // Dark background
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithCols:80 rows:24];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _cols = 80;
        _rows = 24;
        _cells = calloc(_cols * _rows, sizeof(SilTerminalCell));
        _colorCache = [NSMutableDictionary dictionary];
        _terminalFont = [UIFont monospacedSystemFontOfSize:14.0 weight:UIFontWeightRegular];
        [self updateCellSize];
        [self clearTerminal];
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)dealloc {
    if (_cells) {
        free(_cells);
        _cells = NULL;
    }
}

- (void)updateCellSize {
    // Measure cell size based on font
    NSDictionary *attrs = @{NSFontAttributeName: _terminalFont};
    CGSize charSize = [@"W" sizeWithAttributes:attrs];
    
    _cellWidth = ceil(charSize.width);
    _cellHeight = ceil(charSize.height);
    
    _contentSize = CGSizeMake(_cellWidth * _cols, _cellHeight * _rows);
    
    // Update text attributes
    _textAttributes = @{NSFontAttributeName: _terminalFont};
    
    [self invalidateIntrinsicContentSize];
}

- (void)setTerminalFont:(UIFont *)terminalFont {
    _terminalFont = terminalFont;
    [self updateCellSize];
    [self setNeedsDisplay];
}

- (CGSize)intrinsicContentSize {
    return _contentSize;
}

#pragma mark - Terminal Operations

- (void)clearTerminal {
    for (int i = 0; i < _cols * _rows; i++) {
        _cells[i].character = ' ';
        _cells[i].attribute = 0; // TERM_DARK
        _cells[i].dirty = YES;
    }
    [self setNeedsDisplay];
}

- (void)clearRegionAtX:(int)x y:(int)y width:(int)width height:(int)height {
    for (int row = y; row < y + height && row < _rows; row++) {
        for (int col = x; col < x + width && col < _cols; col++) {
            int idx = row * _cols + col;
            _cells[idx].character = ' ';
            _cells[idx].attribute = 0;
            _cells[idx].dirty = YES;
        }
    }
    [self setNeedsDisplay];
}

- (void)setCharacter:(wchar_t)character attribute:(uint8_t)attribute atX:(int)x y:(int)y {
    if (x < 0 || x >= _cols || y < 0 || y >= _rows) return;
    
    int idx = y * _cols + x;
    _cells[idx].character = character;
    _cells[idx].attribute = attribute;
    _cells[idx].dirty = YES;
}

- (void)drawString:(const char *)string attribute:(uint8_t)attribute atX:(int)x y:(int)y {
    if (!string || y < 0 || y >= _rows) return;
    
    int col = x;
    const char *p = string;
    while (*p && col < _cols) {
        [self setCharacter:(wchar_t)*p attribute:attribute atX:col y:y];
        p++;
        col++;
    }
}

- (void)refreshDisplay {
    [self setNeedsDisplay];
}

#pragma mark - Color Management

- (UIColor *)colorForAttribute:(uint8_t)attribute {
    NSNumber *key = @(attribute & 0x0F);
    UIColor *color = _colorCache[key];
    
    if (!color) {
        uint32_t rgb = sil_colors[attribute & 0x0F];
        CGFloat r = ((rgb >> 16) & 0xFF) / 255.0;
        CGFloat g = ((rgb >> 8) & 0xFF) / 255.0;
        CGFloat b = (rgb & 0xFF) / 255.0;
        color = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
        _colorCache[key] = color;
    }
    
    return color;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return;
    
    // Fill background
    [[UIColor blackColor] setFill];
    CGContextFillRect(context, rect);
    
    // Calculate visible cell range
    int startCol = MAX(0, (int)(rect.origin.x / _cellWidth));
    int endCol = MIN(_cols, (int)ceil((rect.origin.x + rect.size.width) / _cellWidth));
    int startRow = MAX(0, (int)(rect.origin.y / _cellHeight));
    int endRow = MIN(_rows, (int)ceil((rect.origin.y + rect.size.height) / _cellHeight));
    
    // Draw cells
    for (int row = startRow; row < endRow; row++) {
        for (int col = startCol; col < endCol; col++) {
            int idx = row * _cols + col;
            SilTerminalCell cell = _cells[idx];
            
            CGRect cellRect = CGRectMake(col * _cellWidth, row * _cellHeight, 
                                         _cellWidth, _cellHeight);
            
            // Draw character if not space
            if (cell.character != ' ' && cell.character != 0) {
                UIColor *textColor = [self colorForAttribute:cell.attribute];
                
                NSString *charString = [NSString stringWithFormat:@"%C", (unichar)cell.character];
                NSDictionary *attrs = @{
                    NSFontAttributeName: _terminalFont,
                    NSForegroundColorAttributeName: textColor
                };
                
                [charString drawAtPoint:cellRect.origin withAttributes:attrs];
            }
            
            _cells[idx].dirty = NO;
        }
    }
    
    // Draw cursor
    if (_cursorVisible && _cursorCol >= 0 && _cursorCol < _cols && 
        _cursorRow >= 0 && _cursorRow < _rows) {
        CGRect cursorRect = CGRectMake(_cursorCol * _cellWidth, _cursorRow * _cellHeight,
                                       _cellWidth, _cellHeight);
        
        [[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.7] setFill];
        CGContextFillRect(context, cursorRect);
        
        // Redraw character under cursor with inverted color
        int idx = _cursorRow * _cols + _cursorCol;
        SilTerminalCell cell = _cells[idx];
        if (cell.character != ' ' && cell.character != 0) {
            NSString *charString = [NSString stringWithFormat:@"%C", (unichar)cell.character];
            NSDictionary *attrs = @{
                NSFontAttributeName: _terminalFont,
                NSForegroundColorAttributeName: [UIColor blackColor]
            };
            [charString drawAtPoint:cursorRect.origin withAttributes:attrs];
        }
    }
}

#pragma mark - Coordinate Conversion

- (BOOL)terminalCoordinatesForPoint:(CGPoint)point col:(int *)outCol row:(int *)outRow {
    int col = (int)(point.x / _cellWidth);
    int row = (int)(point.y / _cellHeight);
    
    if (col >= 0 && col < _cols && row >= 0 && row < _rows) {
        if (outCol) *outCol = col;
        if (outRow) *outRow = row;
        return YES;
    }
    
    return NO;
}

@end
