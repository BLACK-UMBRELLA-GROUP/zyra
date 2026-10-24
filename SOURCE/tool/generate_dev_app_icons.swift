// Rebuilds Current plus ten original app-icon comparison studies.
//
// Run from SOURCE with:
//   xcrun swift tool/generate_dev_app_icons.swift
//
// Gold Horizon at the current wordmark size is written to the primary AppIcon
// and assets/icon/icon.png. The locked lettering stencil is tinted to the
// Quiet Horizon splash's exact #E5CE8E gold without changing its geometry.
// Ten iOS alternates explore genuinely different compositions. Every icon is
// rebuilt from the same deterministic
// Midnight Plum background and the exact locked Syne stencil in
// splash_logo.png, so repeated generation cannot compound an earlier treatment
// or inherit a damaged base. Midnight Plum is the live app palette:
// Hulu-inspired #30203F top-left → #160E20 bottom-right (Founder 2026-09-27).

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let iconColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

let midnightPlumTop = CGColor(
  colorSpace: iconColorSpace,
  components: [0x30 / 255.0, 0x20 / 255.0, 0x3F / 255.0, 1]
)!
let midnightPlumBottom = CGColor(
  colorSpace: iconColorSpace,
  components: [0x16 / 255.0, 0x0E / 255.0, 0x20 / 255.0, 1]
)!
let splashWordmarkGold = CGColor(
  colorSpace: iconColorSpace,
  components: [0xE5 / 255.0, 0xCE / 255.0, 0x8E / 255.0, 1]
)!

enum Treatment {
  case goldHorizon
  case goldHalo, orbitLight, twinGlow, openFrame, editorialGold
  case risingDawn, quietMonogram, silkRibbon, constellation, royalSeal
}

struct Variant {
  let assetName: String
  let previewName: String
  let treatment: Treatment
}

struct IconSize {
  let filename: String
  let pixels: Int
}

let variants = [
  Variant(
    assetName: "AppIcon",
    previewName: "goldHorizonCurrent",
    treatment: .goldHorizon
  ),
  Variant(assetName: "ZyraGoldHalo", previewName: "goldHalo", treatment: .goldHalo),
  Variant(assetName: "ZyraOrbitLight", previewName: "orbitLight", treatment: .orbitLight),
  Variant(assetName: "ZyraTwinGlow", previewName: "twinGlow", treatment: .twinGlow),
  Variant(assetName: "ZyraOpenFrame", previewName: "openFrame", treatment: .openFrame),
  Variant(assetName: "ZyraEditorialGold", previewName: "editorialGold", treatment: .editorialGold),
  Variant(assetName: "ZyraRisingDawn", previewName: "risingDawn", treatment: .risingDawn),
  Variant(assetName: "ZyraQuietMonogram", previewName: "quietMonogram", treatment: .quietMonogram),
  Variant(assetName: "ZyraSilkRibbon", previewName: "silkRibbon", treatment: .silkRibbon),
  Variant(assetName: "ZyraConstellation", previewName: "constellation", treatment: .constellation),
  Variant(assetName: "ZyraRoyalSeal", previewName: "royalSeal", treatment: .royalSeal),
]

