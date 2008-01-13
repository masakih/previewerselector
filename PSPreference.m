#import "PSPreference.h"

#import "PreviewerSelector.h"

@interface PSPreference(PSPrivate)
- (id)privateInit;
@end

@implementation PSPreference

static PSPreference *sSharedInstance = nil;

+ (id)sharedInstance
{
	if(!sSharedInstance) {
		sSharedInstance = [[self alloc] privateInit];
	}
	
	return sSharedInstance;
}

- (id)privateInit
{
	self = [super initWithWindowNibName:@"Preference"];
	if(self) {
		//
	}
	
	return self;
}
- (id)init
{
	self = [super init];
	[self release];
	
	return [[self class] sharedInstance];
}
- (void)dealloc
{
	[plugInList release];
	
	[super dealloc];
}
- (void)awakeFromNib
{
	[self setWindowFrameAutosaveName:@"PreviewerSelectorPreferenceWindow"];
	
	[pluginsView setDoubleAction:@selector(toggleAPlugin:)];
	[pluginsView setTarget:self];
}

- (void)setPlugInList:(id)list
{
	id temp = plugInList;
	plugInList = [list retain];
	[temp release];
}

- (IBAction)toggleAPlugin:(id)sender
{
	int selectedRow = [pluginsView selectedRow];
	if(selectedRow == -1) return;
	
	id info = [plugInList objectAtIndex:selectedRow];
	id obj = [info objectForKey:@"PlugInObjectKey"];
	if(!obj) return;
	
	if([obj respondsToSelector:@selector(togglePreviewPanel:)]) {
		[obj performSelector:@selector(togglePreviewPanel:) withObject:self];
	}
}
- (IBAction)togglePreferencePanel: (id) sender
{
	if([[self window] isVisible]) {
		[[self window] orderOut:self];
	} else {
		[self showWindow:self];
	}
}
- (IBAction)openPreferences:(id)sender
{
	int selectedRow = [pluginsView selectedRow];
	if(selectedRow == -1) return;
	
	id info = [plugInList objectAtIndex:selectedRow];
	id obj = [info objectForKey:@"PlugInObjectKey"];
	if(!obj) return;
	
	if([obj respondsToSelector:@selector(showPreviewerPreferences:)]) {
		[obj performSelector:@selector(showPreviewerPreferences:) withObject:self];
	}
}

#pragma mark## NSMenu Delegate ##
enum _PreferenceMenuTags {
	kOpenPreviewer = 10000,
	kOpenPreferences = 10001,
};
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	int selectedRow = [pluginsView selectedRow];
	if(selectedRow == -1) return NO;
	
	id info = [plugInList objectAtIndex:selectedRow];
	id obj = [info objectForKey:@"PlugInObjectKey"];
	if(!obj) return NO;
	
	id displayName = [info objectForKey:@"PlugInDisplayNameKey"];
	
	switch([menuItem tag]) {
		case kOpenPreviewer:
		{
			if(displayName) {
				id title = [NSString stringWithFormat:PSLocalizedString(@"Open %@", @"Open Previewer."), displayName];
				[menuItem setTitle:title];
			}
			if([obj respondsToSelector:@selector(togglePreviewPanel:)]) {
				return YES;
			}
			break;
		}
		case kOpenPreferences:
			if(displayName) {
				id title = [NSString stringWithFormat:PSLocalizedString(@"Open %@'s Preferences", @"Open Previewer Preferences."), displayName];
				[menuItem setTitle:title];
			}
			if([obj respondsToSelector:@selector(showPreviewerPreferences:)]) {
				return YES;
			}
			break;
		default:
			//
			break;
	}
	
	return NO;
}

@end
