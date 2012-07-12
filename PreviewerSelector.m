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
#import "PSPreviewerItems.h"

#pragma mark## Static Variable ##
static IMP orignalIMP;

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
		Method newMethod = class_getInstanceMethod([PreviewerSelector class], @selector(replacementCommandItemWithLink:command:title:));
		method_exchangeImplementations(method, newMethod);
	}
}

#pragma mark-
#pragma mark## Class variables ##
static PreviewerSelector *sSharedInstance;

#pragma mark-
#pragma mark## NSDictionary Keys ##
static NSString *keyPlugInObject = @"PlugInObjectKey";
static NSString *keyActionLink = @"ActionLinkKey";

#define AppIdentifierString @"com.masakih.previewerSelector"
static NSString *keyPrefPlugInsDir = AppIdentifierString @"." @"PlugInsDir";
static NSString *keyPrefPlugInsInfo2 = AppIdentifierString @"." @"PlugInsInfo2";

@interface PreviewerSelector(PSPrivate)
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

+ (PreviewerSelector *)sharedInstance
{
	if (sSharedInstance == nil) {
		sSharedInstance = [[super allocWithZone:NULL] init];
	}
	return sSharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self sharedInstance] retain];
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


- (NSArray *)loadedPlugInsInfo
{
	return [items previewerItems];
}

- (void)savePlugInsInfo
{
	NSData *itemsData = [NSKeyedArchiver archivedDataWithRootObject:[self loadedPlugInsInfo]];
	
	[self setPreference:itemsData forKey:keyPrefPlugInsInfo2];
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
	
	for(PSPreviewerItem *item in [self loadedPlugInsInfo]) {
		if(!item.isDisplayInMenu) continue;
		
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:item.displayName
														   action:@selector(performLinkAction:)
													keyEquivalent:@""] autorelease];
		
		if([item.previewer validateLink:url]) {
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
	PSPreference *pref = [PSPreference sharedPreference];
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

#pragma mark-
// Designated Initializer
- (id)initWithPreferences:(AppDefaults *)prefs
{
	self = [self init];
	
	items = [[PSPreviewerItems alloc] init];
	
	[self setPreferences:prefs];
	
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
	
	[items setPreference:preferences];
}
	// Action
- (BOOL)showImageWithURL:(NSURL *)imageURL
{
	BOOL result = NO;
	
	for(PSPreviewerItem *item in [self loadedPlugInsInfo]) {
		if(!item.isTryCheck) continue;
		
		id previewer = item.previewer;
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
	PSPreference *pref = [PSPreference sharedPreference];
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
	
	for(PSPreviewerItem *item in [self loadedPlugInsInfo]) {
		result = [self openURLs:urls withPreviewer:item.previewer];
		if(result) return YES;
	}
	
	return NO;
}

- (IBAction)showPreviewerPreferences:(id)sender
{
	[self openPSPreference:sender];
}
@end
