/* PSPreference */

#import <Cocoa/Cocoa.h>

@class PreviewerSelectorPreferenceViewController;
@interface PSPreference : NSWindowController
{
	PreviewerSelectorPreferenceViewController *viewController;
}

+ (id)sharedPreference;
- (void)setPlugInList:(id)list;

- (IBAction)togglePreferencePanel: (id) sender;
@end
