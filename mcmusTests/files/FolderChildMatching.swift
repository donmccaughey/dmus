import Foundation
import Model

// FolderChild is a protocol, so child arrays compare element by element
// through isEqual.
func childrenEqual(_ actual: [FolderChild], _ expected: [FolderChild]) -> Bool {
    actual.count == expected.count && zip(actual, expected).allSatisfy { $0.isEqual($1) }
}
