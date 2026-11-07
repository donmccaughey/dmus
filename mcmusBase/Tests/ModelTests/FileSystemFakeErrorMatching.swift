import Foundation
import WrappersTestSupport

// Errors are matched by domain, code and user info rather than by type, which
// is all an Objective-C thrower can offer.
func fileSystemFakeErrorPath(of error: any Error) -> String? {
    let error = error as NSError
    guard error.domain == FileSystemFakeErrorDomain,
          error.code == FileSystemFakeErrorCode.operationFailed.rawValue
    else { return nil }
    return error.userInfo[NSFilePathErrorKey] as? String
}

func fileSystemFakeErrorPaths(in errors: [any Error]) -> [String] {
    errors.compactMap(fileSystemFakeErrorPath)
}
