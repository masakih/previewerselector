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
	
	NSMutableArray *plugInList;
}
@property (readonly) NSTableView *tableView;

- (id)init;

- (void)setPlugInList:(id)list;

- (IBAction)openPreferences:(id)sender;
- (IBAction)toggleAPlugin:(id)sender;
@end
