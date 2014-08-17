//
//  DragDropView.m
//  CheckMD5
//
//  Created by wanswings on 2014/08/13.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "DragDropView.h"

@implementation DragDropView

static NSString * const CONST_DROPPED = @"droppedFile";

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    }
    return self;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    highlight=YES;
    [self setNeedsDisplay: YES];
    return NSDragOperationGeneric;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    highlight=NO;
    [self setNeedsDisplay: YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    highlight=NO;
    [self setNeedsDisplay: YES];
    return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
    NSArray *filenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    if ([filenames count] == 1) {
        return YES;
    }
    else {
        return NO;
    }
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    NSArray *fileNames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    NSString *fileName = [fileNames objectAtIndex:0];

    NSNotification *notification = [NSNotification notificationWithName:CONST_DROPPED object:fileName];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotification:notification];
// Alternative
//    AppDelegate *delegate = [[NSApplication sharedApplication] delegate];
//    [delegate droppedFile:fileName];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];

    if (highlight) {
        [[NSColor orangeColor] set];
        [NSBezierPath setDefaultLineWidth: 10];
        [NSBezierPath strokeRect: [self bounds]];
    }
    else {
        [[NSColor grayColor] set];
        [NSBezierPath setDefaultLineWidth: 10];
        [NSBezierPath strokeRect: [self bounds]];
    }

    @autoreleasepool {
        NSString *text = @"Drop any file here \n or \n Use the SELECT button";

        NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:paragraphStyle
                                                        forKey:NSParagraphStyleAttributeName];
        NSRect strFrame = { { 8, 8 }, { 200, 55 } };
        [text drawInRect:strFrame withAttributes:attributes];
    }
}

@end
