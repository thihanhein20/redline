// Draws Redline's app icon: a dark macOS tile with a speedometer whose last stretch is red (the "redline").
//   swift scripts/make-icon.swift Resources/AppIcon.png   → 1024×1024 PNG
import AppKit

let size: CGFloat = 1024
let red = CGColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1)   // system red
let dial = CGColor(gray: 0.93, alpha: 1)

let context = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// Tile: Apple's icon grid is an 824 pt rounded square centred in 1024, with a soft drop shadow.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: CGColor(gray: 0, alpha: 0.45))
context.addPath(tilePath)
context.setFillColor(CGColor(gray: 0.1, alpha: 1))
context.fillPath()
context.restoreGState()

context.saveGState()
context.addPath(tilePath)
context.clip()
let background = CGGradient(colorsSpace: nil, colors: [CGColor(red: 0.20, green: 0.20, blue: 0.23, alpha: 1),
                                                       CGColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1)] as CFArray,
                            locations: [0, 1])!
context.drawLinearGradient(background, start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.minY), options: [])
context.restoreGState()

// Gauge: 240° sweep from lower-left to lower-right; the last 60° is the red zone.
let center = CGPoint(x: 512, y: 470)
let radius: CGFloat = 270
func radians(_ degrees: CGFloat) -> CGFloat { degrees * .pi / 180 }
func arc(from start: CGFloat, to end: CGFloat, color: CGColor) {
    context.addArc(center: center, radius: radius, startAngle: radians(start), endAngle: radians(end), clockwise: true)
    context.setStrokeColor(color)
    context.setLineWidth(58)
    context.setLineCap(.round)
    context.strokePath()
}
arc(from: 210, to: 46, color: dial)
arc(from: 24, to: -30, color: red)

// Needle pointing into the red zone, with a hub.
let needleAngle = radians(8)
let tip = CGPoint(x: center.x + cos(needleAngle) * 225, y: center.y + sin(needleAngle) * 225)
context.move(to: center)
context.addLine(to: tip)
context.setStrokeColor(red)
context.setLineWidth(34)
context.setLineCap(.round)
context.strokePath()

context.setFillColor(dial)
context.fillEllipse(in: CGRect(x: center.x - 52, y: center.y - 52, width: 104, height: 104))
context.setFillColor(CGColor(gray: 0.08, alpha: 1))
context.fillEllipse(in: CGRect(x: center.x - 20, y: center.y - 20, width: 40, height: 40))

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let png = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
try! png.write(to: output)
print("Wrote \(output.path)")
