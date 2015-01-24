//
//  AWMainWindow.m
//  AgdaWriter
//
//  Created by Marko Koležnik on 15. 10. 14.
//  Copyright (c) 2014 koleznik.net. All rights reserved.
//

#import "AWMainWindow.h"
#import "MAAttachedWindow.h"
#import "TestView.h"
#import "AWNotifications.h"

@implementation AWMainWindow

@synthesize delegate;

#pragma mark - initialize

-(void)awakeFromNib
{
    // Called, when xib is loaded
    self.mainTextView.delegate = self;
    [self.mainTextView setString:@"Some pre-entered text! :)"];
//    NSLog(@"Font description: %@",self.mainTextView.font.description);
    
    // Add this class as observer, when font (in Prefrences) is changed. It might be reusable in other classes as well.
    // Don't forget to remove observer in dealloc, because it has strong pointer to self.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeFontSizeFromNotification:) name:fontSizeChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeFontFamilyFromNotification:) name:fontFamilyChanged object:nil];
    
}

-(void) textDidBeginEditing:(NSNotification *)notification
{
    // Called, when user pressed a key in our "editor" window.
    // This method is called before any visual change is made. After this method, textDidChange is called.
    

}


- (void) textDidChange:(NSNotification *)notification
{
    // Here we can send typed words to Agda.
    

}

-(void)changeFontSizeFromNotification:(NSNotification *)notification
{
    // When "fontSizeChanged" notification is recieved, change font to our editor
    if ([notification.object isKindOfClass:[NSNumber class]]) {
        
        NSNumber *fontSize = (NSNumber *) notification.object;
        NSFont *font = self.mainTextView.font;
        font = [[NSFontManager sharedFontManager] convertFont:font toSize:[fontSize floatValue]];
        [self.mainTextView setFont:font];
        
    }
}
- (void) changeFontFamilyFromNotification:(NSNotification *)notification
{
    if ([notification.object isKindOfClass:[NSString class]]) {
        NSString *fontFamily = (NSString *) notification.object;
        NSFont *font = self.mainTextView.font;
        font = [[NSFontManager sharedFontManager] convertFont:font toFamily:fontFamily];
        [self.mainTextView setFont:font];
    }
}

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
    // Called, when we select text
    
    // Check for selected range, and put rectangle around it.
    NSRange selectedText = [self.mainTextView selectedRange];
    NSRect rectangle = [self.mainTextView firstRectForCharacterRange:selectedText actualRange:nil];
    
    
//    int location = (int)selectedText.location;
    int lenght = (int) selectedText.length;
    if (lenght > 0) {
        [self.numberLabel setStringValue:[NSString stringWithFormat:@"%i", lenght]];
        
        [self.mainTextView addToolTipRect:NSMakeRect(100, 100, 300, 300) owner:self userData:nil];
        
        // Open help window
        [self showHelpWindowAtRect:rectangle];
    }
    else
    {
        // Remove window!
        // TODO: use delegation to remove help window.
        [self.numberLabel setStringValue:@""];
        for (NSWindow *window in self.childWindows) {
            if ([window.identifier isEqualToString:@"Helper"]) {
                [self removeChildWindow:window];
                self.isHelperWindowOpened = NO;
            }
        }
    }
}


-(void) showHelpWindowAtRect: (NSRect) rect
{
    // If one instance of window is already opened, return.
    if (self.isHelperWindowOpened) {
        return;
    }
    

    // TODO: Change fixed values. For testing only.
    NSView * view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, 300)];
    
    NSImageView * imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 90, 180, 200)];
    NSString *myImagePath = [[NSBundle mainBundle] pathForResource:@"xcode_pic" ofType:@"png"];
    NSImage * image = [[NSImage alloc] initWithContentsOfFile:myImagePath];
    [imageView setImage:image];
    [view addSubview:imageView];
    
#pragma mark - handling subviews
    
    NSTextField *subview = [[NSTextField alloc] initWithFrame:NSMakeRect(5, 10, 200, 50)];
    [subview setStringValue:@"Some help text here."];
    [subview setTextColor:[NSColor whiteColor]];
    [subview setDrawsBackground:NO];
    [subview setBezeled:NO];
    [subview setDrawsBackground:NO];
    [subview setEditable:NO];
    [subview setSelectable:NO];
    [view addSubview:subview];
    
    
    // Set origin of the window to the center-bottom of selected word.
    MAAttachedWindow * window = [[MAAttachedWindow alloc] initWithView:view attachedToPoint:NSMakePoint(rect.origin.x + rect.size.width/2, rect.origin.y)];
    window.identifier = @"Helper";
    [window setTitle:@"Title"];
    // Animation upon opening.
    [window setAnimationBehavior:NSWindowAnimationBehaviorAlertPanel];
    [self addChildWindow:window ordered:1];
    
    // Animation inside window (on it's child view) -> For experimenting only.
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.5f;
        view.animator.frame = CGRectOffset(view.frame, 20, 0);
    } completionHandler:^{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 1.0f;
            view.animator.frame = CGRectOffset(view.frame, -20, 0);
        } completionHandler:nil];
        
    }];
    
    self.isHelperWindowOpened = YES;

}



-(NSString *) description
{
    return @"Tooltip effect";
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end