let iconSizes = [
  IconSize(filename: "Icon-App-20x20@1x.png", pixels: 20),
  IconSize(filename: "Icon-App-20x20@2x.png", pixels: 40),
  IconSize(filename: "Icon-App-20x20@3x.png", pixels: 60),
  IconSize(filename: "Icon-App-29x29@1x.png", pixels: 29),
  IconSize(filename: "Icon-App-29x29@2x.png", pixels: 58),
  IconSize(filename: "Icon-App-29x29@3x.png", pixels: 87),
  IconSize(filename: "Icon-App-40x40@1x.png", pixels: 40),
  IconSize(filename: "Icon-App-40x40@2x.png", pixels: 80),
  IconSize(filename: "Icon-App-40x40@3x.png", pixels: 120),
  IconSize(filename: "Icon-App-50x50@1x.png", pixels: 50),
  IconSize(filename: "Icon-App-50x50@2x.png", pixels: 100),
  IconSize(filename: "Icon-App-57x57@1x.png", pixels: 57),
  IconSize(filename: "Icon-App-57x57@2x.png", pixels: 114),
  IconSize(filename: "Icon-App-60x60@2x.png", pixels: 120),
  IconSize(filename: "Icon-App-60x60@3x.png", pixels: 180),
  IconSize(filename: "Icon-App-72x72@1x.png", pixels: 72),
  IconSize(filename: "Icon-App-72x72@2x.png", pixels: 144),
  IconSize(filename: "Icon-App-76x76@1x.png", pixels: 76),
  IconSize(filename: "Icon-App-76x76@2x.png", pixels: 152),
  IconSize(filename: "Icon-App-83.5x83.5@2x.png", pixels: 167),
  IconSize(filename: "Icon-App-1024x1024@1x.png", pixels: 1024),
]

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let primarySourceURL = root.appendingPathComponent("assets/icon/icon.png")
let wordmarkURL = root.appendingPathComponent("assets/splash/splash_logo.png")
let assetsURL = root.appendingPathComponent("ios/Runner/Assets.xcassets")
let previewsURL = root.appendingPathComponent("assets/icon/previews")

