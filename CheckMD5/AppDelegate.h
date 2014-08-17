//
//  AppDelegate.h
//  CheckMD5
//
//  Created by wanswings on 2014/08/13.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    @private
    NSInteger lastCountPasteboard;
    NSString *procMD5;
    BOOL runningAPP;
    NSString *waitFilename;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *targetPath;
@property (weak) IBOutlet NSTextField *targetMD5;
@property (weak) IBOutlet NSTextField *sourceMD5;

- (IBAction)finderButton:(id)sender;
- (void)droppedFile:(NSString *)filePath;

@end
