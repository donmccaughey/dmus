#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_SENDABLE
@protocol Preferences <NSObject>

- (nullable NSData *)getMusicRootDirectoryBookmark;
- (void)setMusicRootDirectoryBookmark:(NSData *)bookmark;

@end

NS_ASSUME_NONNULL_END
