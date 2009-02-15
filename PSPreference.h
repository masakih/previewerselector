/* PSPreference */

#import <Cocoa/Cocoa.h>

@interface PSPreference : NSWindowController
{
	IBOutlet NSTableView *pluginsView;
	IBOutlet NSArrayController *itemsController;
	
	NSMutableArray *plugInList;
}

+ (id)sharedInstance;
- (void)setPlugInList:(id)list;

- (IBAction)togglePreferencePanel: (id) sender;
@end
