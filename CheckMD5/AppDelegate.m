//
//  AppDelegate.m
//  CheckMD5
//
//  Created by wanswings on 2014/08/13.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize targetPath;
@synthesize targetMD5;
@synthesize sourceMD5;

static NSString * const CONST_APPNAME = @"CheckMD5";
static NSString * const CONST_PROCMD5 = @"/sbin/md5";
static NSString * const CONST_PROCSSL = @"/usr/bin/openssl";
static NSString * const CONST_DROPPED = @"droppedFile";

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:CONST_DROPPED object:nil];
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [targetPath setEditable:NO];
    [targetMD5 setEditable:NO];
    [sourceMD5 setEditable:NO];

    procMD5 = CONST_PROCMD5;
    if (![[NSFileManager defaultManager] fileExistsAtPath:procMD5]) {
        procMD5 = CONST_PROCSSL;
        if (![[NSFileManager defaultManager] fileExistsAtPath:procMD5]) {
            NSRunAlertPanel(CONST_APPNAME,
                            @"Cannot find %@ or %@",
                            @"OK", nil, nil,
                            CONST_PROCMD5, CONST_PROCSSL);
            [NSApp terminate:self];
        }
    }

    lastCountPasteboard = 0;
    [NSTimer scheduledTimerWithTimeInterval:1
            target:self selector:@selector(observePasteboard:) userInfo:nil repeats:YES];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(droppedFile:) name:CONST_DROPPED object:nil];

    if (waitFilename != nil) {
        NSNotification *notification = [NSNotification notificationWithName:CONST_DROPPED object:waitFilename];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotification:notification];
        waitFilename = nil;
    }

    runningAPP = YES;
}

- (void)compMD5
{
    NSString *tMD5 = [targetMD5 stringValue];
    NSString *sMD5 = [sourceMD5 stringValue];

    if ([tMD5 isEqualToString:@""] || [sMD5 isEqualToString:@""]) {
        [targetMD5 setBackgroundColor:[NSColor whiteColor]];
        [sourceMD5 setBackgroundColor:[NSColor whiteColor]];
    }
    else if ([tMD5 isEqualToString:sMD5]) {
        // OK
        [targetMD5 setBackgroundColor:[NSColor greenColor]];
        [sourceMD5 setBackgroundColor:[NSColor greenColor]];
        NSLog(@"MD5 OK!");
    }
    else {
        // NG
        [targetMD5 setBackgroundColor:[NSColor redColor]];
        [sourceMD5 setBackgroundColor:[NSColor redColor]];
        NSLog(@"MD5 NG!");
    }
}

- (void)observePasteboard:(NSTimer *)timer
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    if (pboard.changeCount > lastCountPasteboard) {
        NSArray *types = [NSArray arrayWithObject:@"NSStringPboardType"];
        if ([pboard availableTypeFromArray:types] != nil) {
            NSData *pbData = [pboard dataForType:NSStringPboardType];
            NSString *str = [[NSString alloc] initWithData:pbData encoding:NSUTF8StringEncoding];
            NSString *lowerStr = [str lowercaseString];
            NSString *result = nil;
            NSRange match = [lowerStr rangeOfString:@"[0-9a-f]+" options:NSRegularExpressionSearch];
            if (match.location != NSNotFound) {
                result = [lowerStr substringWithRange:match];
                if (result.length == 32) {
                    [sourceMD5 setStringValue:result];
                    NSLog(@"Pasteboard: %@", result);
                    [self compMD5];
                }
            }
        }
    }
    lastCountPasteboard = pboard.changeCount;
}

- (NSString *)calcMD5:(NSString *)path
{
    @autoreleasepool {
        NSTask *task = [NSTask new];
        NSPipe *pipe = [NSPipe new];
        [task setLaunchPath:procMD5];
        if ([procMD5 isEqualToString:CONST_PROCSSL])    [task setArguments:@[ @"md5", path ]];
        else                                            [task setArguments:@[ path ]];
        [task setStandardOutput:pipe];
        [task launch];

        NSData *data = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
        NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSLog(@"MD5 in: %@", str);

        NSString *result = nil;
        NSRange match = [str rangeOfString:@"[0-9a-f]+$" options:NSRegularExpressionSearch];
        if (match.location != NSNotFound) {
            result = [str substringWithRange:match];
        }
        else {
            result = @"Cannot calculate MD5";
        }

        NSLog(@"MD5 out: %@", result);
        return result;
    }
}

- (void)droppedFile:(NSNotification *)notification
{
    [targetPath setStringValue:notification.object];
    NSString *result = [self calcMD5:notification.object];
    [targetMD5 setStringValue:result];
    [self compMD5];
}
// Alternative
//- (void)droppedFile:(NSString *)filePath
//{
//}

- (IBAction)finderButton:(id)sender
{
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    // Sets whether the user can select multiple files (and directories) at one time for opening.
    [openDlg setAllowsMultipleSelection:NO];
    // Sets whether the user can select directories in the panel’s browser.
    [openDlg setCanChooseDirectories:NO];
    // Sets whether the user can select files in the panel’s browser.
    [openDlg setCanChooseFiles:YES];
    // Sets the prompt of the default button.
    [openDlg setPrompt:@"Select"];

    // Display the dialog.  If the OK button was pressed,
    // process the files.
    if ([openDlg runModal] == NSOKButton) {
        // Get the full filename.
        NSString *filePath = [[openDlg URL] path];

        [targetPath setStringValue:filePath];
        NSString *result = [self calcMD5:filePath];
        [targetMD5 setStringValue:result];
        [self compMD5];
    }
}

// Add Document Type first. (Project > Targets > Info > Document Types)
//  CFBundleTypeExtensions: *
//  Document Type Name: File
//  Role: Viewer
//  Cocoa NSDocument Class: NSDocument
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filePath
{
    if (runningAPP) {
        [targetPath setStringValue:filePath];
        NSString *result = [self calcMD5:filePath];
        [targetMD5 setStringValue:result];
        [self compMD5];
    }
    else {
        waitFilename = [NSString stringWithString:filePath];
    }
    return YES;
}

@end
