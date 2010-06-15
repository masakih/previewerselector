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

#import "PSPreviewerItem.h"

#import "PSPreviewerInterface.h"

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

@implementation PreviewerSelector(MethodExchange)
- (NSMenuItem *)replacementCommandItemWithLink:(id)link command:(Class)class title:(NSString *)title
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
@end
static void psSwapMethod()
{
//	Class target = NSClassFromString(@"CMRThreadView");
	Class target = NSClassFromString(@"SGHTMLView");
	Method method;
	
    method = class_getInstanceMethod(target, @selector(commandItemWithLink:command:title:));
	orignalIMP = class_getMethodImplementation(target, @selector(commandItemWithLink:command:title:));
	if(method) {
//		orignalIMP = method->method_imp;
//		method->method_imp = (IMP)psCommandItemWithLink;
		
		Method newMethod = class_getInstanceMethod([PreviewerSelector class], @selector(replacementCommandItemWithLink:command:title:));
		
		method_exchangeImplementations(method, newMethod);
	}
}

#pragma mark-
#pragma mark## Class variables ##
static PreviewerSelector *sSharedInstance;

#pragma mark-
#pragma mark## NSDictionary Keys ##
//static NSString *keyPlugInPath = @"PlugInPathKey";
static NSString *keyPlugInObject = @"PlugInObjectKey";
//static NSString *keyPlugInName = @"PlugInNameKey";
//static NSString *keyPlugInDisplayName = @"PlugInDisplayNameKey";
//static NSString *keyPlugInVersion = @"PlugInVersionKey";
//static NSString *keyPlugInID = @"PlugInIDKey";
//static NSString *keyPlugInIsUse = @"PlugInIsUseKey";
//static NSString *keyPlugInIsDefault = @"PlugInIsDefaultKey";

static NSString *keyActionLink = @"ActionLinkKey";

#define AppIdentifierString @"com.masakih.previewerSelector"
static NSString *keyPrefPlugInsDir = AppIdentifierString @"." @"PlugInsDir";
static NSString *keyPrefPlugInsInfo2 = AppIdentifierString @"." @"PlugInsInfo2";

#pragma mark## NSString Literals ##
static NSString *builtInPreviewerName = @"BuiltIn";
static NSString *noarmalImagePreviewerName = @"ImagePreviewer";

@interface PreviewerSelector(PSPrivate)
- (void)loadPlugIns;
- (BOOL)openURL:(NSURL *)url withPreviewer:(id)previewer;
- (BOOL)openURLs:(NSArray *)url withPreviewer:(id)previewer;
@end

#pragma mark-
@implementation PreviewerSelector
NSString *resolveAlias(NSString *path)
{
	NSString *newPath = nil;
	
	FSRef	ref;
	char *newPathCString;
	Boolean isDir,  wasAliased;
	OSStatus err;
	
	err = FSPathMakeRef( (UInt8 *)[path fileSystemRepresentation], &ref, NULL );
	if( err == dirNFErr ) {
		NSString *lastPath = [path lastPathComponent];
		NSString *parent = [path stringByDeletingLastPathComponent];
		NSString *f;
		
		if( [@"/" isEqualTo:parent] ) return nil;
		
		parent = resolveAlias( parent );
		if( !parent ) return nil;
		
		f = [parent stringByAppendingPathComponent:lastPath];
		
		err = FSPathMakeRef( (UInt8 *)[f fileSystemRepresentation], &ref, NULL );
	}
	if( err != noErr ) {
		return nil;
	}
	
	err = FSResolveAliasFile( &ref, TRUE, &isDir, &wasAliased );
	if( err != noErr ) {
		return nil;
	}
	
	newPathCString = (char *)malloc( sizeof(unichar) * 1024 );
	if( !newPathCString ) {
		return nil;
	}
	
	err = FSRefMakePath( &ref, (UInt8 *)newPathCString, sizeof(unichar) * 1024 );
	if( err != noErr ) {
		goto final;
	}
	
	newPath = [NSString stringWithUTF8String:newPathCString];
	
final:
	free( (char *)newPathCString );
	
	return newPath;
}
+ (void)initialize
{
	psSwapMethod();
}

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

- (NSUInteger)retainCount
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

