#!/usr/bin/env swift

import AppKit
import Foundation

enum Palette {
    static let paperLight = NSColor(srgbRed: 0.976, green: 0.972, blue: 0.957, alpha: 1.0)
    static let paperMid = NSColor(srgbRed: 0.949, green: 0.941, blue: 0.918, alpha: 1.0)
    static let paperDark = NSColor(srgbRed: 0.894, green: 0.882, blue: 0.851, alpha: 1.0)
    static let ink = NSColor(srgbRed: 0.055, green: 0.055, blue: 0.051, alpha: 1.0)
    static let inkSoft = NSColor(srgbRed: 0.145, green: 0.145, blue: 0.133, alpha: 1.0)
    static let orange = NSColor(srgbRed: 1.0, green: 0.31, blue: 0.0, alpha: 1.0)
}

let iconFiles: [(filename: String, pixels: Int)] = [
    ("appicon_16x16.png", 16),
    ("appicon_16x16@2x.png", 32),
    ("appicon_32x32.png", 32),
    ("appicon_32x32@2x.png", 64),
    ("appicon_128x128.png", 128),
    ("appicon_128x128@2x.png", 256),
    ("appicon_256x256.png", 256),
    ("appicon_256x256@2x.png", 512),
    ("appicon_512x512.png", 512),
    ("appicon_512x512@2x.png", 1024)
]

let outputPath: String = {
    if CommandLine.arguments.count > 1 {
        return CommandLine.arguments[1]
    }

    return FileManager.default.currentDirectoryPath
        + "/Vox/Vox/Vox/Assets.xcassets/AppIcon.appiconset"
}()

let outputDirectory = URL(fileURLWithPath: outputPath, isDirectory: true)

