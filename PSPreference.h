/* PSPreference */

#import <Cocoa/Cocoa.h>

@interface PSPreference : NSWindowController
{
	IBOutlet NSTableView *pluginsView;
	NSMutableArray *plugInList;
}

+ (id)sharedInstance;
- (void)setPlugInList:(id)list;

- (IBAction)togglePreferencePanel: (id) sender;
@end