func loadImage(_ url: URL) throws -> CGImage {
  guard
    let source = CGImageSourceCreateWithURL(url as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
  else {
    throw NSError(
      domain: "ZYRAIconGenerator",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Could not read \(url.path)"]
    )
  }
  return image
}

func makeContext(size: Int) throws -> CGContext {
  guard
    let context = CGContext(
      data: nil,
      width: size,
      height: size,
      bitsPerComponent: 8,
      bytesPerRow: size * 4,
      space: iconColorSpace,
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )
  else {
    throw NSError(
      domain: "ZYRAIconGenerator",
      code: 2,
      userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap context"]
    )
  }
  context.interpolationQuality = .high
  return context
}

func tintWordmark(_ stencil: CGImage) throws -> CGImage {
  let bounds = CGRect(x: 0, y: 0, width: stencil.width, height: stencil.height)
  guard let context = CGContext(
    data: nil,
    width: stencil.width,
    height: stencil.height,
    bitsPerComponent: 8,
    bytesPerRow: stencil.width * 4,
    space: iconColorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  ) else {
    throw NSError(
      domain: "ZYRAIconGenerator",
      code: 8,
      userInfo: [NSLocalizedDescriptionKey: "Could not create wordmark tint context"]
    )
  }
  context.draw(stencil, in: bounds)
  context.setBlendMode(.sourceIn)
  context.setFillColor(splashWordmarkGold)
  context.fill(bounds)
  guard let tinted = context.makeImage() else {
    throw NSError(
      domain: "ZYRAIconGenerator",
      code: 9,
      userInfo: [NSLocalizedDescriptionKey: "Could not tint wordmark stencil"]
    )
  }
  return tinted
}

func writePNG(_ image: CGImage, to url: URL) throws {
  guard
    let destination = CGImageDestinationCreateWithURL(
      url as CFURL,
      UTType.png.identifier as CFString,
      1,
      nil
    )
  else {
    throw NSError(
      domain: "ZYRAIconGenerator",
      code: 3,
      userInfo: [NSLocalizedDescriptionKey: "Could not open \(url.path)"]
    )
  }
  CGImageDestinationAddImage(destination, image, nil)
  guard CGImageDestinationFinalize(destination) else {
    throw NSError(
      domain: "ZYRAIconGenerator",
      code: 4,
      userInfo: [NSLocalizedDescriptionKey: "Could not write \(url.path)"]
    )
  }
}

func goldGradient(alpha: CGFloat) -> CGGradient {
  CGGradient(
    colorsSpace: iconColorSpace,
    colors: [
      CGColor(red: 0.97, green: 0.87, blue: 0.58, alpha: alpha),
      CGColor(red: 0.88, green: 0.70, blue: 0.31, alpha: alpha * 0.5),
      CGColor(red: 0.88, green: 0.70, blue: 0.31, alpha: 0),
    ] as CFArray,
    locations: [0, 0.48, 1]
  )!
}

func drawBackground(in context: CGContext) {
  let background = CGGradient(
    colorsSpace: iconColorSpace,
    colors: [
      midnightPlumTop,
      midnightPlumBottom,
    ] as CFArray,
    locations: [0, 1]
  )!
  context.drawLinearGradient(
    background,
    start: CGPoint(x: 0, y: 1024),
    end: CGPoint(x: 1024, y: 0),
    options: []
  )
}

func drawGoldHorizon(in context: CGContext) {
  let lineRect = CGRect(x: 122, y: 282, width: 780, height: 4)
  context.saveGState()
  context.clip(to: lineRect)
  let lineGradient = CGGradient(
    colorsSpace: iconColorSpace,
    colors: [
      CGColor(red: 0.91, green: 0.77, blue: 0.40, alpha: 0),
      CGColor(red: 0.96, green: 0.86, blue: 0.57, alpha: 0.95),
      CGColor(red: 0.91, green: 0.77, blue: 0.40, alpha: 0),
    ] as CFArray,
    locations: [0, 0.5, 1]
  )!
  context.drawLinearGradient(
    lineGradient,
    start: CGPoint(x: lineRect.minX, y: lineRect.midY),
    end: CGPoint(x: lineRect.maxX, y: lineRect.midY),
    options: []
  )
  context.restoreGState()

  let dot = CGPoint(x: 286, y: 284)
  context.drawRadialGradient(
    goldGradient(alpha: 0.72),
    startCenter: dot,
    startRadius: 0,
    endCenter: dot,
    endRadius: 34,
    options: []
  )
  context.setFillColor(
    CGColor(red: 0.97, green: 0.87, blue: 0.58, alpha: 1)
  )
  context.fillEllipse(in: CGRect(x: dot.x - 8, y: dot.y - 8, width: 16, height: 16))
}


let studyGold = CGColor(red: 0.96, green: 0.85, blue: 0.55, alpha: 1)

func stroke(_ path: CGPath, in context: CGContext, width: CGFloat = 5, alpha: CGFloat = 0.85) {
  context.addPath(path)
  context.setStrokeColor(studyGold.copy(alpha: alpha)!)
  context.setLineWidth(width)
  context.setLineCap(.round)
  context.setLineJoin(.round)
  context.strokePath()
}

func glow(at point: CGPoint, radius: CGFloat, alpha: CGFloat, in context: CGContext) {
  context.drawRadialGradient(
    goldGradient(alpha: alpha),
    startCenter: point, startRadius: 0,
    endCenter: point, endRadius: radius, options: []
  )
}

func goldDot(at point: CGPoint, radius: CGFloat, in context: CGContext) {
  context.setFillColor(studyGold)
  context.fillEllipse(in: CGRect(x: point.x - radius, y: point.y - radius,
    width: radius * 2, height: radius * 2))
}

func drawStudyArt(_ treatment: Treatment, in context: CGContext) {
  // All study art stays inside an inset so corner pixels preserve the exact
  // shared dark-Hulu gradient. The operating system supplies icon corner masks.
  context.saveGState()
  context.clip(to: CGRect(x: 32, y: 32, width: 960, height: 960))
  switch treatment {
  case .goldHorizon:
    break
  case .goldHalo:
    glow(at: CGPoint(x: 512, y: 512), radius: 375, alpha: 0.16, in: context)
    stroke(CGPath(ellipseIn: CGRect(x: 170, y: 170, width: 684, height: 684),
      transform: nil), in: context, width: 7)
    goldDot(at: CGPoint(x: 748, y: 760), radius: 12, in: context)
  case .orbitLight:
    context.saveGState()
    context.translateBy(x: 512, y: 512)
    context.rotate(by: .pi / 7)
    stroke(CGPath(ellipseIn: CGRect(x: -365, y: -205, width: 730, height: 410),
      transform: nil), in: context, width: 6, alpha: 0.75)
    context.restoreGState()
    glow(at: CGPoint(x: 806, y: 695), radius: 95, alpha: 0.75, in: context)
    goldDot(at: CGPoint(x: 806, y: 695), radius: 15, in: context)
  case .twinGlow:
    glow(at: CGPoint(x: 280, y: 680), radius: 290, alpha: 0.48, in: context)
    glow(at: CGPoint(x: 750, y: 320), radius: 290, alpha: 0.38, in: context)
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 254, y: 292))
    path.addCurve(to: CGPoint(x: 774, y: 292), control1: CGPoint(x: 420, y: 390),
      control2: CGPoint(x: 604, y: 390))
    stroke(path, in: context, width: 5)
    goldDot(at: CGPoint(x: 254, y: 292), radius: 11, in: context)
    goldDot(at: CGPoint(x: 774, y: 292), radius: 11, in: context)
  case .openFrame:
    for (x, y, dx, dy) in [(180.0, 180.0, 1.0, 1.0), (844.0, 180.0, -1.0, 1.0),
      (180.0, 844.0, 1.0, -1.0), (844.0, 844.0, -1.0, -1.0)] {
      let path = CGMutablePath()
      path.move(to: CGPoint(x: x + dx * 112, y: y))
      path.addLine(to: CGPoint(x: x, y: y))
      path.addLine(to: CGPoint(x: x, y: y + dy * 112))
      stroke(path, in: context, width: 8)
    }
  case .editorialGold:
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 190, y: 285))
    path.addLine(to: CGPoint(x: 190, y: 710))
    stroke(path, in: context, width: 9)
    goldDot(at: CGPoint(x: 190, y: 764), radius: 14, in: context)
    let foot = CGMutablePath()
    foot.move(to: CGPoint(x: 252, y: 296))
    foot.addLine(to: CGPoint(x: 408, y: 296))
    stroke(foot, in: context, width: 4, alpha: 0.7)
  case .risingDawn:
    glow(at: CGPoint(x: 512, y: 360), radius: 325, alpha: 0.5, in: context)
    let sun = CGMutablePath()
    sun.addArc(center: CGPoint(x: 512, y: 285), radius: 135,
      startAngle: 0, endAngle: .pi, clockwise: false)
    stroke(sun, in: context, width: 9)
    let horizon = CGMutablePath()
    horizon.move(to: CGPoint(x: 166, y: 283))
    horizon.addLine(to: CGPoint(x: 858, y: 283))
    stroke(horizon, in: context, width: 4, alpha: 0.65)
  case .quietMonogram:
    goldDot(at: CGPoint(x: 762, y: 274), radius: 20, in: context)
    let dash = CGMutablePath()
    dash.move(to: CGPoint(x: 239, y: 262))
    dash.addLine(to: CGPoint(x: 401, y: 262))
    stroke(dash, in: context, width: 7)
  case .silkRibbon:
    let ribbon = CGMutablePath()
    ribbon.move(to: CGPoint(x: 142, y: 275))
    ribbon.addCurve(to: CGPoint(x: 860, y: 820), control1: CGPoint(x: 785, y: 202),
      control2: CGPoint(x: 233, y: 866))
    stroke(ribbon, in: context, width: 40, alpha: 0.14)
    stroke(ribbon, in: context, width: 7, alpha: 0.8)
    let companion = CGMutablePath()
    companion.move(to: CGPoint(x: 150, y: 211))
    companion.addCurve(to: CGPoint(x: 906, y: 768), control1: CGPoint(x: 823, y: 143),
      control2: CGPoint(x: 299, y: 806))
    stroke(companion, in: context, width: 3, alpha: 0.45)
  case .constellation:
    let points = [CGPoint(x: 320, y: 694), CGPoint(x: 512, y: 795),
      CGPoint(x: 712, y: 687)]
    let path = CGMutablePath()
    path.move(to: points[0]); path.addLine(to: points[1]); path.addLine(to: points[2])
    stroke(path, in: context, width: 4, alpha: 0.5)
    for (index, point) in points.enumerated() {
      glow(at: point, radius: 56, alpha: 0.35, in: context)
      let r: CGFloat = index == 1 ? 29 : 17
      let star = CGMutablePath()
      star.move(to: CGPoint(x: point.x, y: point.y + r))
      star.addLine(to: CGPoint(x: point.x + r * 0.3, y: point.y + r * 0.3))
      star.addLine(to: CGPoint(x: point.x + r, y: point.y))
      star.addLine(to: CGPoint(x: point.x + r * 0.3, y: point.y - r * 0.3))
      star.addLine(to: CGPoint(x: point.x, y: point.y - r))
      star.addLine(to: CGPoint(x: point.x - r * 0.3, y: point.y - r * 0.3))
      star.addLine(to: CGPoint(x: point.x - r, y: point.y))
      star.addLine(to: CGPoint(x: point.x - r * 0.3, y: point.y + r * 0.3))
      star.closeSubpath()
      context.addPath(star); context.setFillColor(studyGold); context.fillPath()
    }
  case .royalSeal:
    glow(at: CGPoint(x: 512, y: 512), radius: 345, alpha: 0.15, in: context)
    stroke(CGPath(ellipseIn: CGRect(x: 172, y: 172, width: 680, height: 680),
      transform: nil), in: context, width: 12)
    stroke(CGPath(ellipseIn: CGRect(x: 201, y: 201, width: 622, height: 622),
      transform: nil), in: context, width: 3, alpha: 0.45)
    for angle in [0.0, Double.pi / 2, Double.pi, Double.pi * 1.5] {
      goldDot(at: CGPoint(x: 512 + cos(angle) * 340, y: 512 + sin(angle) * 340),
        radius: 10, in: context)
    }
  }
  context.restoreGState()
}

