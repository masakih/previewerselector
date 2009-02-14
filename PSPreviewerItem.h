//
//  PSPreviewerItem.h
//  PreviewerSelector
//
//  Created by Hori,Masaki on 09/02/14.
//  Copyright 2009 masakih. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PSPreviewerItem : NSObject <NSCopying, NSCoding>
{
	id previewer;	// コピーしない。 codingしない。
	NSString *identifier;
	NSString *displayName;
	NSString *path;
	NSString *version;
	BOOL tryCheck;
	BOOL displayInMenu;
}

- (id)initWithIdentifier:(NSString *)identifier;

- (NSString *)identifier;

- (id)previewer;
- (void)setPreviewer:(id)previewer;
- (NSString *)displayName;
- (void)setDisplayName:(NSString *)displayName;
- (NSString *)path;
- (void)setPath:(NSString *)path;
- (NSString *)version;
- (void)setVersion:(NSString *)version;
- (BOOL)isTryCheck;
- (void)setTryCheck:(BOOL)flag;
- (BOOL)isDisplayInMenu;
- (void)setDisplayInMenu:(BOOL)flag;


@end
