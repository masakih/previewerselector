//
//  PreviewerSelector.h
//  PreviewerSelector
//
//  Created by Hori,Masaki on 06/05/07.
//  Copyright 2006 masakih. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BSImagePreviewerInterface.h"
#import "BSPreviewPluginInterface.h"

@interface PreviewerSelector : NSObject <BSImagePreviewerProtocol, BSLinkPreviewing>
{
	AppDefaults *preferences;
	
	NSMutableArray *loadedPlugInsInfo;
	NSMutableDictionary *itemsDict;
	
//	id<BSImagePreviewerProtocol> defaultPreviewer;
}

+ (id)sharedInstance;

- (NSMenuItem *)previewMenuItemForLink:(id)link;

- (NSString *)plugInsDirectory;
// - (void)setPlugInsDirectory:(NSString *)path;

- (NSArray *)loadedPlugInsInfo;

- (void)savePlugInsInfo;
- (void)restorePlugInsInfo;

//- (NSString *)defaultPreviewerName;
//- (void)setDefaultPreviewerName:(NSString *)name;

- (id)preferenceForKey:(id)key;
- (void)setPreference:(id)pref forKey:(id)key;

@end

#define PSLocalizedString( str, comment ) \
NSLocalizedStringFromTableInBundle( (str), @"Localizable", [NSBundle bundleForClass:[PreviewerSelector class]], (comment) )
