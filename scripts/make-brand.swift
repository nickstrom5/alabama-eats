// Alabama Eats brand (final: Nick's decisions, 2026-11-07): the app icon is concept C of
// scripts/icon-concepts.swift, a smoked chicken leg with a drizzle of Alabama white sauce, on sand; the shared Eats Ranked icon style,
// state-prompts/ICON-STYLE.md, no backing shape. No school colours or marks, no flag saltire, no seal.
// Usage, from al-eats/: swift scripts/make-brand.swift   -> AlabamaEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png,
// docs/ favicons and touch icons, docs/og.png. scripts/make-site.py draws the same mark as its inline SVG: change both together.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let TEAL: UInt32 = 0x1F5F6B, CRIMSON: UInt32 = 0xB0202E, SAND: UInt32 = 0xF7F1E3, GOLD: UInt32 = 0xE8B04A
let SKIN: UInt32 = 0x9C4F22, BONE: UInt32 = 0xE9D6B2, SAUCE: UInt32 = 0xFFFFFF

func P(_ s: CGFloat, _ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

/// C: the white-sauce chicken leg. CoreGraphics y-up, s = canvas size. Identical to icon-concepts.swift's concept C.
func chicken(_ c: CGContext, _ s: CGFloat) {
    c.setFillColor(rgb(BONE))
    c.fill(CGRect(x: 0.60 * s, y: 0.445 * s, width: 0.17 * s, height: 0.09 * s))
    c.fillEllipse(in: CGRect(x: 0.735 * s, y: 0.505 * s, width: 0.12 * s, height: 0.12 * s))
    c.fillEllipse(in: CGRect(x: 0.735 * s, y: 0.355 * s, width: 0.12 * s, height: 0.12 * s))
    let leg = CGMutablePath()
    leg.move(to: P(s, 0.15, 0.49))
    leg.addCurve(to: P(s, 0.42, 0.70), control1: P(s, 0.15, 0.63), control2: P(s, 0.28, 0.71))
    leg.addCurve(to: P(s, 0.66, 0.53), control1: P(s, 0.55, 0.69), control2: P(s, 0.60, 0.58))
    leg.addLine(to: P(s, 0.66, 0.45))
    leg.addCurve(to: P(s, 0.42, 0.29), control1: P(s, 0.60, 0.40), control2: P(s, 0.55, 0.30))
    leg.addCurve(to: P(s, 0.15, 0.49), control1: P(s, 0.28, 0.28), control2: P(s, 0.15, 0.36))
    leg.closeSubpath()
    c.setFillColor(rgb(SKIN)); c.addPath(leg); c.fillPath()
    let w = CGMutablePath()
    w.move(to: P(s, 0.24, 0.52))
    for i in 0..<5 {
        let x = 0.24 + CGFloat(i) * 0.074
        w.addQuadCurve(to: P(s, x + 0.074, 0.52), control: P(s, x + 0.037, i % 2 == 0 ? 0.575 : 0.465))
    }
    c.setStrokeColor(rgb(SAUCE)); c.setLineWidth(0.035 * s); c.setLineCap(.round); c.setLineJoin(.round)
    c.addPath(w); c.strokePath()
}

func render(_ n: Int, _ path: String, background: Bool) {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: background ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setShouldAntialias(true)
    if background { ctx.setFillColor(rgb(SAND)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n)) }
    chicken(ctx, CGFloat(n))
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
render(1024, "AlabamaEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png", background: true)
try? FileManager.default.createDirectory(atPath: "docs", withIntermediateDirectories: true)
for (n, name) in [(512, "icon-512.png"), (192, "icon-192.png"), (180, "apple-touch-icon.png"), (32, "favicon-32.png")] {
    render(n, "docs/" + name, background: true)
}

/// The share image (1200 x 630): sand, the chicken at the left, the name in Gulf teal and the tagline in crimson at the right, and the
/// app's camellia band (Theme.swift's Stripes) along the bottom.
func og(_ path: String) {
    let W = 1200, H = 630
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setShouldAntialias(true)
    ctx.setFillColor(rgb(SAND)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    // the camellia band: a teal line with crimson camellias and gold centres
    let line: CGFloat = 46, r: CGFloat = 20
    ctx.setFillColor(rgb(TEAL)); ctx.fill(CGRect(x: 0, y: line - 3, width: CGFloat(W), height: 6))
    let n = Int(CGFloat(W) / (r * 4.2))
    for i in 0..<n {
        let cx = (CGFloat(i) + 0.5) * CGFloat(W) / CGFloat(n)
        ctx.setFillColor(rgb(CRIMSON))
        for k in 0..<5 {
            let a = CGFloat(k) * 2 * .pi / 5 + .pi / 2
            let px = cx + cos(a) * r * 0.52, py = line + sin(a) * r * 0.52
            ctx.fillEllipse(in: CGRect(x: px - r * 0.52, y: py - r * 0.52, width: r * 1.04, height: r * 1.04))
        }
        ctx.setFillColor(rgb(GOLD)); ctx.fillEllipse(in: CGRect(x: cx - r * 0.3, y: line - r * 0.3, width: r * 0.6, height: r * 0.6))
    }
    ctx.saveGState(); ctx.translateBy(x: 20, y: 90); chicken(ctx, 520); ctx.restoreGState()
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ns
    let title = NSFont(name: "AvenirNextCondensed-Heavy", size: 96) ?? NSFont.boldSystemFont(ofSize: 84)
    let sub = NSFont(name: "AvenirNextCondensed-DemiBold", size: 32) ?? NSFont.boldSystemFont(ofSize: 28)
    let teal = NSColor(srgbRed: 0x1F / 255, green: 0x5F / 255, blue: 0x6B / 255, alpha: 1)
    let crimson = NSColor(srgbRed: 0xB0 / 255, green: 0x20 / 255, blue: 0x2E / 255, alpha: 1)
    NSAttributedString(string: "ALABAMA", attributes: [.font: title, .foregroundColor: teal]).draw(at: NSPoint(x: 560, y: 380))
    NSAttributedString(string: "EATS", attributes: [.font: title, .foregroundColor: teal]).draw(at: NSPoint(x: 560, y: 282))
    NSAttributedString(string: "WHITE SAUCE, MEAT-AND-THREES", attributes: [.font: sub, .foregroundColor: crimson]).draw(at: NSPoint(x: 564, y: 232))
    NSAttributedString(string: "& GULF OYSTERS", attributes: [.font: sub, .foregroundColor: crimson]).draw(at: NSPoint(x: 564, y: 192))
    NSGraphicsContext.restoreGraphicsState()
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
og("docs/og.png")
