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

@synthesize identifier = _identifier;
@synthesize previewer = _previewer;
@synthesize displayName = _displayName, path = _path, version = _version;
@synthesize tryCheck = _tryCheck, displayInMenu = _displayInMenu;

+ (void)initialize
{
	static BOOL isFirst = YES;
	if(isFirst) {
		isFirst = NO;
		
		previewerInfo = [[NSMutableDictionary alloc] init];
	}
}

- (id)initWithIdentifier:(NSString *)inIdentifier
{
	if(self = [super init]) {
		_identifier = [inIdentifier copy];
	}
	
	return self;
}

- (void)dealloc
{
	[_previewer release];
	[_displayName release];
	[_path release];
	[_version release];
	
	[_identifier release];
	
	[super dealloc];
}

- (void)setPreviewer:(id)newPreviewer
{
	if(_previewer == newPreviewer) return;
	
	[_previewer autorelease];
	
	if(!newPreviewer) return;
	
	_previewer = [newPreviewer retain];
	[previewerInfo setObject:_previewer forKey:_identifier];
}

- (NSString *)copyright
{
	NSBundle *bundle = [NSBundle bundleForClass:[self.previewer class]];
	NSDictionary *info = [bundle localizedInfoDictionary];
	return [info objectForKey:@"NSHumanReadableCopyright"];
}
- (BOOL)hasPreviewPanel
{
	return [self.previewer respondsToSelector:@selector(togglePreviewPanel:)];
}
- (BOOL)hasPreferencePanel
{
	return [self.previewer respondsToSelector:@selector(showPreviewerPreferences:)];
}


- (BOOL)isEqual:(id)object
{
	if(self == object) return YES;
	if(![object isMemberOfClass:[self class]]) return NO;
	
	return [self.identifier isEqualToString:[object identifier]];
}
- (NSUInteger)hash
{
	return [self.identifier hash];
}

- (id)description
{
	return [NSString stringWithFormat:@"%@ <%p> identifier = %@",
			NSStringFromClass([self class]), self, self.identifier];
}

- (id)copyWithZone:(NSZone *)zone
{
	PSPreviewerItem *result = [[[self class] allocWithZone:zone] initWithIdentifier:_identifier];
	result.previewer = _previewer;
	result.displayName = _displayName;
	result.version = _version;
	result.path = _path;
	result.tryCheck = _tryCheck;
	result.displayInMenu = _displayInMenu;
	
	return result;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_identifier forKey:PSPIIdentifierKey];
	[aCoder encodeObject:_displayName forKey:PSIDisplayNameKey];
	[aCoder encodeObject:_path forKey:PSIPathKey];
	[aCoder encodeObject:_version forKey:PSIVersionKey];
	[aCoder encodeBool:_tryCheck forKey:PSPITryCheckKey];
	[aCoder encodeBool:_displayInMenu forKey:PSPIDisplayInMenuKey];
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
	[self initWithIdentifier:[aDecoder decodeObjectForKey:PSPIIdentifierKey]];
	self.displayName = [aDecoder decodeObjectForKey:PSIDisplayNameKey];
	self.path = [aDecoder decodeObjectForKey:PSIPathKey];
	self.version = [aDecoder decodeObjectForKey:PSIVersionKey];
	self.tryCheck = [aDecoder decodeBoolForKey:PSPITryCheckKey];
	self.displayInMenu = [aDecoder decodeBoolForKey:PSPIDisplayInMenuKey];
	
	self.previewer = [previewerInfo objectForKey:_identifier];
	
	return self;
}

@end
