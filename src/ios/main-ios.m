/**
 * \file main-ios.m
 * \brief iOS front end for Sil-Q
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

#include "angband.h"

#if defined(USE_IOS)

#import <UIKit/UIKit.h>
#import "SilAppDelegate.h"
#import "SilViewController.h"
#import "SilTerminalView.h"

/* Creator signature for iOS */
#ifndef SIL_CREATOR
# define SIL_CREATOR 'SilI'
#endif

/* Forward declarations */
static void Term_init_ios(term *t);
static void Term_nuke_ios(term *t);
static errr Term_xtra_ios(int n, int v);
static errr Term_curs_ios(int x, int y);
static errr Term_wipe_ios(int x, int y, int n);
static errr Term_text_ios(int x, int y, int n, byte_hack a, const char *cp);

/* External functions from SilViewController */
extern int sil_ios_get_key(void);
extern int sil_ios_check_key(void);

/* The iOS term data structure */
typedef struct ios_term_data {
    term t;
    int rows;
    int cols;
} ios_term_data;

/* Global term data for the main term */
static ios_term_data *ios_term = NULL;

/* Flag to indicate game is running */
static BOOL game_in_progress = NO;

/* Flag to track if we're waiting for input */
static BOOL waiting_for_input = NO;

#pragma mark - Path Configuration

/**
 * Get the application support directory for Sil-Q
 */
static NSString *get_app_support_directory(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupport = [paths firstObject];
    NSString *silDir = [appSupport stringByAppendingPathComponent:@"Sil-Q"];
    
    // Create if it doesn't exist
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:silDir]) {
        [fm createDirectoryAtPath:silDir 
      withIntermediateDirectories:YES 
                       attributes:nil 
                            error:nil];
    }
    
    return silDir;
}

/**
 * Get the lib directory within the app bundle
 */
static NSString *get_lib_directory(void) {
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"lib"];
}

/**
 * Initialize file paths for the game
 */
static void init_file_paths(void) {
    NSString *libPath = get_lib_directory();
    NSString *appSupportPath = get_app_support_directory();
    
    // Convert paths to C strings
    const char *lib = [libPath fileSystemRepresentation];
    const char *user = [[appSupportPath stringByAppendingPathComponent:@"user"] 
                        fileSystemRepresentation];
    const char *save = [[appSupportPath stringByAppendingPathComponent:@"save"] 
                        fileSystemRepresentation];
    
    // Set up the data path (read-only, in bundle)
    // The init_file_paths function in init2.c will handle setting up all paths
    // We just need to set ANGBAND_DIR
    
    // Create user and save directories in app support
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:[appSupportPath stringByAppendingPathComponent:@"user"]
  withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:[appSupportPath stringByAppendingPathComponent:@"save"]
  withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Copy lib directory contents if needed (first run)
    NSString *destLib = [appSupportPath stringByAppendingPathComponent:@"lib"];
    if (![fm fileExistsAtPath:destLib]) {
        NSError *error = nil;
        [fm copyItemAtPath:libPath toPath:destLib error:&error];
        if (error) {
            NSLog(@"Error copying lib directory: %@", error);
        }
    }
    
    // Set the lib path - using app support so it's writable
    char *path = strdup([[appSupportPath stringByAppendingPathComponent:@"lib"] 
                         fileSystemRepresentation]);
    
    // This should be called early in initialization
    // The actual path setup is handled by init_angband()
    setenv("ANGBAND_PATH", path, 1);
}

#pragma mark - Term Hooks

/**
 * Initialize a new term
 */
static void Term_init_ios(term *t) {
    // Nothing special needed - view is already set up
}

/**
 * Destroy a term
 */
static void Term_nuke_ios(term *t) {
    // Clean up if needed
}

/**
 * React to events - the main input/output handler
 */
static errr Term_xtra_ios(int n, int v) {
    @autoreleasepool {
        switch (n) {
            case TERM_XTRA_NOISE:
                // Play a system sound
                // AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                break;
                
            case TERM_XTRA_BORED:
                // Process events while idle
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode 
                                         beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                break;
                
            case TERM_XTRA_EVENT:
                // Wait for an event (v is wait flag)
                waiting_for_input = YES;
                if (v) {
                    // Blocking wait - run the loop until we get a key
                    while (!sil_ios_check_key()) {
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode 
                                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                    }
                } else {
                    // Non-blocking - just check once
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode 
                                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                }
                waiting_for_input = NO;
                break;
                
            case TERM_XTRA_FLUSH:
                // Flush pending events
                while (sil_ios_check_key()) {
                    sil_ios_get_key();
                }
                break;
                
            case TERM_XTRA_LEVEL:
                // Activate/deactivate term - not needed on iOS
                break;
                
            case TERM_XTRA_CLEAR:
                // Clear the screen
                dispatch_async(dispatch_get_main_queue(), ^{
                    SilViewController *vc = [SilViewController sharedController];
                    [vc.terminalView clearTerminal];
                    [vc.terminalView refreshDisplay];
                });
                break;
                
            case TERM_XTRA_REACT:
                // React to color/visual changes
                break;
                
            case TERM_XTRA_DELAY:
                // Delay for v milliseconds
                if (v > 0) {
                    [NSThread sleepForTimeInterval:v / 1000.0];
                }
                break;
                
            case TERM_XTRA_FRESH:
                // Refresh the display
                dispatch_async(dispatch_get_main_queue(), ^{
                    SilViewController *vc = [SilViewController sharedController];
                    [vc.terminalView refreshDisplay];
                });
                break;
                
            default:
                return 1;
        }
    }
    
    return 0;
}

