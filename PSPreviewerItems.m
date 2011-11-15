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
	previewerItems = [[NSMutableArray alloc] init];
	
	return self;
}

- (NSArray *)previewerItems
{
	return previewerItems;
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
		if([previewerItems containsObject:item]) {
			[newItems addObject:item];
		}
	}
	
	// リストアされていないがロード済のプラグインを追加
	for(PSPreviewerItem *item in previewerItems) {
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
	
	[previewerItems autorelease];
	previewerItems = [newItems retain];
}

- (void)awakePreviewers
{
	for(PSPreviewerItem *item in previewerItems) {
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
	
	[pluginBundle load];
	pluginClass = [pluginBundle principalClass];
	if(!pluginClass) return;
	if(![pluginClass conformsToProtocol:@protocol(BSImagePreviewerProtocol)]
	   && ![pluginClass conformsToProtocol:@protocol(BSLinkPreviewing)]) return;
	plugin = [[[pluginClass alloc] initWithPreferences:[[PreviewerSelector sharedInstance] preferences]] autorelease];
	if(!plugin) return;
	
	item = [[[PSPreviewerItem alloc] initWithIdentifier:[pluginBundle bundleIdentifier]] autorelease];
	[item setTryCheck:YES];
	[item setDisplayInMenu:YES];
	[item setPreviewer:plugin];
	[item setPath:fullpath];
	
	id v = [pluginBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if(v) {
		[item setVersion:v];
	} else {
		[item setVersion:@""];
	}
	
	v = [pluginBundle objectForInfoDictionaryKey:@"BSPreviewerDisplayName"];
	if(v) {
		[item setDisplayName:v];
	} else {
		[item setDisplayName:name];
	}
	
	if(![previewerItems containsObject:item]) {
		[previewerItems addObject:item];
	}
}
- (void)loadDefaultPreviewer
{
	NSBundle *b = [NSBundle mainBundle];
	id pluginDirPath = [b builtInPlugInsPath];
	NSFileManager *dfm = [NSFileManager defaultManager];
	NSArray *files = [dfm directoryContentsAtPath:pluginDirPath];
	
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
	NSArray *files = [dfm directoryContentsAtPath:path];
	
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
