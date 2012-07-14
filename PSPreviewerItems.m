//
//  PSPreviewerItems.m
//  PreviewerSelector
//
//  Created by Hori,Masaki on 10/09/12.
//  Copyright 2010 masakih. All rights reserved.
//

#import "PSPreviewerItems.h"
#import "PSPreviewerItem.h"


#import "PreviewerSelector.h"


#define AppIdentifierString @"com.masakih.previewerSelector"
static NSString *keyPrefPlugInsInfo2 = AppIdentifierString @"." @"PlugInsInfo2";

static NSString *builtInPreviewerName = @"BuiltIn";
static NSString *noarmalImagePreviewerName = @"ImagePreviewer";


@interface PSPreviewerItems ()
- (void)loadPlugIns;
- (void)awakePreviewers;
@end

@implementation PSPreviewerItems

- (id)init
{
	[super init];
	_previewerItems = [[NSMutableArray alloc] init];
	
	return self;
}

- (NSArray *)previewerItems
{
	return _previewerItems;
}
- (void)setPreference:(id)pref
{
	[self loadPlugIns];
	[self awakePreviewers];
	
	NSMutableArray *newItems = [NSMutableArray array];
	NSArray *retoredItems = nil;
	
	NSData *itemsData = [[[[PreviewerSelector sharedInstance] preferences] imagePreviewerPrefsDict] objectForKey:keyPrefPlugInsInfo2];
	if(!itemsData) {
		return;
	} else {
		retoredItems = [NSKeyedUnarchiver unarchiveObjectWithData:itemsData];
	}
	
	// リストアされ且つロード済のプラグインを追加
	for(PSPreviewerItem *item in retoredItems) {
		if([_previewerItems containsObject:item]) {
			[newItems addObject:item];
		}
	}
	
	// リストアされていないがロード済のプラグインを追加
	for(PSPreviewerItem *item in _previewerItems) {
		if(![newItems containsObject:item]) {
			[newItems addObject:item];
		} else {
			NSInteger index = [newItems indexOfObject:item];
			PSPreviewerItem *restoredItem = [newItems objectAtIndex:index];
			if(![restoredItem.version isEqualToString:item.version]) {
				[newItems replaceObjectAtIndex:index withObject:item];
			}
		}
	}
	
	[_previewerItems autorelease];
	_previewerItems = [newItems retain];
}

- (void)awakePreviewers
{
	for(PSPreviewerItem *item in _previewerItems) {
		id previewer = [item previewer];
		if([previewer respondsToSelector:@selector(awakeByPreviewerSelector:)]) {
			[previewer performSelector:@selector(awakeByPreviewerSelector:)
							withObject:[PreviewerSelector sharedInstance]];
		}
	}
}

- (void)registPlugIn:(NSBundle *)pluginBundle name:(NSString *)name path:(NSString *)fullpath
{
	Class pluginClass;
	id plugin;
	PSPreviewerItem *item;
	
	if([pluginBundle isLoaded]) return;
	
	pluginClass = [pluginBundle principalClass];
	if(!pluginClass) return;
	if(![pluginClass conformsToProtocol:@protocol(BSImagePreviewerProtocol)]
	   && ![pluginClass conformsToProtocol:@protocol(BSLinkPreviewing)]) return;
	plugin = [[[pluginClass alloc] initWithPreferences:[[PreviewerSelector sharedInstance] preferences]] autorelease];
	if(!plugin) return;
	
	item = [[[PSPreviewerItem alloc] initWithIdentifier:[pluginBundle bundleIdentifier]] autorelease];
	item.tryCheck = YES;
	item.displayInMenu = YES;
	item.previewer = plugin;
	item.path = fullpath;
	
	id v = [pluginBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	item.version = v ?: @"";
	
	v = [pluginBundle objectForInfoDictionaryKey:@"BSPreviewerDisplayName"];
	item.displayName = v ?: name;
	
	if(![_previewerItems containsObject:item]) {
		[_previewerItems addObject:item];
	}
}
- (void)loadDefaultPreviewer
{
	NSBundle *b = [NSBundle mainBundle];
	id pluginDirPath = [b builtInPlugInsPath];
	NSFileManager *dfm = [NSFileManager defaultManager];
	NSArray *files = [dfm contentsOfDirectoryAtPath:pluginDirPath error:NULL];
	
	for(NSString *file in files) {
		NSString *fullpath = [pluginDirPath stringByAppendingPathComponent:file];
		NSString *name = [file stringByDeletingPathExtension];
		NSBundle *pluginBundle;
		
		if(![name isEqualToString:noarmalImagePreviewerName]) continue;
		
		pluginBundle = [NSBundle bundleWithPath:fullpath];
		if(!pluginBundle) return;
		
		[self registPlugIn:pluginBundle name:builtInPreviewerName path:fullpath];
	}
}

- (void)loadPlugIns
{
	NSString *path = [[PreviewerSelector sharedInstance] plugInsDirectory];
	NSFileManager *dfm = [NSFileManager defaultManager];
	NSArray *files = [dfm contentsOfDirectoryAtPath:path error:NULL];
	
	[self loadDefaultPreviewer];
	
	for(NSString *file in files) {
		NSString *fullpath = [path stringByAppendingPathComponent:file];
		NSString *name = [file stringByDeletingPathExtension];
		NSBundle *pluginBundle;
		
		if([name isEqualToString:noarmalImagePreviewerName]) continue;
		
		pluginBundle = [NSBundle bundleWithPath:fullpath];
		if(!pluginBundle) continue;
		
		[self registPlugIn:pluginBundle name:name path:fullpath];
	}
}

@end
