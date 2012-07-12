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

@synthesize identifier;
@synthesize previewer;
@synthesize displayName, path, version;
@synthesize tryCheck, displayInMenu;

+ (void)initialize
{
	static BOOL isFirst = YES;
	if(isFirst) {
		@synchronized(self) {
			if(isFirst) {
				isFirst = NO;
				
				previewerInfo = [[NSMutableDictionary alloc] init];
//				NSLog(@"Initialize.");
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

- (void)dealloc
{
	self.previewer = nil;
	self.displayName = nil;
	self.path = nil;
	self.version = nil;
	
	[identifier release];
	
	[super dealloc];
}

- (void)setPreviewer:(id)newPreviewer
{
	if(previewer == newPreviewer) return;
	
	[previewer autorelease];
	
	if(!newPreviewer) return;
	
	previewer = [newPreviewer retain];
	[previewerInfo setObject:previewer forKey:identifier];
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
	PSPreviewerItem *result = [[[self class] allocWithZone:zone] initWithIdentifier:identifier];
	result.previewer = previewer;
	result.displayName = displayName;
	result.version = version;
	result.path = path;
	result.tryCheck = tryCheck;
	result.displayInMenu = displayInMenu;
	
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
	self.displayName = [aDecoder decodeObjectForKey:PSIDisplayNameKey];
	self.path = [aDecoder decodeObjectForKey:PSIPathKey];
	self.version = [aDecoder decodeObjectForKey:PSIVersionKey];
	self.tryCheck = [aDecoder decodeBoolForKey:PSPITryCheckKey];
	self.displayInMenu = [aDecoder decodeBoolForKey:PSPIDisplayInMenuKey];
	
	id p = [previewerInfo objectForKey:identifier];
	if(p) self.previewer = p;
	
	return self;
}

@end
