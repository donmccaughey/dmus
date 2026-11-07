#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>

#import "FolderChild.h"

NS_ASSUME_NONNULL_BEGIN

extern NSPasteboardType const FolderChildPasteboardType NS_SWIFT_NAME(folderChild);

@interface FolderChildPasteboard : NSObject

+ (NSPasteboardItem *)pasteboardItemForChild:(id<FolderChild>)child NS_SWIFT_NAME(pasteboardItem(for:));
+ (nullable id<FolderChild>)childInItem:(NSPasteboardItem *)item NS_SWIFT_NAME(child(in:));
+ (NSArray<id<FolderChild>> *)childrenInPasteboard:(NSPasteboard *)pasteboard NS_SWIFT_NAME(children(in:));

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
#endif
