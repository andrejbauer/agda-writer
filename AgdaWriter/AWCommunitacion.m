//
//  AWCommunitacion.m
//  AgdaWriter
//
//  Created by Marko Koležnik on 3. 02. 15.
//  Copyright (c) 2015 koleznik.net. All rights reserved.
//

#import "AWCommunitacion.h"
#import "AWNotifications.h"
#import "AWAgdaParser.h"

@implementation AWCommunitacion


-(id) init
{
    self = [super init];
    if (self) {
        
        [self openPipes];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dataAvailabe:)
                                                     name:NSFileHandleReadToEndOfFileCompletionNotification
                                                   object:nil];
    }
    return self;
}


- (void) dataAvailabe:(NSNotification *) notification {
    
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString * reply = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([reply hasPrefix:NSHomeDirectory()]) {
        [AWNotifications notifyPossibleAgdaPathFound:reply];
    }
    else {
        
        NSArray * actions = [AWAgdaParser makeArrayOfActions:reply];
        [AWNotifications notifyExecuteActions:actions];
        [AWNotifications notifyAgdaReplied:reply];
    }
}


- (void) stopTask
{
    [task terminate];
}



- (void) startTask
{
    task = [NSTask new];
    // PATH TO AGDA
    task.launchPath = [AWNotifications agdaLaunchPath];
    NSLog(@"launch path: %@", task.launchPath);
    task.arguments = @[@"--interaction"];
    task.standardInput = outputPipe;
    task.standardOutput = inputPipe;
    BOOL exists = [[NSFileManager defaultManager] isExecutableFileAtPath:[task launchPath]];
    if (exists) {
        @try {
            [task launch];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@", exception.reason);
            NSAlert * alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Open Prefreneces..."];
            [alert setMessageText:@"Task can't be launched!\nCheck your path in Settings."];
            [alert setAlertStyle:NSWarningAlertStyle];
            if ([alert runModal] == NSAlertFirstButtonReturn) {
                NSLog(@"Open preferences");
                [AWNotifications notifyOpenPreferences];
            }
        }
        @finally {

        }
        
    }
    else
    {
        // File can't be lauched!
        NSLog(@"File can't be launched!\nLaunch path not accessible.");
        // TODO: set launch path by user
        [self setPathToAgdaByUser];
    }
    
}

-(void) searchForAgda
{
    [self openPipes];
    task = [NSTask new];
    // PATH TO AGDA
    task.launchPath = @"/usr/bin/find";
    NSLog(@"launch path: %@", task.launchPath);
    task.arguments = @[NSHomeDirectory(), @"-name", @"agda"];
    task.standardInput = outputPipe;
    task.standardOutput = inputPipe;
    
    @try {
        [task launch];
    }
    @catch (NSException *exception) {
        NSLog(@"exception: %@", exception.description);
    }
    @finally {
        
    }
    

    
}

- (void) setPathToAgdaByUser
{
    
    // loading bar, spinning style
//    NSProgressIndicator * indicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 20, 30, 30)];
//    [indicator setStyle:NSProgressIndicatorSpinningStyle];
//    
//    [indicator startAnimation:nil];
    
    // try to find agda automatically (in Haskell file)
        // asynchronously find file
    
    // Text input with Browse Button
    
    // Save file path
    
    // Check if file at that path is executable
    
    // Test Agda (check Agda Version)
    
    // if success, launch task
        // [task launch];
}

- (void) openPipes
{
    inputPipe = [NSPipe pipe];
    outputPipe = [NSPipe pipe];
    fileReading = inputPipe.fileHandleForReading;
    [fileReading readToEndOfFileInBackgroundAndNotify];
    fileWriting = outputPipe.fileHandleForWriting;
}

- (void) closePipes
{
    
}

- (void) writeData: (NSString * ) message
{
    [self openPipes];
    [self startTask];
    [fileWriting writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    [fileWriting closeFile];
}


#pragma mark -
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}






@end