- (void)awakePreviewers
{
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	
	while(item = [itemsEnum nextObject]) {
		id previewer = [item previewer];
		if([previewer respondsToSelector:@selector(awakeByPreviewerSelector:)]) {
			[previewer performSelector:@selector(awakeByPreviewerSelector:) withObject:self];
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
	plugin = [[[pluginClass alloc] initWithPreferences:[self preferences]] autorelease];
	if(!plugin) return;
	
	item = [itemsDict objectForKey:[pluginBundle bundleIdentifier]];
	if(!item) {
		item = [[[PSPreviewerItem alloc] initWithIdentifier:[pluginBundle bundleIdentifier]] autorelease];
		[item setTryCheck:YES];
		[item setDisplayInMenu:YES];
		
		[loadedPlugInsInfo addObject:item];
		[itemsDict setObject:item forKey:[item identifier]];
	}
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
	
	// ???
//	[item addObserver:self
//		   forKeyPath:@"tryCheck"
//			  options:NSKeyValueObservingOptionNew
//			  context:NULL];
//	[item addObserver:self
//		   forKeyPath:@"displayInMenu"
//			  options:NSKeyValueObservingOptionNew
//			  context:NULL];
	
//	[loadedPlugInsInfo addObject:item];
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
	
//	if([[self loadedPlugInsInfo] count] == 0) {
		[self loadDefaultPreviewer];
//	}
		
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
	
	[self awakePreviewers];
}

- (NSArray *)loadedPlugInsInfo
{
	return loadedPlugInsInfo;
}

- (void)savePlugInsInfo
{
	NSData *itemsData = [NSKeyedArchiver archivedDataWithRootObject:loadedPlugInsInfo];
	
	[self setPreference:itemsData forKey:keyPrefPlugInsInfo2];
	
//	NSLog(@"Save information.");
}
- (void)restorePlugInsInfo
{
	[loadedPlugInsInfo autorelease];
	NSData *itemsData = [self preferenceForKey:keyPrefPlugInsInfo2];
	if(!itemsData) {
		loadedPlugInsInfo = [[NSMutableArray alloc] init];
	} else {
		loadedPlugInsInfo = [[NSKeyedUnarchiver unarchiveObjectWithData:itemsData] retain];
		if(!loadedPlugInsInfo) {
			loadedPlugInsInfo = [[NSMutableArray alloc] init];
		}
	}
	
	[itemsDict autorelease];
	itemsDict = [[NSMutableDictionary alloc] init];
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	while(item = [itemsEnum nextObject]) {
		[itemsDict setObject:item forKey:[item identifier]];
	}
	
	[self loadPlugIns];
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
	id item;
	
	while(item = [plugIns nextObject]) {
		id name;
		id menuItem;
		
		if(![item isDisplayInMenu]) continue;
		
		name = [item displayName];
		
		menuItem = [[[NSMenuItem alloc] initWithTitle:name
										   action:@selector(performLinkAction:)
									keyEquivalent:@""] autorelease];
		
		if([[item previewer] validateLink:url]) {
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:
				[NSDictionary dictionaryWithObjectsAndKeys:item, keyPlugInObject, url, keyActionLink, nil]];
		} else {
			[menuItem setEnabled:NO];
		}
		
		[submenu addItem:menuItem];
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
	
	id obj = [[rep objectForKey:keyPlugInObject] previewer];
	id url = [rep objectForKey:keyActionLink];
	
	[self openURL:url withPreviewer:obj];
}
- (void)openPSPreference:(id)sender
{
	PSPreference *pref = [PSPreference sharedInstance];
	[pref setPlugInList:[self loadedPlugInsInfo]];
	[pref showWindow:self];
}


#pragma mark## Key Value Coding ##
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
		NSString *appName = [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
		if(!appName) {
			appName = [[mainBundle infoDictionary] objectForKey:@"CFBundleExecutable"];
		}
		
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
	
	return resolveAlias(path);
}

//- (void)observeValueForKeyPath:(NSString *)keyPath
//					  ofObject:(id)object
//						change:(NSDictionary *)change
//					   context:(void *)context
//{
//	if([keyPath isEqualToString:@"tryCheck"]) {
//		[self savePlugInsInfo];
//	}
//	if([keyPath isEqualToString:@"displayInMenu"]) {
//		[self savePlugInsInfo];
//	}
//}

#pragma mark-
// Designated Initializer
- (id)initWithPreferences:(AppDefaults *)prefs
{
	self = [self init];
	
	[self setPreferences:prefs];
//	[self loadPlugIns];
	
	return self;
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
	
	id info = [self preferenceForKey:keyPrefPlugInsInfo2];
	if(info) {
		[self restorePlugInsInfo];
	}
}
	// Action
- (BOOL)showImageWithURL:(NSURL *)imageURL
{
	BOOL result = NO;
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	
	while(item = [itemsEnum nextObject]) {
		id previewer = [item previewer];
		if(![item isTryCheck]) continue;
		if([previewer validateLink:imageURL]) {
			result =  [self openURL:imageURL withPreviewer:previewer];
		}
		if(result) return YES;
	}
	
	return NO;
}
- (BOOL)previewLink:(NSURL *)url
{
	return [self showImageWithURL:url];
}
- (BOOL)validateLink:(NSURL *)anURL
{
	if([[anURL scheme] isEqualToString:@"cmonar"]) return NO;
	
	return YES;
}

- (IBAction) togglePreviewPanel : (id) sender
{
	PSPreference *pref = [PSPreference sharedInstance];
	[pref setPlugInList:[self loadedPlugInsInfo]];
	[pref togglePreferencePanel:self];
}
- (BOOL)previewLinks:(NSArray *)urls
{
	return [self showImagesWithURLs:urls];
}
- (BOOL)showImagesWithURLs:(NSArray *)urls
{
	BOOL result = NO;
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	
	while(item = [itemsEnum nextObject]) {
		result = [self openURLs:urls withPreviewer:[item previewer]];
		if(result) return YES;
	}
	
	return NO;
}

- (IBAction)showPreviewerPreferences:(id)sender
{
	[self openPSPreference:sender];
}
@end

@interface PreviewerSelector (PSPreviewerInterface) <PSPreviewerInterface>
@end

@implementation PreviewerSelector (PSPreviewerInterface)
static NSArray *previewerDisplayNames = nil;
static NSArray *previewerIdentifiers = nil;
static NSArray *previewers = nil;

- (void)buildArrays
{
	NSMutableArray *names = [NSMutableArray array];
	NSMutableArray *ids = [NSMutableArray array];
	
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	
	while(item = [itemsEnum nextObject]) {
		id name = [item displayName];
		[names addObject:name];
		
		id identifier = [item identifier];
		[ids addObject:identifier];
	}
	
	previewerDisplayNames = [[NSArray arrayWithArray:names] retain];
	previewerIdentifiers = [[NSArray arrayWithArray:ids] retain];
}
- (NSArray *)previewerDisplayNames
{
	if(previewerDisplayNames) return previewerDisplayNames;
	
	[self buildArrays];
	
	return previewerDisplayNames;
}
	
- (NSArray *)previewerIdentifires
{
	if(previewerIdentifiers) return previewerIdentifiers;
	
	[self buildArrays];
	
	return previewerIdentifiers;
}
- (BOOL)openURL:(NSURL *)url withPreviewer:(id)previewer
{
	if([previewer conformsToProtocol:@protocol(BSLinkPreviewing)]) {
		return [previewer previewLink:url];
	}
	
	return [previewer showImageWithURL:url];
}
- (BOOL)openURLs:(NSArray *)url withPreviewer:(id)previewer
{
	if([previewer respondsToSelector:@selector(previewLinks:)]) {
		return [previewer previewLinks:url];
	}
	if([previewer respondsToSelector:@selector(showImagesWithURLs:)]) {
		return [previewer showImagesWithURLs:url];
	}
	return NO;
}

- (BOOL)openURL:(NSURL *)url inPreviewerByName:(NSString *)previewerName
{
	BOOL result = NO;
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	
	while(item = [itemsEnum nextObject]) {
		NSString *displayName = [item displayName];
		
		if([displayName isEqualToString:previewerName]) {
			id previewer = [item previewer];
			if([previewer validateLink:url]) {
				result =  [self openURL:url withPreviewer:previewer];;
			}
			return result;
		}
	}
	
	return NO;
}
- (BOOL)openURL:(NSURL *)url inPreviewerByIdentifier:(NSString *)target
{
	BOOL result = NO;
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	
	while(item = [itemsEnum nextObject]) {
		NSString *identifier = [item identifier];
		
		if([identifier isEqualToString:target]) {
			id previewer = [item previewer];
			if([previewer validateLink:url]) {
				result =  [self openURL:url withPreviewer:previewer];;
			}
			return result;
		}
	}
	
	return NO;
}

- (NSArray *)previewerItems
{
	return [NSArray arrayWithArray:loadedPlugInsInfo];
}

// for direct controll previewers.
- (NSArray *)previewers
{
	if(previewers) return previewers;
	
	NSMutableArray *pvs = [NSMutableArray array];
	
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	
	while(item = [itemsEnum nextObject]) {
		id pv = [item previewer];
		[pvs addObject:pv];
	}
	
	previewers = [NSArray arrayWithArray:pvs];
	
	return previewers;
}
- (id <BSImagePreviewerProtocol>)previewerByName:(NSString *)previewerName
{
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	
	while(item = [itemsEnum nextObject]) {
		NSString *displayName = [item displayName];
		
		if([displayName isEqualToString:previewerName]) {
			return  [item previewer];
		}
	}
	
	return nil;
}
- (id <BSImagePreviewerProtocol>)previewerByIdentifier:(NSString *)previewerIdentifier
{
	id item, itemsEnum = [loadedPlugInsInfo objectEnumerator];
	
	while(item = [itemsEnum nextObject]) {
		NSString *identifier = [item identifier];
		
		if([identifier isEqualToString:previewerIdentifier]) {
			return  [item previewer];
		}
	}
	
	return nil;
}
@end

@implementation NSObject (PSPreviewerInterface)
+ (id <PSPreviewerInterface>)PSPreviewerSelector
{
	return [PreviewerSelector sharedInstance];
}
@end