/**
 * Set the cursor position
 */
static errr Term_curs_ios(int x, int y) {
    dispatch_async(dispatch_get_main_queue(), ^{
        SilViewController *vc = [SilViewController sharedController];
        vc.terminalView.cursorCol = x;
        vc.terminalView.cursorRow = y;
        vc.terminalView.cursorVisible = YES;
        [vc.terminalView refreshDisplay];
    });
    
    return 0;
}

/**
 * Erase n characters at position (x, y)
 */
static errr Term_wipe_ios(int x, int y, int n) {
    dispatch_async(dispatch_get_main_queue(), ^{
        SilViewController *vc = [SilViewController sharedController];
        [vc.terminalView clearRegionAtX:x y:y width:n height:1];
    });
    
    return 0;
}

/**
 * Draw n characters at position (x, y) with attribute a
 */
static errr Term_text_ios(int x, int y, int n, byte_hack a, const char *cp) {
    // Make a copy of the string data for the async block
    char *text = strndup(cp, n);
    byte_hack attr = a;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        SilViewController *vc = [SilViewController sharedController];
        
        for (int i = 0; i < n && text[i]; i++) {
            [vc.terminalView setCharacter:text[i] attribute:attr atX:x + i y:y];
        }
        
        free(text);
    });
    
    return 0;
}

#pragma mark - Input Handling

/**
 * Check if a key is available
 */
static errr Term_check_ios(void) {
    return sil_ios_check_key() ? 0 : 1;
}

/**
 * Get the next key from the queue
 */
int Term_inkey_ios(void) {
    return sil_ios_get_key();
}

#pragma mark - Term Setup

/**
 * Create and initialize the iOS term
 */
static void init_ios_term(void) {
    // Allocate term data
    ios_term = calloc(1, sizeof(ios_term_data));
    if (!ios_term) return;
    
    // Set dimensions - standard 80x24 terminal
    ios_term->cols = 80;
    ios_term->rows = 24;
    
    // Initialize the term
    term *t = &ios_term->t;
    term_init(t, ios_term->cols, ios_term->rows, 256);
    
    // Set term flags
    t->soft_cursor = TRUE;  // We draw our own cursor
    t->icky_corner = FALSE;
    t->higher_pict = FALSE;
    t->always_pict = FALSE;
    t->never_bored = FALSE;
    t->never_frosh = FALSE;
    
    // Set hooks
    t->init_hook = Term_init_ios;
    t->nuke_hook = Term_nuke_ios;
    t->xtra_hook = Term_xtra_ios;
    t->curs_hook = Term_curs_ios;
    t->wipe_hook = Term_wipe_ios;
    t->text_hook = Term_text_ios;
    
    // Store reference
    t->data = ios_term;
    
    // Activate and register
    Term_activate(t);
    angband_term[0] = t;
}

#pragma mark - Main Entry Point

/**
 * Initialize the iOS frontend and start the game
 */
void init_ios(void) {
    @autoreleasepool {
        // Initialize file paths
        init_file_paths();
        
        // Initialize the term
        init_ios_term();
        
        // Mark game as in progress
        game_in_progress = YES;
    }
}

/**
 * Main function for iOS - called from the app delegate
 */
int ios_main(int argc, char *argv[]) {
    @autoreleasepool {
        // Initialize the iOS frontend
        init_ios();
        
        // Start the Angband initialization
        // This would normally call init_angband() and then play_game()
        // For now, we return control to the iOS run loop
        
        return 0;
    }
}

/**
 * Run the game loop - called after UI is ready
 */
void ios_run_game(void) {
    @autoreleasepool {
        // Make sure we're on a background thread for the game loop
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Initialize Angband
            init_angband();
            
            // Main game loop
            play_game(FALSE);
            
            // Game ended
            game_in_progress = NO;
        });
    }
}

#pragma mark - iOS App Main

/**
 * iOS application main entry point
 */
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SilAppDelegate class]));
    }
}

#endif /* USE_IOS */