func makeMaster(
  variant: Variant,
  wordmark: CGImage
) throws -> CGImage {
  let context = try makeContext(size: 1024)
  drawBackground(in: context)

  if variant.treatment == .goldHorizon {
    drawGoldHorizon(in: context)
  } else {
    drawStudyArt(variant.treatment, in: context)
  }

  switch variant.treatment {
  case .quietMonogram, .royalSeal:
    // Crop the existing locked Z glyph; never substitute a font approximation.
    let monogram = wordmark.cropping(to: CGRect(x: 17, y: 22, width: 133, height: 136))!
    let size: CGFloat = variant.treatment == .quietMonogram ? 415 : 330
    context.draw(monogram, in: CGRect(x: (1024 - size) / 2, y: (1024 - size) / 2,
      width: size, height: size))
  case .editorialGold:
    context.draw(wordmark, in: CGRect(x: 252, y: 425, width: 660, height: 165))
  case .risingDawn:
    context.draw(wordmark, in: CGRect(x: 152, y: 503, width: 720, height: 180))
  case .constellation:
    context.draw(wordmark, in: CGRect(x: 152, y: 347, width: 720, height: 180))
  case .goldHalo, .orbitLight, .twinGlow, .openFrame, .silkRibbon:
    context.draw(wordmark, in: CGRect(x: 192, y: 432, width: 640, height: 160))
  case .goldHorizon:
    // Retain Current's approved size and placement; only the tint changes.
    context.draw(wordmark, in: CGRect(x: 112, y: 412, width: 800, height: 200))
  }

  guard let image = context.makeImage() else {
    throw NSError(
      domain: "ZYRAIconGenerator",
      code: 5,
      userInfo: [NSLocalizedDescriptionKey: "Could not render \(variant.assetName)"]
    )
  }
  return image
}

