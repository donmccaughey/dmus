// Prints the orientation of a `simctl io screenshot` PNG: "portrait",
// "landscape-left", "landscape-right" (the orientations Simulator's Rotate
// Left and Rotate Right reach from portrait), or "unknown".
//
// simctl always writes the framebuffer in the device's physical portrait
// dimensions with the app's content drawn rotated, so the image size says
// nothing about the orientation. The home indicator does: it is a short
// uniform bar hugging the UI's bottom edge, which is the image's bottom edge
// in portrait, its left edge after Rotate Left and its right edge after
// Rotate Right.
import CoreGraphics
import Foundation
import ImageIO

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: screen-orientation PATH.png\n".utf8))
    exit(2)
}
let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
else {
    FileHandle.standardError.write(Data("cannot read \(url.path)\n".utf8))
    exit(2)
}

let width = image.width
let height = image.height
var pixels = [UInt8](repeating: 0, count: width * height * 4)
let context = CGContext(
    data: &pixels, width: width, height: height, bitsPerComponent: 8,
    bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

func luminance(x: Int, y: Int) -> Double {
    let i = (y * width + x) * 4
    return (0.299 * Double(pixels[i]) + 0.587 * Double(pixels[i + 1]) + 0.114 * Double(pixels[i + 2])) / 255
}

// The bar is about a third of the short side long and black, white in dark
// mode, or grey while dimmed. It shades itself segment by segment from what
// is under it, so right after a launch or a rotation it can be a gradient
// rather than one flat shade. Text and separators never make a run that
// long that is all darker or all lighter than the background 60 pixels
// inward, and the median of that background ignores a separator or a line
// of text crossing it.
let edgeDepth = 60
let halfRun = min(width, height) / 8
let inward = 60

func median(_ values: [Double]) -> Double {
    values.sorted()[values.count / 2]
}

func isBar(_ run: [Double], background: [Double]) -> Bool {
    let background = median(background)
    return run.allSatisfy { background - $0 > 0.3 } || run.allSatisfy { $0 - background > 0.3 }
}

func barAlongBottom() -> Bool {
    let xs = (width / 2 - halfRun)...(width / 2 + halfRun)
    for y in (height - edgeDepth)..<height {
        let run = xs.map { luminance(x: $0, y: y) }
        if isBar(run, background: xs.map { luminance(x: $0, y: y - inward) }) { return true }
    }
    return false
}

func barAlongSide(xRange: Range<Int>, inwardSign: Int) -> Bool {
    let ys = (height / 2 - halfRun)...(height / 2 + halfRun)
    for x in xRange {
        let run = ys.map { luminance(x: x, y: $0) }
        if isBar(run, background: ys.map { luminance(x: x + inwardSign * inward, y: $0) }) { return true }
    }
    return false
}

if barAlongBottom() {
    print("portrait")
} else if barAlongSide(xRange: 0..<edgeDepth, inwardSign: 1) {
    print("landscape-left")
} else if barAlongSide(xRange: (width - edgeDepth)..<width, inwardSign: -1) {
    print("landscape-right")
} else {
    print("unknown")
}
