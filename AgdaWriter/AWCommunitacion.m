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
        [self startTask];

    }
    return self;
}


- (void) dataAvailabe:(NSNotification *) notification {
    
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString * reply = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSArray * actions = [AWAgdaParser makeArrayOfActions:reply];
    [AWNotifications notifyExecuteActions:actions];
    [AWNotifications notifyAgdaReplied:reply];
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
    task.arguments = @[@"--interaction"];
    task.standardInput = outputPipe;
    task.standardOutput = inputPipe;
    BOOL exists = [[NSFileManager defaultManager] isExecutableFileAtPath:[task launchPath]];
    if (exists) {
        [task launch];
    }
    else
    {
        // File can't be lauched!
        NSLog(@"File can't be launched!\nLaunch path not accessible.");
        // TODO: set launch path manually;
    }
    
}

- (void) openPipes
{
//    [[NSProcessInfo processInfo] processIdentifier];
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
//    [self stopTask];
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
