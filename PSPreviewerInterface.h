//
//  PSPreviewerInterface.h
//  PreviewerSelector
//
//  Created by Hori,Masaki on 09/03/10.
//  Copyright 2009 masakih. All rights reserved.
//

#import <Foundation/NSObject.h>
#import "BSImagePreviewerInterface.h"

@class PSPreviewerItem;
@class PreviewerSelector;

@protocol PSPreviewerInterface <NSObject>

- (NSArray *)previewerDisplayNames;
- (NSArray *)previewerIdentifires;

// ##### C A U T I O N !! #####
// YOU DO NOT CALL THESE METHODS WITH YOUR NAME OR IDENTIFIER.
// IT MAY FALL INTO AN INFINITE LOOP.
- (BOOL)openURL:(NSURL *)url inPreviewerByName:(NSString *)previewerName;
- (BOOL)openURL:(NSURL *)url inPreviewerByIdentifier:(NSString *)identifier;

- (NSArray *)previewerItems;	// array of PSPreviewerItem instances.

// for direct controll previewers.
- (NSArray *)previewers;
- (id <BSImagePreviewerProtocol>)previewerByName:(NSString *)name;
- (id <BSImagePreviewerProtocol>)previewerByIdentifier:(NSString *)identifier;
@end


@interface NSObject (PSPreviewerInterface)
+ (id <PSPreviewerInterface>)PSPreviewerSelector;
@end

@interface NSObject (PreviewerOptionalMethod)
// this method called, if previewer load by PreviewerSelector.
// all property is ready.
- (void)awakeByPreviewerSelector:(id <PSPreviewerInterface>)previewerSelector;
@end
