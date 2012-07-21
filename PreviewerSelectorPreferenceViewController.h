//
//  PreviewerSelectorPreferenceViewController.h
//  PreviewerSelector
//
//  Created by 堀 昌樹 on 12/07/15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreviewerSelectorPreferenceViewController : NSViewController
{
	IBOutlet NSArrayController *itemsController;
	NSTableView *_tableView;
	NSMutableArray *plugInList;
}
@property (assign, nonatomic) IBOutlet NSTableView *tableView;

- (id)init;

- (void)setPlugInList:(id)list;

- (IBAction)openPreferences:(id)sender;
- (IBAction)toggleAPlugin:(id)sender;
@end
