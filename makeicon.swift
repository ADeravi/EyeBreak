import AppKit

let S = 1024
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: S, pixelsHigh: S,
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("bitmap rep failed") }

let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx

// Rounded-rect gradient background (teal -> blue)
let full = NSRect(x: 0, y: 0, width: S, height: S)
let bg = NSBezierPath(roundedRect: full, xRadius: 220, yRadius: 220)
NSGradient(colors: [
    NSColor(calibratedRed: 0.16, green: 0.78, blue: 0.72, alpha: 1),
    NSColor(calibratedRed: 0.10, green: 0.42, blue: 0.88, alpha: 1)
])!.draw(in: bg, angle: -90)

// White eye symbol
let symSize: CGFloat = 540
var sym = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)!
sym = sym.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: symSize, weight: .medium))!
sym.isTemplate = false

let target = NSRect(x: (CGFloat(S) - symSize) / 2, y: (CGFloat(S) - symSize) / 2, width: symSize, height: symSize)
sym.draw(in: target)
NSColor.white.set()
target.fill(using: .sourceAtop)

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png export failed") }
try! png.write(to: URL(fileURLWithPath: "icon_1024.png"))
print("wrote icon_1024.png")