func resize(_ image: CGImage, to pixels: Int) throws -> CGImage {
  if pixels == image.width && pixels == image.height { return image }
  let context = try makeContext(size: pixels)
  context.draw(
    image,
    in: CGRect(x: 0, y: 0, width: CGFloat(pixels), height: CGFloat(pixels))
  )
  guard let resized = context.makeImage() else {
    throw NSError(
      domain: "ZYRAIconGenerator",
      code: 6,
      userInfo: [NSLocalizedDescriptionKey: "Could not resize app icon"]
    )
  }
  return resized
}

func drawCaption(_ text: String, at point: CGPoint, in context: CGContext) {
  let string = NSAttributedString(string: text, attributes: [
    NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, 22, nil),
    NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(red: 0.92, green: 0.88, blue: 0.95, alpha: 1),
  ])
  context.textPosition = point
  CTLineDraw(CTLineCreateWithAttributedString(string), context)
}

func writeContactSheet(_ masters: [CGImage]) throws {
  // Inspection-only candidate, never an approved screenshot baseline.
  let size = 1536
  let context = try makeContext(size: size)
  context.setFillColor(midnightPlumBottom)
  context.fill(CGRect(x: 0, y: 0, width: size, height: size))
  let labels = ["Current", "1 · Gold Halo", "2 · Orbit Light", "3 · Together",
    "4 · Open Frame", "5 · Editorial Gold", "6 · Rising Dawn", "7 · Quiet Monogram",
    "8 · Silk Ribbon", "9 · Constellation", "10 · Royal Seal"]
  for (index, master) in masters.enumerated() {
    let x = CGFloat(48 + (index % 4) * 374)
    let y = CGFloat(1080 - (index / 4) * 448)
    let rect = CGRect(x: x, y: y, width: 318, height: 318)
    context.saveGState()
    context.addPath(CGPath(roundedRect: rect, cornerWidth: 64, cornerHeight: 64, transform: nil))
    context.clip()
    context.draw(master, in: rect)
    context.restoreGState()
    drawCaption(labels[index], at: CGPoint(x: x, y: y - 40), in: context)
  }
  let directory = root.appendingPathComponent("test/visual/candidates/app_icons_2026_09_27")
  try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
  try writePNG(context.makeImage()!, to: directory.appendingPathComponent("contact_sheet.png"))
}

