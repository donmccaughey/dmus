# Localized Display Name

- The on-disk name really is `Media.localized`. The Finder computes a display
  name at runtime; this is a Finder/Foundation convention, not a filesystem
  feature.
- A folder named `Name.localized` may contain a hidden `.localized/`
  subdirectory with one `.strings` file per language (`en.strings`,
  `de.strings`, ...). Each file maps the base name to its translation, e.g.
  `"Release Notes" = "Localized name";`.
- The Finder strips the `.localized` suffix, looks up the base name in the
  best-matching `.strings` file, and shows the result. With no match, it still
  hides the suffix, which is why "Media" appears even in English.
- The standard home folders (`Documents`, `Music`, ...) use a variant: an empty
  `.localized` marker file inside the folder, with names drawn from the system's
  own localization tables.
- Spotlight applies the same logic when indexing and stores the result in
  `kMDItemDisplayName`, which is what `mdls` prints. `ls` has no knowledge of
  the convention and prints the raw name.
- Apps get the display name from system APIs rather than parsing `.strings`
  files:
  - `FileManager.displayName(atPath:)` and `componentsToDisplay(forPath:)`
    (Foundation)
  - `URL.resourceValues(forKeys: [.localizedNameKey])` (Foundation)
  - `MDItemCopyAttribute` with `kMDItemDisplayName` (Core Services)
  - `CFURLCopyResourcePropertyForKey` with `kCFURLLocalizedNameKey` (Core
    Foundation)
- Apps should keep the on-disk name for filesystem operations and use one of
  these APIs only for what they show the user.

Sources: Apple's "Localizing Folder Names" (Internationalization and
Localization Guide); [mac-localized on
PyPI](https://pypi.org/project/mac-localized/).
