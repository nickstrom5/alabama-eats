// Alabama Eats icon concepts (2026-11-06), drawn in the shared Eats Ranked style (state-prompts/ICON-STYLE.md): one flat, level,
// centred food on a plain background in the state palette (Gulf teal #1F5F6B, flag crimson #B0202E, sand #F7F1E3, yellowhammer gold
// #E8B04A), no backing shape, no text or texture; no school colours or marks (no crimson-and-white elephant, no orange-and-blue
// tiger), no flag saltire. Food hexes: shell #F2EADB, shell cup #D7C9AF, oyster #B5A482, mantle #6F624C; cake #F7EBD0, frosting
// #FFFFFF, frosting front #EFE5D3; smoked chicken #9C4F22, bone #E9D6B2, white sauce #FFFFFF.
//   A  a Gulf oyster on the half shell, from above, on Gulf teal
//   B  a slice of Lane cake (the state cake since 2016): white layers and the yellow bourbon-pecan filling, frosted, on crimson
//   C  a smoked chicken leg with a drizzle of Alabama white sauce (Decatur, 1925), on sand
// Usage, from al-eats/: swift scripts/icon-concepts.swift <out dir>   -> concept-{a,b,c}-1024.png
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let TEAL: UInt32 = 0x1F5F6B, CRIMSON: UInt32 = 0xB0202E, SAND: UInt32 = 0xF7F1E3, GOLD: UInt32 = 0xE8B04A
let SHELL: UInt32 = 0xF2EADB, CUP: UInt32 = 0xD7C9AF, OYSTER: UInt32 = 0xB5A482, MANTLE: UInt32 = 0x6F624C
let CAKE: UInt32 = 0xF7EBD0, FROST: UInt32 = 0xFFFFFF, FROSTFRONT: UInt32 = 0xEFE5D3
let SKIN: UInt32 = 0x9C4F22, BONE: UInt32 = 0xE9D6B2, SAUCE: UInt32 = 0xFFFFFF

