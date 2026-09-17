import CoreGraphics
import CoreVideo
import ImageIO

enum LightGuardStatus: Equatable {
    case tooDark
    case harsh
    case offBaseline
    case ok

    var banner: String {
        switch self {
        case .tooDark: "Find brighter light — move toward a window."
        case .harsh: "Too much shadow — face the light, not away."
        case .offBaseline: "The light changed from your last photo — try to match it."
        case .ok: "Light looks good."
        }
    }

    var icon: String {
        switch self {
        case .tooDark: "moon.stars.fill"
        case .harsh: "sun.max.fill"
        case .offBaseline: "arrow.left.arrow.right"
        case .ok: "checkmark.circle.fill"
        }
    }

    var isPass: Bool { self == .ok }
}

nonisolated enum LightGuard {
    static let darkThreshold: Double = 62
    static let harshThreshold: Double = 186

    static func evaluate(meanLuma: Double, baseline: Double?) -> LightGuardStatus {
        if meanLuma < darkThreshold { return .tooDark }
        if meanLuma > harshThreshold { return .harsh }
        if let baseline, baseline > 0 {
            let tolerance = max(baseline * 0.15, 8)
            if abs(meanLuma - baseline) > tolerance { return .offBaseline }
        }
        return .ok
    }

    static func meanLuma(from pixelBuffer: CVPixelBuffer) -> Double {
        let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return 0 }

        if format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange || format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
            guard let yBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return 0 }
            let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
            let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
            let stride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
            return sampleLuma(pointer: yBase, width: width, height: height, stride: stride, channels: 1)
        }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let stride = CVPixelBufferGetBytesPerRow(pixelBuffer)
        return sampleLuma(pointer: base, width: width, height: height, stride: stride, channels: 4)
    }

    static func meanLuma(fromImageData data: Data) -> Double {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways as String: true,
                  kCGImageSourceThumbnailMaxPixelSize as String: "128"
              ] as CFDictionary) else { return 0 }
        let w = 64, h = 64
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let ok = pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(
                data: raw.baseAddress,
                width: w, height: h,
                bitsPerComponent: 8, bytesPerRow: w * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard ok else { return 0 }
        var total = 0.0
        for i in stride(from: 0, to: pixels.count, by: 4) {
            total += 0.299 * Double(pixels[i]) + 0.587 * Double(pixels[i + 1]) + 0.114 * Double(pixels[i + 2])
        }
        return total / Double(w * h)
    }

    private static func sampleLuma(pointer: UnsafeMutableRawPointer, width: Int, height: Int, stride: Int, channels: Int) -> Double {
        let buffer = pointer.assumingMemoryBound(to: UInt8.self)
        var total = 0.0
        var count = 0
        let stepY = max(1, height / 32)
        let stepX = max(1, width / 32)
        var y = 0
        while y < height {
            var x = 0
            while x < width {
                let offset = y * stride + x * channels
                if channels == 1 {
                    total += Double(buffer[offset])
                } else {
                    total += 0.299 * Double(buffer[offset]) + 0.587 * Double(buffer[offset + 1]) + 0.114 * Double(buffer[offset + 2])
                }
                count += 1
                x += stepX
            }
            y += stepY
        }
        return count > 0 ? total / Double(count) : 0
    }
}
