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

@class PSPreviewerItems;

@interface PreviewerSelector : NSObject <BSImagePreviewerProtocol, BSLinkPreviewing>
{
	AppDefaults *preferences;
	PSPreviewerItems *items;
}

+ (id)sharedInstance;

- (NSMenuItem *)previewMenuItemForLink:(id)link;

- (NSString *)plugInsDirectory;

- (NSArray *)loadedPlugInsInfo;

- (void)savePlugInsInfo;
//- (void)restorePlugInsInfo;

- (id)preferenceForKey:(id)key;
- (void)setPreference:(id)pref forKey:(id)key;

@end

#define PSLocalizedString( str, comment ) \
NSLocalizedStringFromTableInBundle( (str), @"Localizable", [NSBundle bundleForClass:[PreviewerSelector class]], (comment) )
