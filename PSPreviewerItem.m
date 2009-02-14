//
//  PSPreviewerItem.m
//  PreviewerSelector
//
//  Created by Hori,Masaki on 09/02/14.
//  Copyright 2009 masakih. All rights reserved.
//

#import "PSPreviewerItem.h"


static NSString *const PSPIIdentifierKey = @"PSPIIdentifierKey";
static NSString *const PSIDisplayNameKey = @"PSIDisplayNameKey";
static NSString *const PSIPathKey = @"PSIPathKey";
static NSString *const PSIVersionKey = @"PSIVersionKey";
static NSString *const PSPITryCheckKey = @"PSPITryCheckKey";
static NSString *const PSPIDisplayInMenuKey = @"PSPIDisplayInMenuKey";

static NSMutableDictionary *previewerInfo = nil;

@implementation PSPreviewerItem

+ (void)initialize
{
	static BOOL isFirst = YES;
	if(isFirst) {
		@synchronized(self) {
			if(isFirst) {
				isFirst = NO;
				
				previewerInfo = [[NSMutableDictionary alloc] init];
				NSLog(@"Initialize.");
			}
		}
	}
}

- (id)initWithIdentifier:(NSString *)inIdentifier
{
	if(self = [super init]) {
		identifier = [inIdentifier copy];
	}
	
	return self;
}

- (NSString *)identifier
{
	return identifier;
}

- (id)previewer
{
	return previewer;
}
- (void)setPreviewer:(id)newPreviewer
{
	if(previewer == newPreviewer) return;
	
	[previewer autorelease];
	previewer = [newPreviewer retain];
	
	[previewerInfo setObject:previewer forKey:identifier];
}
- (NSString *)displayName
{
	return displayName;
}
- (void)setDisplayName:(NSString *)newDisplayName
{
	if(displayName == newDisplayName) return;
	
	[displayName autorelease];
	displayName = [newDisplayName copy];
}
- (NSString *)path
{
	return path;
}
- (void)setPath:(NSString *)newPath
{
	if(path == newPath) return;
	
	[path autorelease];
	path = [newPath copy];
}
- (NSString *)version
{
	return version;
}
- (void)setVersion:(NSString *)newVersion
{
	if(version == newVersion) return;
	
	[version autorelease];
	version = [newVersion copy];
}
- (BOOL)isTryCheck
{
	return tryCheck;
}
- (void)setTryCheck:(BOOL)flag
{
	tryCheck = flag;
}
- (BOOL)isDisplayInMenu
{
	return displayInMenu;
}
- (void)setDisplayInMenu:(BOOL)flag
{
	displayInMenu = flag;
}

- (id)copyWithZone:(NSZone *)zone
{
	PSPreviewerItem *result = [[[self class] allocWithZone:zone] initWithIdentifier:identifier];
	[result setPreviewer:previewer];
	[result setDisplayName:displayName];
	[result setVersion:version];
	[result setPath:path];
	[result setTryCheck:tryCheck];
	[result setDisplayInMenu:displayInMenu];
	
	return result;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:identifier forKey:PSPIIdentifierKey];
	[aCoder encodeObject:displayName forKey:PSIDisplayNameKey];
	[aCoder encodeObject:path forKey:PSIPathKey];
	[aCoder encodeObject:version forKey:PSIVersionKey];
	[aCoder encodeBool:tryCheck forKey:PSPITryCheckKey];
	[aCoder encodeBool:displayInMenu forKey:PSPIDisplayInMenuKey];
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
	[self initWithIdentifier:[aDecoder decodeObjectForKey:PSPIIdentifierKey]];
	[self setDisplayName:[aDecoder decodeObjectForKey:PSIDisplayNameKey]];
	[self setPath:[aDecoder decodeObjectForKey:PSIPathKey]];
	[self setVersion:[aDecoder decodeObjectForKey:PSIVersionKey]];
	[self setTryCheck:[aDecoder decodeBoolForKey:PSPITryCheckKey]];
	[self setDisplayInMenu:[aDecoder decodeBoolForKey:PSPIDisplayInMenuKey]];
	
	id p = [previewerInfo objectForKey:identifier];
	if(p) [self setPreviewer:p];
	
	return self;
}

@end