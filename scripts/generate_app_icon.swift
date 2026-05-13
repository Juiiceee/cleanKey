#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let rootPath = CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath
let rootURL = URL(fileURLWithPath: rootPath)
let iconsetURL = rootURL.appendingPathComponent("Packaging/CleanKey.iconset", isDirectory: true)

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconSpecs: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for spec in iconSpecs {
    let image = makeIcon(size: spec.pixels)
    let outputURL = iconsetURL.appendingPathComponent(spec.name)
    try writePNG(image, to: outputURL)
}

func makeIcon(size: Int) -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerRow = size * 4
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Unable to create icon context")
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)

    drawBackground(in: context)
    drawKeycap(in: context)
    drawKeyboardLines(in: context)
    drawLock(in: context)
    drawSparkle(in: context)

    guard let image = context.makeImage() else {
        fatalError("Unable to render icon")
    }
    return image
}

func drawBackground(in context: CGContext) {
    let rect = CGRect(x: 42, y: 42, width: 940, height: 940)
    let path = CGPath(roundedRect: rect, cornerWidth: 220, cornerHeight: 220, transform: nil)

    context.saveGState()
    context.addPath(path)
    context.clip()

    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            CGColor(red: 0.04, green: 0.06, blue: 0.09, alpha: 1),
            CGColor(red: 0.09, green: 0.16, blue: 0.20, alpha: 1)
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 120, y: 940),
        end: CGPoint(x: 920, y: 80),
        options: []
    )
    context.restoreGState()

    context.addPath(path)
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
    context.setLineWidth(18)
    context.strokePath()
}

func drawKeycap(in context: CGContext) {
    let rect = CGRect(x: 148, y: 260, width: 728, height: 500)
    let path = CGPath(roundedRect: rect, cornerWidth: 120, cornerHeight: 120, transform: nil)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -22), blur: 38, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
    context.addPath(path)
    context.setFillColor(CGColor(red: 0.99, green: 0.78, blue: 0.18, alpha: 1))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(path)
    context.clip()
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            CGColor(red: 1.00, green: 0.88, blue: 0.28, alpha: 1),
            CGColor(red: 0.91, green: 0.55, blue: 0.06, alpha: 1)
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 260, y: 760),
        end: CGPoint(x: 760, y: 260),
        options: []
    )
    context.restoreGState()

    context.addPath(path)
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.72))
    context.setLineWidth(22)
    context.strokePath()
}

func drawKeyboardLines(in context: CGContext) {
    context.setFillColor(CGColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 0.28))

    let rows: [[CGRect]] = [
        [
            CGRect(x: 250, y: 610, width: 92, height: 46),
            CGRect(x: 372, y: 610, width: 92, height: 46),
            CGRect(x: 494, y: 610, width: 92, height: 46),
            CGRect(x: 616, y: 610, width: 92, height: 46)
        ],
        [
            CGRect(x: 220, y: 520, width: 92, height: 46),
            CGRect(x: 342, y: 520, width: 92, height: 46),
            CGRect(x: 464, y: 520, width: 92, height: 46),
            CGRect(x: 586, y: 520, width: 92, height: 46),
            CGRect(x: 708, y: 520, width: 62, height: 46)
        ],
        [
            CGRect(x: 292, y: 430, width: 440, height: 48)
        ]
    ]

    for row in rows {
        for rect in row {
            context.addPath(CGPath(roundedRect: rect, cornerWidth: 18, cornerHeight: 18, transform: nil))
            context.fillPath()
        }
    }
}

func drawLock(in context: CGContext) {
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -8), blur: 16, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.22))

    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.setLineWidth(34)
    context.setLineCap(.round)
    context.addArc(center: CGPoint(x: 512, y: 438), radius: 92, startAngle: .pi * 0.05, endAngle: .pi * 0.95, clockwise: false)
    context.strokePath()

    let body = CGRect(x: 390, y: 280, width: 244, height: 184)
    context.addPath(CGPath(roundedRect: body, cornerWidth: 42, cornerHeight: 42, transform: nil))
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fillPath()

    context.setFillColor(CGColor(red: 0.08, green: 0.11, blue: 0.13, alpha: 0.74))
    context.addEllipse(in: CGRect(x: 486, y: 350, width: 52, height: 52))
    context.fillPath()
    context.addPath(CGPath(roundedRect: CGRect(x: 498, y: 304, width: 28, height: 58), cornerWidth: 14, cornerHeight: 14, transform: nil))
    context.fillPath()

    context.restoreGState()
}

func drawSparkle(in context: CGContext) {
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.88))
    drawDiamond(center: CGPoint(x: 730, y: 780), radius: 38, in: context)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.72))
    drawDiamond(center: CGPoint(x: 790, y: 705), radius: 20, in: context)
}

func drawDiamond(center: CGPoint, radius: CGFloat, in context: CGContext) {
    context.beginPath()
    context.move(to: CGPoint(x: center.x, y: center.y + radius))
    context.addLine(to: CGPoint(x: center.x + radius * 0.32, y: center.y + radius * 0.32))
    context.addLine(to: CGPoint(x: center.x + radius, y: center.y))
    context.addLine(to: CGPoint(x: center.x + radius * 0.32, y: center.y - radius * 0.32))
    context.addLine(to: CGPoint(x: center.x, y: center.y - radius))
    context.addLine(to: CGPoint(x: center.x - radius * 0.32, y: center.y - radius * 0.32))
    context.addLine(to: CGPoint(x: center.x - radius, y: center.y))
    context.addLine(to: CGPoint(x: center.x - radius * 0.32, y: center.y + radius * 0.32))
    context.closePath()
    context.fillPath()
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        fatalError("Unable to create PNG destination")
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Unable to write PNG at \(url.path)")
    }
}
