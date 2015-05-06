//
//  AWMainTextView.m
//  AgdaWriter
//
//  Created by Marko Koležnik on 29. 01. 15.
//  Copyright (c) 2015 koleznik.net. All rights reserved.
//

#import "AWMainTextView.h"
#import "AWNotifications.h"
#import "CustomTokenCell.h"
#import "AWAgdaParser.h"

@implementation AWMainTextView

-(void)awakeFromNib
{
//    NSLog(@"%@", self.description);
    if (!initialize) {
        [self toggleAutomaticDashSubstitution:NO];
        [self toggleContinuousSpellChecking:NO];
        
        [self setContinuousSpellCheckingEnabled:NO];
        self.delegate = self;
        [NSApplication sharedApplication].delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addToken:) name:@"AW.addToken" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChangedInRangeWithReplacementString:) name:@"textChangedInRangeWithReplacementString" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHelp) name:@"showHelp" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allGoalsAction:) name:AWAllGoals object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(placeInsertionPointAtCharIndex:) name:AWPlaceInsertionPointAtCharIndex object:nil];
        
        
        initialize = YES;
        
        mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:self.textStorage.string];
        // Set Attributes for attributed string
        NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
        defaultAttributes = @{
                              NSForegroundColorAttributeName : [NSColor blackColor],
                              NSFontAttributeName : [NSFont fontWithName:[ud objectForKey:FONT_FAMILY_KEY] size:[[ud objectForKey:FONT_SIZE_KEY] doubleValue]],
                              NSBackgroundColorAttributeName : [NSColor whiteColor]
                              };
        
        goalsAttributes = @{
                            NSForegroundColorAttributeName : [NSColor blueColor],
                            NSBackgroundColorAttributeName : [NSColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.5],
                            };
        
        [mutableAttributedString addAttributes:defaultAttributes range:NSMakeRange(0, mutableAttributedString.length)];
        goalsArray = [NSMutableArray new];
        
        [self openLastDocument];
        
        


    }
    
    
    
}

- (void)insertAttachmentCell:(NSTextAttachmentCell *)cell toTextView:(NSTextView *)textView
{
    NSTextAttachment *attachment = [NSTextAttachment new];
    [attachment setAttachmentCell:cell];
    [textView insertText:[NSAttributedString attributedStringWithAttachment:attachment]];
}


-(void)textViewDidChangeSelection:(NSNotification *)notification
{
    NSLog(@"%@", notification.userInfo);
    
    NSRange range = [notification.userInfo[@"NSOldSelectedCharacterRange"] rangeValue];
    NSLog(@"Selected range: (%li, %li)", range.location, range.length);
    
}


-(void)setString:(NSString *)string
{
    // Overrride this method to set Attributed string!
    [super setString:string];
    mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:self.textStorage.string];
    [mutableAttributedString addAttributes:defaultAttributes range:NSMakeRange(0, mutableAttributedString.length)];
    [[self textStorage] setAttributedString:mutableAttributedString];
}

- (void) openLastDocument
{
    NSUserDefaults *ud = [[NSUserDefaults alloc] init];
    NSString * path = [ud objectForKey:@"currentFile"];
    if (path) {
        NSError * error;
        NSString * fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"Error occoured when opening document: %@", error.description);
            return;
        }
        // double check if fileContent is initialized.
        if (fileContent) {
            [self setString:fileContent];
            [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL URLWithString:path]];
        }
        
    }
}

-(BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    
    return YES;
}

- (void)saveCurrentWork
{
    // TODO: error handling
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    NSString * fullPath = [ud objectForKey:@"currentFile"];
    NSError * error;
    NSString *content = [[self textStorage] string];
    if (content) {
        [content writeToFile:fullPath
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error];
        if (error) {
            NSLog(@"Error saving file. Reason: %@", error.description);
        }
    }
    

}

- (IBAction)save:(id)sender
{
    [self saveCurrentWork];
}

- (void) recolorText
{
    [self setTextColor:[NSColor blackColor]];
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"//.*" options:0 error:nil];
    [regex enumerateMatchesInString:[self.textStorage string] options:0 range:NSMakeRange(0, self.textStorage.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
    {
        [self setTextColor:[NSColor colorWithRed:94.0/255.0 green:126.0/255.0 blue:28.0/255.0 alpha:1.0] range:result.range];
    }];
    

}

- (void) textChangedInRangeWithReplacementString:(NSNotification *) notification
{
    NSDictionary * dictionary = notification.object;
    NSRange range = [dictionary[@"range"] rangeValue];
    NSString * replacementString = dictionary[@"replacementString"];
    NSLog(@"range: (%li, %li), replacementString: %@", range.location, range.location + range.length, replacementString);
    
    if ([replacementString isEqualToString:@"/"]) {
        NSDate * regexStart = [NSDate date];
        [self asynchronouslyFindRangesOfCommentsWithCompletion:^(NSArray * matches) {
            
            NSDate *methodStart = [NSDate date];
            
            NSLog(@"number of matches %li", matches.count);
            [self setTextColor:[NSColor blackColor]];
            [self.textStorage beginEditing];
            
            for (NSTextCheckingResult * result in matches) {
                [self setTextColor:[NSColor colorWithRed:94.0/255.0 green:126.0/255.0 blue:28.0/255.0 alpha:1.0] range:result.range];
            }
            
            [self.textStorage endEditing];
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            NSLog(@"regex execution time: %f s, execution time for coloring: %f s", [methodStart timeIntervalSinceDate:regexStart], executionTime);
        }];
    }
    
    
    
}

