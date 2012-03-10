//
//  BSPreviewPluginInterface.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/03/21.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

@class AppDefaults, CMRThreadViewer;

@protocol BSLinkPreviewing
// Designated Initializer
- (id)initWithPreferences:(AppDefaults *)prefs;

// Action
- (BOOL)previewLink:(NSURL *)url;
- (BOOL)validateLink:(NSURL *)url;

@optional
//- (BOOL)previewLink:(NSURL *)url atThread:(CMRThreadViewer *)threadViewer;
//- (BOOL)previewLink:(NSURL *)url atThread:(CMRThreadViewer *)threadViewer mouseLocation:(NSPoint)point linkBounds:(NSRect)bounds;
//- (BOOL)validateLink:(NSURL *)url atThread:(CMRThreadViewer *)threadViewer;
- (BOOL)previewLinks:(NSArray *)urls;
//- (BOOL)previewLinks:(NSArray *)urls atThread:(CMRThreadViewer *)threadViewer;
//- (BOOL)previewLinks:(NSArray *)urls atThread:(CMRThreadViewer *)threadViewer linksBounds:(NSRect)bounds;
- (IBAction)togglePreviewPanel:(id)sender;
- (IBAction)showPreviewerPreferences:(id)sender;
@end


@interface NSObject(BSPreviewPluginAdditions)
// Storage for plugin-specific settings
- (NSMutableDictionary *)previewerPrefsDict;

//  Accessor for useful BathyScaphe global settings
- (BOOL)openInBg;
- (BOOL)isOnlineMode;
- (NSString *)linkDownloaderDestination; // 「リンク先のファイルをダウンロード」時の「保存先」
@end
