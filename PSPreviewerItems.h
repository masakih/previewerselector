//
//  PSPreviewerItems.h
//  PreviewerSelector
//
//  Created by Hori,Masaki on 10/09/12.
//  Copyright 2010 masakih. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PSPreviewerItem.h"


@interface PSPreviewerItems : NSObject
{
	NSMutableArray *previewerItems;
}

- (void)setPreference:(id)pref;

@property (nonatomic, readonly) NSArray *previewerItems;
@end
