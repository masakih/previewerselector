#import "PSPreference.h"

#import "PreviewerSelectorPreferenceViewController.h"

@implementation PSPreference

static PSPreference *sSharedInstance = nil;

+ (PSPreference*)sharedPreference
{
	if (sSharedInstance == nil) {
		sSharedInstance = [[super allocWithZone:NULL] initWithWindowNibName:@"Preference"];
	}
	return sSharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self sharedPreference] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (NSUInteger)retainCount
{
	return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
	//do nothing
}

- (id)autorelease
{
	return self;
}
- (void)awakeFromNib
{
	[self setWindowFrameAutosaveName:@"PreviewerSelectorPreferenceWindow"];
	viewController = [[PreviewerSelectorPreferenceViewController alloc] init];
	[[self window] setContentView:[viewController view]];
}

- (void)setPlugInList:(id)list
{
	if(!viewController) [self loadWindow];
	[viewController setPlugInList:list];
}


- (IBAction)togglePreferencePanel: (id) sender
{
	if([[self window] isVisible]) {
		[[self window] orderOut:self];
	} else {
		[self showWindow:self];
	}
}
@end
