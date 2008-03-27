//
//  PreviewerSelector.m
//  PreviewerSelector
//
//  Created by Hori,Masaki on 06/05/07.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PreviewerSelector.h"
#import "PSPreference.h"
#import <objc/objc-class.h>

#pragma mark## Static Variable ##
static IMP orignalIMP;

NSMenuItem *psCommandItemWithLink(id self, SEL _cmd, id link, Class class, NSString *title)
{
	id obj = [PreviewerSelector sharedInstance];
	Class class_ = NSClassFromString(@"SGPreviewLinkCommand");
	NSMenuItem *res;
	
	if(class_ == class) {
	   res = [obj previewMenuItemForLink:link];
	   [res setTitle:title];
	} else {
		res = orignalIMP(self, _cmd, link, class, title);
	}
	
	return res;
}
static void psSwapMethod()
{
	Class target = NSClassFromString(@"CMRThreadView");
    Method method;
	
    method = class_getInstanceMethod(target, @selector(commandItemWithLink:command:title:));
	if(method) {
		orignalIMP = method->method_imp;
		method->method_imp = (IMP)psCommandItemWithLink;
	}
}

#pragma mark-
#pragma mark## Class variables ##
static PreviewerSelector *sSharedInstance;

#pragma mark-
#pragma mark## NSDictionary Keys ##
static NSString *keyPlugInPath = @"PlugInPathKey";
static NSString *keyPlugInObject = @"PlugInObjectKey";
static NSString *keyPlugInName = @"PlugInNameKey";
static NSString *keyPlugInDisplayName = @"PlugInDisplayNameKey";
static NSString *keyPlugInVersion = @"PlugInVersionKey";
static NSString *keyPlugInID = @"PlugInIDKey";
static NSString *keyPlugInIsUse = @"PlugInIsUseKey";
static NSString *keyPlugInIsDefault = @"PlugInIsDefaultKey";

static NSString *keyActionLink = @"ActionLinkKey";

#define AppIdentifierString @"com.masakih.previewerSelector"
static NSString *keyPrefPlugInsDir = AppIdentifierString @"." @"PlugInsDir";
static NSString *keyPrefPlugInsInfo = AppIdentifierString @"." @"PlugInsInfo";

#pragma mark## NSString Literals ##
static NSString *builtInPreviewerName = @"BuiltIn";
static NSString *noarmalImagePreviewerName = @"ImagePreviewer";

@interface PreviewerSelector(PSPrivate)
- (void)loadPlugIns;
@end

#pragma mark-
@implementation PreviewerSelector