do {
  let logo = try loadImage(wordmarkURL)
  guard
    let wordmark = logo.cropping(
      to: CGRect(x: 350, y: 140, width: 720, height: 180)
    )
  else {
    throw NSError(
      domain: "ZYRAIconGenerator",
      code: 7,
      userInfo: [NSLocalizedDescriptionKey: "Could not crop source assets"]
    )
  }
  let tintedWordmark = try tintWordmark(wordmark)
  let contentsTemplate = try Data(
    contentsOf: assetsURL.appendingPathComponent(
      "ZyraGoldHorizonLarge.appiconset/Contents.json"
    )
  )

  try fileManager.createDirectory(at: previewsURL, withIntermediateDirectories: true)
  var masters: [CGImage] = []
  for variant in variants {
    let master = try makeMaster(variant: variant, wordmark: tintedWordmark)
    masters.append(master)
    try writePNG(master, to: previewsURL.appendingPathComponent("\(variant.previewName).png"))
    let destination = assetsURL.appendingPathComponent(
      "\(variant.assetName).appiconset"
    )
    try fileManager.createDirectory(
      at: destination,
      withIntermediateDirectories: true
    )
    if variant.assetName != "AppIcon" {
      try contentsTemplate.write(
        to: destination.appendingPathComponent("Contents.json"),
        options: .atomic
      )
    }
    for iconSize in iconSizes {
      let icon = try resize(master, to: iconSize.pixels)
      try writePNG(icon, to: destination.appendingPathComponent(iconSize.filename))
    }
    if variant.assetName == "AppIcon" {
      try writePNG(master, to: primarySourceURL)
    }
  }
  try writeContactSheet(masters)
  print("Generated \(variants.count) ZYRA app-icon sets/previews (Current + ten new studies).")
} catch {
  fputs("ZYRA app-icon generation failed: \(error)\n", stderr)
  exit(1)
}
