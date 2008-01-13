//
//  PSPPreviewerTableView.m
//  PreviewerSelector
//
//  Created by Hori,Masaki on 07/11/24.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PSPPreviewerTableView.h"


@implementation PSPPreviewerTableView

- (void)rightMouseDown:(NSEvent *)event
{
	NSPoint mouse = [self convertPoint:[event locationInWindow] fromView:nil];
	
	int row = [self rowAtPoint:mouse];
	
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row]
	  byExtendingSelection:NO];
	
	[super rightMouseDown:event];
}
@end
