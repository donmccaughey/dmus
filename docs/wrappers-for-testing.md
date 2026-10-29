# Wrappers for testing

Code that uses subsystems like the filesystem or network is difficult and slow
to test. This can also be true for code that uses complex libraries. Some
subsystems like the clock and the random number generator have global state that
is impractical or impossible to change in tests.

Make code more cohesive, less coupled and more testable by wrapping these
dependencies in high level interfaces.

For normal execution, these wrappers have the "real" implementation that call
the wrapped dependency. For testing, these wrappers have fake, mock or stub
implementations. Real and fake implementations should share the same base name,
adding a suffix like `Real` or `Fake`, so that these files naturally group
together.

For example, here is a `FileSystem` interface and the `FileSystemReal`
implementation:

    nonisolated protocol FileSystem: Sendable {
        func createDirectory(at url: URL) throws
    }
    
    nonisolated struct FileSystemReal: FileSystem {
        func createDirectory(at url: URL) throws {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

Wrapper interfaces should provide methods and properties with high level names
that describe their purpose in the application domain rather than simply
mirroring the low level, often general purpose, name being wrapped.

Real implementations of wrapper methods and properties should keep their
internal logic as minimal and close to direct delegation as practical. Some
duplication in wrapper methods and properties is reasonable where it aids
readability at the use site.

For example, the wrapper below provides `getMusicDirectoryURL()` and
`getMoviesDirectoryURL()` which make the same underlying method call to
`FileManager`.

    nonisolated protocol FileSystem: Sendable {
        func getMusicDirectoryURL() throws -> URL
        func getMoviesDirectoryURL() throws -> URL
    }

    nonisolated struct FileSystemReal: FileSystem {
        func getMusicDirectoryURL() throws -> URL {
            try FileManager.default.url(
                for: .musicDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
        
        func getMoviesDirectoryURL() throws -> URL {
            try FileManager.default.url(
                for: .moviesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
    }