func P(_ s: CGFloat, _ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

/// The half shell: a rounded teardrop, the hinge to the left. Scaled about (cx, cy) by k.
func shellPath(_ s: CGFloat, k: CGFloat = 1, cx: CGFloat = 0.50, cy: CGFloat = 0.49) -> CGPath {
    func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { P(s, cx + (x - cx) * k, cy + (y - cy) * k) }
    let p = CGMutablePath()
    p.move(to: q(0.14, 0.50))
    p.addCurve(to: q(0.60, 0.74), control1: q(0.17, 0.67), control2: q(0.38, 0.76))
    p.addCurve(to: q(0.86, 0.49), control1: q(0.78, 0.73), control2: q(0.86, 0.63))
    p.addCurve(to: q(0.60, 0.25), control1: q(0.86, 0.35), control2: q(0.77, 0.25))
    p.addCurve(to: q(0.14, 0.50), control1: q(0.39, 0.24), control2: q(0.17, 0.34))
    p.closeSubpath()
    return p
}

/// A: the oyster on the half shell. CoreGraphics y-up, s = canvas size.
func oyster(_ c: CGContext, _ s: CGFloat) {
    c.setFillColor(rgb(SHELL)); c.addPath(shellPath(s)); c.fillPath()
    c.setFillColor(rgb(CUP)); c.addPath(shellPath(s, k: 0.84, cx: 0.53)); c.fillPath()
    let meat = CGRect(x: 0.35 * s, y: 0.355 * s, width: 0.40 * s, height: 0.27 * s)
    c.setFillColor(rgb(OYSTER)); c.fillEllipse(in: meat)
    // the dark mantle frill: one 36 px ring just inside the meat's edge
    c.setStrokeColor(rgb(MANTLE)); c.setLineWidth(0.035 * s)
    c.strokeEllipse(in: meat.insetBy(dx: 0.0175 * s, dy: 0.0175 * s))
}

/// B: a slice of Lane cake, front elevation with one lighter top plane (cabinet style, as Wisconsin's wedge).
func laneCake(_ c: CGContext, _ s: CGFloat) {
    let x0: CGFloat = 0.175, x1: CGFloat = 0.855, y0: CGFloat = 0.28, y1: CGFloat = 0.62, dx: CGFloat = -0.03, dy: CGFloat = 0.085
    // the frosted top plane, lightest (facing up)
    let top = CGMutablePath()
    top.move(to: P(s, x0, y1)); top.addLine(to: P(s, x1, y1)); top.addLine(to: P(s, x1 + dx, y1 + dy)); top.addLine(to: P(s, x0 + dx, y1 + dy))
    top.closeSubpath()
    c.setFillColor(rgb(FROST)); c.addPath(top); c.fillPath()
    // the front: three cake layers, two filling layers, the frosting's front edge on top
    c.setFillColor(rgb(CAKE)); c.fill(CGRect(x: x0 * s, y: y0 * s, width: (x1 - x0) * s, height: (y1 - y0) * s))
    c.setFillColor(rgb(GOLD))
    for fy in [0.37, 0.48] { c.fill(CGRect(x: x0 * s, y: CGFloat(fy) * s, width: (x1 - x0) * s, height: 0.04 * s)) }
    c.setFillColor(rgb(FROSTFRONT)); c.fill(CGRect(x: x0 * s, y: (y1 - 0.045) * s, width: (x1 - x0) * s, height: 0.045 * s))
}

/// C: a smoked chicken leg with a white-sauce drizzle, side elevation, the bone to the right.
func chicken(_ c: CGContext, _ s: CGFloat) {
    c.setFillColor(rgb(BONE))
    c.fill(CGRect(x: 0.60 * s, y: 0.445 * s, width: 0.17 * s, height: 0.09 * s))                       // the bone
    c.fillEllipse(in: CGRect(x: 0.735 * s, y: 0.505 * s, width: 0.12 * s, height: 0.12 * s))           // and its knuckle
    c.fillEllipse(in: CGRect(x: 0.735 * s, y: 0.355 * s, width: 0.12 * s, height: 0.12 * s))
    // the meat: a rounded drumstick narrowing toward the bone
    let leg = CGMutablePath()
    leg.move(to: P(s, 0.15, 0.49))
    leg.addCurve(to: P(s, 0.42, 0.70), control1: P(s, 0.15, 0.63), control2: P(s, 0.28, 0.71))
    leg.addCurve(to: P(s, 0.66, 0.53), control1: P(s, 0.55, 0.69), control2: P(s, 0.60, 0.58))
    leg.addLine(to: P(s, 0.66, 0.45))
    leg.addCurve(to: P(s, 0.42, 0.29), control1: P(s, 0.60, 0.40), control2: P(s, 0.55, 0.30))
    leg.addCurve(to: P(s, 0.15, 0.49), control1: P(s, 0.28, 0.28), control2: P(s, 0.15, 0.36))
    leg.closeSubpath()
    c.setFillColor(rgb(SKIN)); c.addPath(leg); c.fillPath()
    // the white sauce: one wave, 36 px, round caps, wholly on the meat
    let w = CGMutablePath()
    w.move(to: P(s, 0.24, 0.52))
    for i in 0..<5 {
        let x = 0.24 + CGFloat(i) * 0.074
        w.addQuadCurve(to: P(s, x + 0.074, 0.52), control: P(s, x + 0.037, i % 2 == 0 ? 0.575 : 0.465))
    }
    c.setStrokeColor(rgb(SAUCE)); c.setLineWidth(0.035 * s); c.setLineCap(.round); c.setLineJoin(.round)
    c.addPath(w); c.strokePath()
}

func render(_ n: Int, _ path: String, _ bg: UInt32, _ draw: (CGContext, CGFloat) -> Void) {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setShouldAntialias(true)
    ctx.setFillColor(rgb(bg)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n))
    draw(ctx, CGFloat(n))
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "playbook/brand"
render(1024, out + "/concept-a-1024.png", TEAL, oyster)
render(1024, out + "/concept-b-1024.png", CRIMSON, laneCake)
render(1024, out + "/concept-c-1024.png", SAND, chicken)