+ (id)sharedInstance
{
    @synchronized(self) {
        if (sSharedInstance == nil) {
            [[self alloc] init]; // ここでは代入していない
        }
    }
    return sSharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {
		if (sSharedInstance == nil) {
			sSharedInstance = [super allocWithZone:zone];
			return sSharedInstance;  // 最初の割り当てで代入し、返す
		}
	}
	return sSharedInstance;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (unsigned)retainCount
{
	return UINT_MAX;  // 解放できないオブジェクトであることを示す
}

- (void)release
{
	// 何もしない
}

- (id)autorelease
{
	return self;
}
- (id)init
{
	if(self = [super init]) {
		loadedPlugInsInfo = [[NSMutableArray array] retain];
	}
	
	return self;
}

- (void)registPlugIn:(NSBundle *)pluginBundle name:(NSString *)name path:(NSString *)fullpath
{
	Class pluginClass;
	id plugin;
	NSMutableDictionary *info;
	
	if([pluginBundle isLoaded]) return;
	
	[pluginBundle load];
	pluginClass = [pluginBundle principalClass];
	if(!pluginClass) return;
	if(![pluginClass conformsToProtocol:@protocol(BSImagePreviewerProtocol)]) return;
	plugin = [[[pluginClass alloc] initWithPreferences:[self preferences]] autorelease];
	if(!plugin) return;
	
	info = [NSMutableDictionary dictionaryWithCapacity:8];
	[info setObject:plugin forKey:keyPlugInObject];
	[info setObject:name forKey:keyPlugInName];
	[info setObject:[pluginBundle bundleIdentifier] forKey:keyPlugInID];
	[info setObject:[NSNumber numberWithBool:YES] forKey:keyPlugInIsUse];
	[info setObject:fullpath forKey:keyPlugInPath];
	
	id v = [pluginBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if(v) {
		[info setObject:v forKey:keyPlugInVersion];
	} else {
		[info setObject:@"" forKey:keyPlugInVersion];
	}
	
	v = [pluginBundle objectForInfoDictionaryKey:@"BSPreviewerDisplayName"];
	if(v) {
		[info setObject:v forKey:keyPlugInDisplayName];
	} else {
		[info setObject:name forKey:keyPlugInDisplayName];
	}
	
	// ???
	[info addObserver:self
		   forKeyPath:keyPlugInIsDefault
			  options:NSKeyValueObservingOptionNew
			  context:NULL];
	[info addObserver:self
		   forKeyPath:keyPlugInIsUse
			  options:NSKeyValueObservingOptionNew
			  context:NULL];
	
	[loadedPlugInsInfo addObject:info];
}
- (void)loadDefaultPreviewer
{
	NSBundle *b = [NSBundle mainBundle];
	id pluginDirPath = [b builtInPlugInsPath];
	NSFileManager *dfm = [NSFileManager defaultManager];
	NSArray *files = [dfm directoryContentsAtPath:pluginDirPath];
	id enume, file;
	
	enume = [files objectEnumerator];
	while(file = [enume nextObject]) {
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
	NSString *path = [self plugInsDirectory];
	NSFileManager *dfm = [NSFileManager defaultManager];
	NSArray *files = [dfm directoryContentsAtPath:path];
	id enume, file;
	
	if([[self loadedPlugInsInfo] count] == 0) {
		[self loadDefaultPreviewer];
	}
	
	enume = [files objectEnumerator];
	while(file = [enume nextObject]) {
		NSString *fullpath = [path stringByAppendingPathComponent:file];
		NSString *name = [file stringByDeletingPathExtension];
		NSBundle *pluginBundle;
		
		if([name isEqualToString:noarmalImagePreviewerName]) continue;
		
		pluginBundle = [NSBundle bundleWithPath:fullpath];
		if(!pluginBundle) continue;
		
		[self registPlugIn:pluginBundle name:name path:fullpath];
	}
	
	[self restorePlugInsInfo];
	
	if(![self defaultPreviewerName]) {
		[self setDefaultPreviewerName:builtInPreviewerName];
	}
}

- (NSArray *)loadedPlugInsInfo
{
	return loadedPlugInsInfo;
}

- (void)savePlugInsInfo
{
	NSMutableDictionary *saveInfo = [NSMutableDictionary dictionary];
	id enums, obj;
	
	enums = [[self loadedPlugInsInfo] objectEnumerator];
	while(obj = [enums nextObject]) {
		id name = [obj objectForKey:keyPlugInName];
		id isUse = [obj objectForKey:keyPlugInIsUse];
		id isDefault = [obj objectForKey:keyPlugInIsDefault];
		
		id dict = [NSDictionary dictionaryWithObjectsAndKeys:isUse, keyPlugInIsUse,
			isDefault, keyPlugInIsDefault,
			nil];
		
		[saveInfo setObject:dict forKey:name];
	}
	[self setPreference:saveInfo forKey:keyPrefPlugInsInfo];
}
- (void)restorePlugInsInfo
{
	NSDictionary *infoDict = [[[self preferenceForKey:keyPrefPlugInsInfo] copy] autorelease];
	
	id enums, obj;
	id defaultPlugInName = nil;
	
	enums = [[self loadedPlugInsInfo] objectEnumerator];
	while(obj = [enums nextObject]) {
		id name = [obj objectForKey:keyPlugInName];
		
		id dict = [infoDict objectForKey:name];
		id isUse = [dict objectForKey:keyPlugInIsUse];
		if(isUse) {
			[obj setObject:isUse forKey:keyPlugInIsUse];
		}
		id isDefault = [dict objectForKey:keyPlugInIsDefault];
		if(isDefault && [isDefault boolValue]) {
			defaultPlugInName = name;
		}
	}
	if(defaultPlugInName) {
		[self setDefaultPreviewerName:defaultPlugInName];
	}
}

- (NSMenuItem *)preferenceMenuItem
{
	id res;
	NSString *title = PSLocalizedString(@"Preference...", @"Preference Menu Item.");
	
	res = [[[NSMenuItem alloc] initWithTitle:title action:Nil keyEquivalent:@""] autorelease];
	[res setAction:@selector(openPSPreference:)];
	[res setTarget:self];
	
	return res;
}

- (NSMenuItem *)previewMenuItemForLink:(id)link
{
	NSURL *url = [NSURL URLWithString:link];
	id res;
	res = [[[NSMenuItem alloc] initWithTitle:@"" action:Nil keyEquivalent:@""] autorelease];
	
	id submenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[res setSubmenu:submenu];
		
	id plugIns = [[self loadedPlugInsInfo] objectEnumerator];
	id dict;
	
	while(dict = [plugIns nextObject]) {
		id obj, name, isUse;
		id item;
		
		isUse = [dict objectForKey:keyPlugInIsUse];
		if(![isUse boolValue]) continue;
		
		obj = [dict objectForKey:keyPlugInObject];
		name = [dict objectForKey:keyPlugInDisplayName];
		
		item = [[[NSMenuItem alloc] initWithTitle:name
										   action:@selector(performLinkAction:)
									keyEquivalent:@""] autorelease];
		
		if([obj validateLink:url]) {
			[item setTarget:self];
			[item setRepresentedObject:
				[NSDictionary dictionaryWithObjectsAndKeys:obj, keyPlugInObject, url, keyActionLink, nil]];
		} else {
			[item setEnabled:NO];
		}
		
		[submenu addItem:item];
	}
	
	[submenu addItem:[NSMenuItem separatorItem]];
	[submenu addItem:[self preferenceMenuItem]];
	
	return res;
}


#pragma mark## Actions ##
- (void)performLinkAction:(id)sender
{
	if(![sender respondsToSelector:@selector(representedObject)]) return;
	
	id rep = [sender representedObject];
	if(![rep isKindOfClass:[NSDictionary class]]) return;
	
	id obj = [rep objectForKey:keyPlugInObject];
	id url = [rep objectForKey:keyActionLink];
	
	[obj showImageWithURL:url];
}
- (void)openPSPreference:(id)sender
{
	PSPreference *pref = [PSPreference sharedInstance];
	[pref setPlugInList:[self loadedPlugInsInfo]];
	[pref showWindow:self];
}


#pragma mark## Key Value Coding ##
- (NSString *)defaultPreviewerName
{
	id enums, obj;
	
	enums = [[self loadedPlugInsInfo] objectEnumerator];
	while(obj = [enums nextObject]) {
		id isDefault = [obj objectForKey:keyPlugInIsDefault];
		if([isDefault boolValue]) {
			return [obj objectForKey:keyPlugInName];
		}
	}
	
	return nil;
}
- (void)setDefaultPreviewerName:(NSString *)newName
{
	id enums, obj;
		
	enums = [[self loadedPlugInsInfo] objectEnumerator];
	while(obj = [enums nextObject]) {
		id name = [obj objectForKey:keyPlugInName];
		if([name isEqualToString:newName]) {
			defaultPreviewer = [obj objectForKey:keyPlugInObject];
			[obj setObject:[NSNumber numberWithBool:YES] forKey:keyPlugInIsDefault];
		} else if([[obj objectForKey:keyPlugInIsDefault] boolValue]) {
			// current default remove from default.
			[obj setObject:[NSNumber numberWithBool:NO] forKey:keyPlugInIsDefault];
		}
	}
	
	[self savePlugInsInfo];
}
- (void)setPreference:(id)pref forKey:(id)key
{
	[[[self preferences] imagePreviewerPrefsDict] setObject:pref forKey:key];
}
- (id)preferenceForKey:(id)key
{
	return [[[self preferences] imagePreviewerPrefsDict] objectForKey:key];
}

- (NSString *)plugInsDirectory
{
	NSString *path;
	
	path = [self preferenceForKey:keyPrefPlugInsDir];
	
	if(!path) {
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSString *appName = [[mainBundle infoDictionary] objectForKey:@"CFBundleExecutable"];
		
		OSErr err;
		FSRef ref;
		UInt8 pathChars[PATH_MAX];
		
		err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, YES, &ref);
		if( noErr != err) return nil;
		
		err = FSRefMakePath(&ref, pathChars, PATH_MAX);
		if(noErr != err) return nil;
		
		path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:(char *)pathChars
																		   length:strlen((char *)pathChars)];
		
		path = [path stringByAppendingPathComponent:appName];
		path = [path stringByAppendingPathComponent:@"PlugIns"];
	}
		
	
	return path;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	id name;
	static BOOL observing = NO;
	
	if([keyPath isEqualToString:keyPlugInIsDefault] && !observing) {
		id newValue = [change objectForKey:NSKeyValueChangeNewKey];
		if([newValue boolValue]) {
			observing = YES;
			name = [object objectForKey:keyPlugInName];
			[self setDefaultPreviewerName:name];
			observing = NO;
		}
	} else if([keyPath isEqualToString:keyPlugInIsUse]) {
		[self savePlugInsInfo];
	}
}

#pragma mark-
// Designated Initializer
- (id)initWithPreferences:(AppDefaults *)prefs
{
	self = [super init];
	[self release];
	
	id result = [[self class] sharedInstance];
	
	[result setPreferences:prefs];
	[result loadPlugIns];
	
	return result;
}
	// Accessor
- (AppDefaults *)preferences
{
	return preferences;
}
- (void)setPreferences:(AppDefaults *)aPreferences
{
	id temp = preferences;
	preferences = [aPreferences retain];
	[temp release];
	
	id info = [self preferenceForKey:keyPrefPlugInsInfo];
	if(info) {
		[self restorePlugInsInfo];
	}
}
	// Action
- (BOOL)showImageWithURL:(NSURL *)imageURL
{
	if([defaultPreviewer validateLink:imageURL]) {
		return [defaultPreviewer showImageWithURL:imageURL];
	}
	
	return NO;
}
- (BOOL)validateLink:(NSURL *)anURL
{
	return YES;
}

- (IBAction) togglePreviewPanel : (id) sender
{
	PSPreference *pref = [PSPreference sharedInstance];
	[pref setPlugInList:[self loadedPlugInsInfo]];
	[pref togglePreferencePanel:self];
}

- (BOOL)showImagesWithURLs:(NSArray *)urls
{
	if([defaultPreviewer respondsToSelector:_cmd]) {
		[defaultPreviewer showImagesWithURLs:urls];
	} else {
		NSBeep();
		return NO;
	}
	
	return YES;
}

- (IBAction)showPreviewerPreferences:(id)sender
{
	[self openPSPreference:sender];
}
@end
