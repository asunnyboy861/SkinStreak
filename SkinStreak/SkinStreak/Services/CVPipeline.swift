import CoreGraphics
import Foundation
import ImageIO

nonisolated struct SkinMetrics: Equatable {
    var rednessPct: Double
    var textureVar: Double
    var spotCount: Int
}

nonisolated enum CVPipeline {
    static func analyze(imageData: Data, fitzpatrick: Int) -> SkinMetrics? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways as String: true,
                  kCGImageSourceThumbnailMaxPixelSize as String: "384"
              ] as CFDictionary) else { return nil }

        let width = 192
        let height = min(256, max(1, Int(Double(cgImage.height) / Double(cgImage.width) * Double(width))))
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(
                data: raw.baseAddress,
                width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        return computeMetrics(pixels: pixels, width: width, height: height, fitzpatrick: fitzpatrick)
    }

    static func computeMetrics(pixels: [UInt8], width: Int, height: Int, fitzpatrick: Int) -> SkinMetrics {
        let grade = min(6, max(1, fitzpatrick))
        let minVal: Double = [0.28, 0.24, 0.20, 0.16, 0.12, 0.09][grade - 1]
        let maxSat: Double = [0.55, 0.58, 0.62, 0.66, 0.70, 0.74][grade - 1]
        let rednessThreshold: Double = [26, 28, 30, 34, 38, 42][grade - 1]
        let spotThreshold: Double = [12, 12, 14, 16, 18, 20][grade - 1]

        var skinCount = 0
        var redCount = 0
        var textureSum = 0.0
        let gridSize = 48
        var spotGrid = [Int](repeating: 0, count: gridSize * gridSize)

        func luma(_ r: Double, _ g: Double, _ b: Double) -> Double {
            0.299 * r + 0.587 * g + 0.114 * b
        }

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let idx = (y * width + x) * 4
                let r = Double(pixels[idx]), g = Double(pixels[idx + 1]), b = Double(pixels[idx + 2])
                let mx = max(r, g, b), mn = min(r, g, b)
                let val = mx / 255.0
                let sat = mx > 0 ? (mx - mn) / mx : 0
                let isSkin = val >= minVal && sat >= 0.10 && sat <= maxSat && r > b && r >= g && (r - b) >= 6
                guard isSkin else { continue }
                skinCount += 1

                if (r - g) > rednessThreshold { redCount += 1 }

                let center = luma(r, g, b)
                var localSum = 0.0
                for dy in -1...1 {
                    for dx in -1...1 {
                        let nIdx = ((y + dy) * width + (x + dx)) * 4
                        localSum += luma(Double(pixels[nIdx]), Double(pixels[nIdx + 1]), Double(pixels[nIdx + 2]))
                    }
                }
                let deviation = abs(center - localSum / 9.0)
                textureSum += deviation
                if deviation > spotThreshold {
                    let gx = min(gridSize - 1, x * gridSize / width)
                    let gy = min(gridSize - 1, y * gridSize / height)
                    spotGrid[gy * gridSize + gx] += 1
                }
            }
        }

        guard skinCount > 0 else {
            return SkinMetrics(rednessPct: 0, textureVar: 0, spotCount: 0)
        }

        let spotCount = countSpotClusters(grid: spotGrid, gridSize: gridSize)
        let rednessPct = (Double(redCount) / Double(skinCount) * 1000).rounded() / 10
        let textureVar = (textureSum / Double(skinCount) * 100).rounded() / 100
        return SkinMetrics(rednessPct: rednessPct, textureVar: textureVar, spotCount: spotCount)
    }

    private static func countSpotClusters(grid: [Int], gridSize: Int) -> Int {
        var visited = [Bool](repeating: false, count: grid.count)
        var clusters = 0
        for start in 0..<grid.count {
            guard grid[start] > 0, !visited[start] else { continue }
            var size = 0
            var stack = [start]
            visited[start] = true
            while let cell = stack.popLast() {
                size += 1
                let cx = cell % gridSize, cy = cell / gridSize
                let neighbors = [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]
                for (nx, ny) in neighbors where nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize {
                    let nIdx = ny * gridSize + nx
                    if grid[nIdx] > 0 && !visited[nIdx] {
                        visited[nIdx] = true
                        stack.append(nIdx)
                    }
                }
            }
            if size >= 2 { clusters += 1 }
        }
        return min(clusters, 999)
    }
}
