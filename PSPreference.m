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
	
	[pluginsView setDoubleAction:@selector(toggleAPlugin:)];
	[pluginsView setTarget:self];
	
	[pluginsView registerForDraggedTypes:[NSArray arrayWithObject:PSPItemPastboardType]];
	
	[itemsController addObserver:self forKeyPath:@"selection.tryCheck" options:0 context:itemsController];
	[itemsController addObserver:self forKeyPath:@"selection.displayInMenu" options:0 context:itemsController];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(context == itemsController) {
		[[PreviewerSelector sharedInstance] savePlugInsInfo];
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
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
	
	NSUInteger index = [rowIndexes firstIndex];
	
	[pboard declareTypes:[NSArray arrayWithObjects:PSPItemPastboardType, PSPRowIndexType, nil] owner:nil];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[plugInList objectAtIndex:index]]
			forType:PSPItemPastboardType];
	[pboard setPropertyList:[NSNumber numberWithUnsignedInteger:index] forType:PSPRowIndexType];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)targetTableView
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	if(![[pboard types] containsObject:PSPItemPastboardType]) {
		return NSDragOperationNone;
	}
	
	if(dropOperation == NSTableViewDropOn) {
        [targetTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	}
	
	NSUInteger originalRow = [[pboard propertyListForType:PSPRowIndexType] unsignedIntegerValue];
	if(row == originalRow || row == originalRow + 1) {
		return NSDragOperationNone;
	}
	
	return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView*)tableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	if(![[pboard types] containsObject:PSPItemPastboardType]) {
		return NO;
	}
	
	if(row < 0) row = 0;
	
	NSUInteger originalRow = [[pboard propertyListForType:PSPRowIndexType] unsignedIntegerValue];
	
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
