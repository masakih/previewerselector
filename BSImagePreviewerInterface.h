//
//  BSImagePreviewerInterface.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/10/15, Last Modified on 07/10/24.
//  Copyright 2005-2007 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

@class AppDefaults;

@protocol BSImagePreviewerProtocol
// Designated Initializer
- (id)initWithPreferences:(AppDefaults *)prefs;
// Accessor
- (AppDefaults *)preferences;
- (void)setPreferences:(AppDefaults *)aPreferences;
// Action
- (BOOL)showImageWithURL:(NSURL *)imageURL;
- (BOOL)validateLink:(NSURL *)anURL;
@end

@interface NSObject(BSImagePreviewerInformalProtocol)
// MeteorSweeper Addition - optional method information
// このメソッドはプロトコル定義には含まれませんが、BathyScaphe 1.3 以降でプラグインの Principal class に
// このメソッドを実装しておくと、BathyScaphe の「ウインドウ」＞「プレビュー」メニュー項目が有効になります。
// BathyScaphe は「ウインドウ」＞「プレビュー」が選択されると、プラグインに対してこのメソッドを実行するようメッセージを送信します。
- (IBAction)togglePreviewPanel:(id)sender;

// Available in BathyScaphe 1.6 and later.
- (BOOL)showImagesWithURLs:(NSArray *)urls;
- (IBAction)showPreviewerPreferences:(id)sender;
@end

@interface NSObject(IPPAdditions)
// Storage for plugin-specific settings
- (NSMutableDictionary *)imagePreviewerPrefsDict;

//  Accessor for useful BathyScaphe global settings
- (BOOL)openInBg;
- (BOOL)isOnlineMode;
@end
