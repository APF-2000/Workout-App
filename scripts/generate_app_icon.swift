import AppKit

let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Workout App/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

let canvasSize = CGSize(width: 1024, height: 1024)

func drawIcon(size: CGSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(origin: .zero, size: size)
    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: size.width * 0.22, yRadius: size.height * 0.22)

    context.saveGState()
    backgroundPath.addClip()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.12, green: 0.42, blue: 0.92, alpha: 1),
        NSColor(calibratedRed: 0.05, green: 0.19, blue: 0.53, alpha: 1)
    ])!
    gradient.draw(in: backgroundPath, angle: -45)

    let glowRect = CGRect(x: size.width * 0.14, y: size.height * 0.08, width: size.width * 0.72, height: size.height * 0.54)
    let glowPath = NSBezierPath(ovalIn: glowRect)
    NSColor(calibratedRed: 0.47, green: 0.82, blue: 0.98, alpha: 0.16).setFill()
    glowPath.fill()

    let plateRect = CGRect(x: size.width * 0.16, y: size.height * 0.16, width: size.width * 0.68, height: size.height * 0.68)
    let platePath = NSBezierPath(roundedRect: plateRect, xRadius: size.width * 0.15, yRadius: size.height * 0.15)
    NSColor(calibratedWhite: 1, alpha: 0.12).setFill()
    platePath.fill()

    let dumbbellColor = NSColor.white
    dumbbellColor.setFill()

    let barHeight = size.height * 0.065
    let barRect = CGRect(x: size.width * 0.25, y: size.height * 0.47, width: size.width * 0.50, height: barHeight)
    NSBezierPath(roundedRect: barRect, xRadius: barHeight / 2, yRadius: barHeight / 2).fill()

    func plate(x: CGFloat, width: CGFloat, height: CGFloat) {
        let plateRect = CGRect(x: x, y: size.height * 0.38, width: width, height: height)
        NSBezierPath(roundedRect: plateRect, xRadius: width / 2.8, yRadius: width / 2.8).fill()
    }

    plate(x: size.width * 0.16, width: size.width * 0.07, height: size.height * 0.24)
    plate(x: size.width * 0.24, width: size.width * 0.045, height: size.height * 0.18)
    plate(x: size.width * 0.715, width: size.width * 0.045, height: size.height * 0.18)
    plate(x: size.width * 0.77, width: size.width * 0.07, height: size.height * 0.24)

    let chartPath = NSBezierPath()
    chartPath.move(to: CGPoint(x: size.width * 0.28, y: size.height * 0.30))
    chartPath.line(to: CGPoint(x: size.width * 0.42, y: size.height * 0.42))
    chartPath.line(to: CGPoint(x: size.width * 0.54, y: size.height * 0.36))
    chartPath.line(to: CGPoint(x: size.width * 0.70, y: size.height * 0.58))
    chartPath.lineWidth = size.width * 0.04
    chartPath.lineCapStyle = .round
    chartPath.lineJoinStyle = .round
    NSColor(calibratedRed: 1.0, green: 0.53, blue: 0.18, alpha: 1).setStroke()
    chartPath.stroke()

    let arrowPath = NSBezierPath()
    arrowPath.move(to: CGPoint(x: size.width * 0.70, y: size.height * 0.58))
    arrowPath.line(to: CGPoint(x: size.width * 0.66, y: size.height * 0.57))
    arrowPath.move(to: CGPoint(x: size.width * 0.70, y: size.height * 0.58))
    arrowPath.line(to: CGPoint(x: size.width * 0.685, y: size.height * 0.54))
    arrowPath.lineWidth = size.width * 0.03
    arrowPath.lineCapStyle = .round
    NSColor(calibratedRed: 1.0, green: 0.53, blue: 0.18, alpha: 1).setStroke()
    arrowPath.stroke()

    context.restoreGState()
    image.unlockFocus()
    return image
}

let baseImage = drawIcon(size: canvasSize)
guard let tiffData = baseImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render icon")
}

let baseURL = outputDirectory.appendingPathComponent("AppIcon-1024.png")
try pngData.write(to: baseURL)

let sizes = [
    20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
]

func writeScaledCopy(size: Int) throws {
    let destination = outputDirectory.appendingPathComponent("AppIcon-\(size).png")
    let target = NSImage(size: CGSize(width: size, height: size))
    target.lockFocus()
    baseImage.draw(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
    target.unlockFocus()

    guard let tiff = target.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGeneration", code: 1)
    }

    try data.write(to: destination)
}

for size in sizes {
    try writeScaledCopy(size: size)
}