- (void)asynchronouslyFindRangesOfCommentsWithCompletion:(void (^)(NSArray *))matches;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        // Asynchronously find all ranges with regex
        // Regex pattern: //.*
        // Finds all strings that begins with // and returns its range to the end of the line.
        
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"//.*" options:0 error:nil];
        NSArray * results = [regex matchesInString:self.textStorage.string options:0 range:NSMakeRange(0, self.textStorage.length)];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (matches) {
                
                matches(results);
            }
        });
    });
}

- (void)asynchronouslyFindRangesOfQuestionMarksWithCompletion:(void (^)(NSArray *))matches;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        // Asynchronously find all ranges with regex
        // Regex pattern: //.*
        // Finds all strings that begins with // and returns its range to the end of the line.
        NSMutableArray * results = [NSMutableArray new];
        
        NSRange searchRange = NSMakeRange(0, self.textStorage.length);
        NSRange foundRange;
        while (searchRange.location < self.textStorage.length) {
            searchRange.length = self.textStorage.length - searchRange.location;
            foundRange = [self.textStorage.string rangeOfString:@"?" options:NSCaseInsensitiveSearch range:searchRange];
            if (foundRange.location != NSNotFound) {
                // found an occurrence of the substring! do stuff here
                
                
                searchRange.location = foundRange.location + foundRange.length;
            } else {
                // no more substring to find
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (matches) {
                
                matches(results);
            }
        });
    });
}

- (void) setDefaultText
{
    NSDate *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"dd. MM. YY."];
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    
    
    NSString * welcomeString = @"";
    welcomeString = [welcomeString stringByAppendingString:@"//  \n"];
    welcomeString = [welcomeString stringByAppendingFormat:@"//  Created by %@ on %@ \n", NSFullUserName(), dateString];
    welcomeString = [welcomeString stringByAppendingString:@"//  \n"];
    [self setString: welcomeString];
    
    

}

- (NSRange) replaceQuestionMarkInRange:(NSRange)range WithType:(NSString *)type
{
    [self replaceCharactersInRange:range withString:type];
    [mutableAttributedString replaceCharactersInRange:range withString:type];
    
    NSRange newRange = NSMakeRange(range.location, type.length);
    return newRange;
}


- (void) showHelp
{
    NSRange searchRange = NSMakeRange(0, self.textStorage.length);
    NSRange foundRange;
    while (searchRange.location < self.textStorage.length) {
        searchRange.length = self.textStorage.length - searchRange.location;
        foundRange = [self.textStorage.string rangeOfString:@"?" options:NSCaseInsensitiveSearch range:searchRange];
        if (foundRange.location != NSNotFound) {
            // found an occurrence of the substring!
            
            // Show all questionmarks
            [self showFindIndicatorForRange:foundRange];
            
            searchRange.location = foundRange.location + foundRange.length;
        } else {
            // no more substring to find
            break;
        }
    }
}


-(void) allGoalsAction:(NSNotification *)notification
{
    if ([notification.object isKindOfClass:[NSString class]]) {
        // Parse goals
        NSArray * goals = [AWAgdaParser makeArrayOfGoalsWithSuggestions:notification.object];
        
        // Add tokens on goals

        int i = 0;
        NSRange searchRange = NSMakeRange(0, self.textStorage.length);
        NSRange foundRange;
        while (searchRange.location < self.textStorage.length) {
            searchRange.length = self.textStorage.length - searchRange.location;
            foundRange = [self.textStorage.string rangeOfString:@" ?" options:NSCaseInsensitiveSearch range:searchRange];
            if (foundRange.location != NSNotFound) {
                // found an occurrence of the substring!
                
                
                [self addTokenAtRange:foundRange withGoalName:[goals objectAtIndex:i]];
                i++;

                searchRange.location = foundRange.location + foundRange.length;
            } else {
                // no more substring to find
                break;
            }
        }
    }
}

-(void) addTokenAtRange:(NSRange)range withGoalName:(NSString *)goalName
{
    NSTextAttachment * attachment = [[NSTextAttachment alloc] initWithFileWrapper:nil];
    NSMutableAttributedString * text = [NSMutableAttributedString new];
//    [text appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"?"]];
    CustomTokenCell * tokenCell = [[CustomTokenCell alloc] init];
    [tokenCell setTitle:goalName];
    
    [attachment setAttachmentCell:tokenCell];
    [text appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [self insertText:text replacementRange: NSMakeRange(range.location + 1, range.length - 1)];
    
//    CustomTokenCell * gfsgfdgfds = (CustomTokenCell *)attachment.attachmentCell;
//    NSLog(@"attachment cell name: %@", gfsgfdgfds.title);
    
//    NSError * error;
//    NSFileWrapper * fileWrapper = [self.attributedString fileWrapperFromRange:NSMakeRange(0, self.attributedString.length) documentAttributes:@{NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType} error:&error];
//    if (error){
//        NSLog(@"Saving failed: %@", error.description);
//    }
//    [fileWrapper writeToURL:[NSURL fileURLWithPath:@"/Users/markokoleznik/Desktop/blablablalba"] options:NSFileWrapperWritingAtomic originalContentsURL:nil error:&error];
//    if (error){
//        NSLog(@"Saving failed: %@", error.description);
//    }

}

- (void) addToken:(NSNotification *)notification
{
    NSTextAttachment * attachment = [[NSTextAttachment alloc] initWithFileWrapper:nil];
    CustomTokenCell * tokenCell = [[CustomTokenCell alloc] init];
    [tokenCell setTitle:@"Here is some token!"];
    [attachment setAttachmentCell:tokenCell];
    [self insertText:[NSAttributedString attributedStringWithAttachment:attachment]];
}

- (void) placeInsertionPointAtCharIndex:(NSNotification *) notification
{
    [self setSelectedRange:NSMakeRange([notification.object integerValue] + 1, 0)];
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
