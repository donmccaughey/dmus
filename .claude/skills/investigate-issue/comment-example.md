# Example investigation comment

This is the tone and shape to aim for: plain prose with backticked identifiers,
exact strings quoted, and steps specific enough for someone else to rerun. Adapt
the sections to the issue; do not pad a section that has nothing to say.

---

Confirmed in code.

Environment: macOS 15.7, Xcode 26.3, commit `d3e4e0c` (clean tree).

The music directory on this machine contains `Media.localized` and
`Previous Libraries.localized`, which the Finder shows as "Media" and
"Previous Libraries". Checked with:

1. `ls ~/Music` lists `Media.localized` and `Previous Libraries.localized`.
2. `mdls -name kMDItemDisplayName ~/Music/Media.localized` reports `"Media"`.

The folder name comes from `url.lastPathComponent` in
`MusicLibrary.loadChildren(of:folderName:parentFolderName:)`
(`dmus/MusicLibrary.swift:120`), which keeps the full Unix name. Nothing in the
walk consults the display name, so every `.localized` directory shows its
extension in the Files panel.

Did not launch the app for this one; the on-disk names and the code path are
enough to account for the report. The Finder uses
`URLResourceValues.localizedName` for these names, which would be the
matching source for the folder name.
