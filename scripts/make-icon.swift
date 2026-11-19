import AppKit

// Generate native icon sizes at build time; no third-party assets or tools.
let destination = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let canvas = NSSize(width: pixels, height: pixels)
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB,
                                      bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = canvas
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let context = NSGraphicsContext.current!.cgContext
        context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
        let background = NSBezierPath(roundedRect: NSRect(x: 72, y: 72, width: 880, height: 880), xRadius: 196, yRadius: 196)
        NSGradient(starting: NSColor(calibratedRed: 0.39, green: 0.40, blue: 0.70, alpha: 1),
                   ending: NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.35, alpha: 1))!
            .draw(in: background, angle: -90)
        let disk = NSBezierPath(ovalIn: NSRect(x: 230, y: 230, width: 564, height: 564))
        NSColor(calibratedRed: 0.88, green: 0.89, blue: 1, alpha: 1).setFill()
        disk.fill()
        context.saveGState()
        disk.addClip()
        NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.26, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 230, y: 230, width: 282, height: 564)).fill()
        context.restoreGState()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        try bitmap.representation(using: .png, properties: [:])!
            .write(to: destination.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
