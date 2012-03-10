//
//  PSPreviewerInterface.m
//  PreviewerSelector
//
//  Created by Hori,Masaki on 10/09/13.
//  Copyright 2010 masakih. All rights reserved.
//

#import "PSPreviewerInterface.h"
#import "PreviewerSelector.h"
#import "PSPreviewerItem.h"

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
	
	for(PSPreviewerItem *item in [self loadedPlugInsInfo]) {
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
	
	for(PSPreviewerItem *item in [self loadedPlugInsInfo]) {
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
	
	for(PSPreviewerItem *item in [self loadedPlugInsInfo]) {
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
	return [NSArray arrayWithArray:[self loadedPlugInsInfo]];
}

// for direct controll previewers.
- (NSArray *)previewers
{
	if(previewers) return previewers;
	
	NSMutableArray *pvs = [NSMutableArray array];
	
	for(PSPreviewerItem *item in [self loadedPlugInsInfo]) {
		id pv = [item previewer];
		[pvs addObject:pv];
	}
	
	previewers = [NSArray arrayWithArray:pvs];
	
	return previewers;
}
- (id <BSImagePreviewerProtocol>)previewerByName:(NSString *)previewerName
{
	for(PSPreviewerItem *item in [self loadedPlugInsInfo]) {
		NSString *displayName = [item displayName];
		
		if([displayName isEqualToString:previewerName]) {
			return  [item previewer];
		}
	}
	
	return nil;
}
- (id <BSImagePreviewerProtocol>)previewerByIdentifier:(NSString *)previewerIdentifier
{
	for(PSPreviewerItem *item in [self loadedPlugInsInfo]) {
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
