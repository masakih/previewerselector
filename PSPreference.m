#import "PSPreference.h"

#import "PreviewerSelector.h"
#import "PSPreviewerItem.h"


@interface PSPreference(PSPrivate)
- (id)privateInit;
@end

@implementation PSPreference

static NSString *const PSPItemPastboardType = @"PSPItemPastboardType";
static NSString *const PSPRowIndexType = @"PSPRowIndexType";

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
	
	[pluginsView registerForDraggedTypes:[NSArray arrayWithObject:PSPItemPastboardType]];
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
	id obj = [info previewer];
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
	id obj = [info previewer];
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
	id obj = [info previewer];
	if(!obj) return NO;
	
	id displayName = [info displayName];
	
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



- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	if([rowIndexes count] != 1) return NO;
	
	unsigned int index = [rowIndexes firstIndex];
	
	[pboard declareTypes:[NSArray arrayWithObjects:PSPItemPastboardType, PSPRowIndexType, nil] owner:nil];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[plugInList objectAtIndex:index]]
			forType:PSPItemPastboardType];
	[pboard setPropertyList:[NSNumber numberWithUnsignedInt:index] forType:PSPRowIndexType];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)targetTableView
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	if(![[pboard types] containsObject:PSPItemPastboardType]) {
		return NSDragOperationNone;
	}
	
	if(dropOperation == NSTableViewDropOn) {
        [targetTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	}
	
	unsigned int originalRow = [[pboard propertyListForType:PSPRowIndexType] unsignedIntValue];
	if(row == originalRow || row == originalRow + 1) {
		return NSDragOperationNone;
	}
	
	return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView*)tableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	if(![[pboard types] containsObject:PSPItemPastboardType]) {
		return NO;
	}
	
	if(row < 0) row = 0;
	
	unsigned int originalRow = [[pboard propertyListForType:PSPRowIndexType] unsignedIntValue];
	
	NSData *itemData = [pboard dataForType:PSPItemPastboardType];
	PSPreviewerItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
	if(![item isKindOfClass:[PSPreviewerItem class]]) {
		return NO;
	}
	
	[self willChangeValueForKey:@"plugInList"];
	[plugInList insertObject:item atIndex:row];
	if(originalRow > row) originalRow++;
	[plugInList removeObjectAtIndex:originalRow];
	[self didChangeValueForKey:@"plugInList"];
	
	[[PreviewerSelector sharedInstance] savePlugInsInfo];
	
	return YES;
}


@end