func renderIcon(side: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: side,
        pixelsHigh: side,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    rep.size = NSSize(width: side, height: side)

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    context.imageInterpolation = .high
    NSGraphicsContext.current = context

    drawIcon(in: NSRect(x: 0, y: 0, width: side, height: side))

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func drawIcon(in bounds: NSRect) {
    let size = min(bounds.width, bounds.height)
    let canvas = NSRect(origin: bounds.origin, size: NSSize(width: size, height: size))
    let inset = size * 0.055
    let cornerRadius = size * 0.23
    let shellRect = canvas.insetBy(dx: inset, dy: inset)
    let shellPath = NSBezierPath(roundedRect: shellRect, xRadius: cornerRadius, yRadius: cornerRadius)

    NSColor.clear.setFill()
    canvas.fill()

    let shellShadow = NSShadow()
    shellShadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shellShadow.shadowBlurRadius = size * 0.045
    shellShadow.shadowOffset = NSSize(width: 0, height: -size * 0.018)
    shellShadow.set()

    let paperGradient = NSGradient(colorsAndLocations:
        (Palette.paperLight, 0.0),
        (Palette.paperMid, 0.52),
        (Palette.paperDark, 1.0)
    )!
    paperGradient.draw(in: shellPath, angle: 90)

    NSGraphicsContext.saveGraphicsState()
    shellPath.addClip()

    let warmGlow = NSGradient(colorsAndLocations:
        (Palette.orange.withAlphaComponent(0.11), 0.0),
        (Palette.orange.withAlphaComponent(0.03), 0.35),
        (.clear, 1.0)
    )!
    warmGlow.draw(
        from: NSPoint(x: shellRect.minX + size * 0.08, y: shellRect.minY + size * 0.14),
        to: NSPoint(x: shellRect.maxX - size * 0.10, y: shellRect.maxY - size * 0.02),
        options: []
    )

    let topHighlight = NSGradient(colorsAndLocations:
        (NSColor.white.withAlphaComponent(0.34), 0.0),
        (.clear, 1.0)
    )!
    topHighlight.draw(
        from: NSPoint(x: shellRect.midX, y: shellRect.maxY),
        to: NSPoint(x: shellRect.midX, y: shellRect.midY),
        options: []
    )

    let panelPath = NSBezierPath()
    panelPath.move(to: NSPoint(x: shellRect.minX, y: shellRect.minY + size * 0.20))
    panelPath.line(to: NSPoint(x: shellRect.minX + size * 0.21, y: shellRect.minY))
    panelPath.line(to: NSPoint(x: shellRect.minX, y: shellRect.minY))
    panelPath.close()
    NSColor.white.withAlphaComponent(0.72).setFill()
    panelPath.fill()

    let bandPath = NSBezierPath()
    bandPath.move(to: NSPoint(x: shellRect.minX, y: shellRect.minY + size * 0.12))
    bandPath.line(to: NSPoint(x: shellRect.minX + size * 0.34, y: shellRect.minY))
    bandPath.line(to: NSPoint(x: shellRect.minX + size * 0.52, y: shellRect.minY))
    bandPath.line(to: NSPoint(x: shellRect.minX + size * 0.18, y: shellRect.minY + size * 0.34))
    bandPath.close()
    Palette.orange.withAlphaComponent(0.08).setFill()
    bandPath.fill()

    NSGraphicsContext.restoreGraphicsState()

    let borderPath = NSBezierPath(roundedRect: shellRect, xRadius: cornerRadius, yRadius: cornerRadius)
    borderPath.lineWidth = max(1.0, size * 0.006)
    Palette.ink.withAlphaComponent(0.12).setStroke()
    borderPath.stroke()

    let ringRect = NSRect(
        x: shellRect.minX + size * 0.16,
        y: shellRect.minY + size * 0.18,
        width: size * 0.41,
        height: size * 0.41
    )

    let ringShadow = NSShadow()
    ringShadow.shadowColor = Palette.ink.withAlphaComponent(0.12)
    ringShadow.shadowBlurRadius = size * 0.02
    ringShadow.shadowOffset = NSSize(width: 0, height: -size * 0.006)
    ringShadow.set()

    let ringGlow = NSBezierPath(ovalIn: ringRect.insetBy(dx: -size * 0.045, dy: -size * 0.045))
    Palette.orange.withAlphaComponent(0.05).setFill()
    ringGlow.fill()

    let ringPath = NSBezierPath(ovalIn: ringRect)
    ringPath.lineWidth = size * 0.034
    Palette.ink.setStroke()
    ringPath.stroke()

    let dotRect = NSRect(
        x: ringRect.midX - size * 0.085,
        y: ringRect.midY - size * 0.085,
        width: size * 0.17,
        height: size * 0.17
    )
    let dotPath = NSBezierPath(ovalIn: dotRect)
    Palette.orange.setFill()
    dotPath.fill()

    let cursorRect = NSRect(
        x: shellRect.minX + size * 0.66,
        y: shellRect.minY + size * 0.23,
        width: size * 0.064,
        height: size * 0.34
    )
    let cursorPath = NSBezierPath(
        roundedRect: cursorRect,
        xRadius: size * 0.02,
        yRadius: size * 0.02
    )
    Palette.orange.setFill()
    cursorPath.fill()

    let dividerRect = NSRect(
        x: shellRect.minX + size * 0.63,
        y: shellRect.minY + size * 0.64,
        width: size * 0.18,
        height: max(2.0, size * 0.012)
    )
    let dividerPath = NSBezierPath(
        roundedRect: dividerRect,
        xRadius: dividerRect.height / 2,
        yRadius: dividerRect.height / 2
    )
    Palette.inkSoft.setFill()
    dividerPath.fill()

    let accentRect = NSRect(
        x: shellRect.minX + size * 0.18,
        y: shellRect.minY + size * 0.67,
        width: size * 0.10,
        height: max(3.0, size * 0.014)
    )
    let accentPath = NSBezierPath(
        roundedRect: accentRect,
        xRadius: accentRect.height / 2,
        yRadius: accentRect.height / 2
    )
    Palette.orange.setFill()
    accentPath.fill()
}

func writeIcon(_ rep: NSBitmapImageRep, to url: URL) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "VoxIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG data."])
    }

    try data.write(to: url, options: .atomic)
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for icon in iconFiles {
    let rep = renderIcon(side: icon.pixels)
    try writeIcon(rep, to: outputDirectory.appendingPathComponent(icon.filename))
}

print("Generated \(iconFiles.count) icon files in \(outputDirectory.path)")
