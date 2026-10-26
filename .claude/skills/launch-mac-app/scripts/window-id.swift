import CoreGraphics

// Prints the first normal-layer on-screen window owned by the given PID.
// System Events needs an Accessibility grant and blocks on the prompt when
// run unattended; CGWindowList needs no permission.
let pid = Int32(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
for window in list
where (window["kCGWindowOwnerPID"] as? Int32) == pid && (window["kCGWindowLayer"] as? Int) == 0 {
    print(window["kCGWindowNumber"] as! Int)
    break
}
