import CoreGraphics
import ImageIO
import UIKit

struct ConditionFeatureAnalyzer {
    static func metrics(from image: CGImage) -> ConditionMetrics {
        let size = CGSize(width: image.width, height: image.height)
        let data = cgImageToGrayscaleData(image)
        let sharp = estimateSharpness(data: data, width: image.width, height: image.height)
        let lum = estimateLuminance(data: data, width: image.width, height: image.height)
        let contrast = estimateContrast(data: data, width: image.width, height: image.height)
        let glare = detectGlare(data: data, width: image.width, height: image.height)
        let centering = estimateCentering(image: image, size: size)
        let wear = estimateWear(data: data, width: image.width, height: image.height)

        return ConditionMetrics(
            quality: .init(sharpness: sharp, brightness: lum, contrast: contrast, hasGlare: glare > 0.01, glareAreaRatio: glare),
            centering: centering,
            wear: wear,
            confidence: clamp((sharp + centering.edgeUniformity + (1 - min(1, wear.cornerDamage + wear.edgeDamage + wear.whitening))) / 3, 0, 1)
        )
    }

    private static func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(v, lo), hi)
    }

    private static func cgImageToGrayscaleData(_ image: CGImage) -> [UInt8] {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var data = [UInt8](repeating: 0, count: width * height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: &data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: 0)
        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return data
    }

    // Sobel variance
    private static func estimateSharpness(data: [UInt8], width: Int, height: Int) -> Double {
        var gxTotal: Double = 0
        var count = 0
        for y in stride(from: 1, to: height - 1, by: 1) {
            for x in stride(from: 1, to: width - 1, by: 1) {
                let i = y * width + x
                let v1 = Double(data[i - 1 - width])
                let v2 = Double(data[i - width])
                let v3 = Double(data[i + 1 - width])
                let v4 = Double(data[i - 1])
                let v5 = Double(data[i])
                let v6 = Double(data[i + 1])
                let v7 = Double(data[i - 1 + width])
                let v8 = Double(data[i + width])
                let v9 = Double(data[i + 1 + width])
                let gx = -v1 - 2*v4 - v7 + v3 + 2*v6 + v9
                gxTotal += gx*gx
                count += 1
            }
        }
        let varSobel = count > 0 ? gxTotal / Double(count) : 0
        return clamp(sqrt(varSobel) / 50.0, 0, 1)
    }

    private static func estimateLuminance(data: [UInt8], width: Int, height: Int) -> Double {
        var sum: Double = 0
        let count = width * height
        for v in data.prefix(count) { sum += Double(v) }
        return clamp(sum / (255.0 * Double(count)), 0, 1)
    }

    private static func estimateContrast(data: [UInt8], width: Int, height: Int) -> Double {
        var sum: Double = 0, sum2: Double = 0
        let count = Double(max(1, width * height))
        for v in data { let d = Double(v); sum += d; sum2 += d*d }
        let mean = sum / count
        let varv = max(0, sum2 / count - mean*mean)
        return clamp(sqrt(varv) / 80.0, 0, 1)
    }

    // simple high-luminance blob ratio
    private static func detectGlare(data: [UInt8], width: Int, height: Int) -> Double {
        var bright = 0
        let total = width * height
        for v in data {
            if v >= 240 { bright += 1 }
        }
        return Double(bright) / Double(max(1, total))
    }

    private static func estimateCentering(image: CGImage, size: CGSize) -> CenteringMetrics {
        return .init(isCentered: true, horizontalOffset: 0, verticalOffset: 0, edgeUniformity: 0.85)
    }

    private static func estimateWear(data: [UInt8], width: Int, height: Int) -> WearMetrics {
        var borderDark = 0
        let border = min(width, height) / 20
        let totalBorder = border * (2*width + 2*height - 4*border)
        for y in stride(from: 0, to: height, by: 1) {
            for x in stride(from: 0, to: width, by: 1) {
                if x < border || x >= width-border || y < border || y >= height-border { continue }
            }
        }
        var edgeDarkRatio = 0.0
        if totalBorder > 0 {
            for y in stride(from: 0, to: height, by: 1) {
                for x in stride(from: 0, to: width, by: 1) {
                    let isBorder = (x < border || x >= width-border || y < border || y >= height-border)
                    if !isBorder { continue }
                    let v = Double(data[y*width + x])
                    if v < 60 { borderDark += 1 }
                }
            }
            edgeDarkRatio = Double(borderDark) / Double(totalBorder)
        }
        let corner = Double(borderDark) / Double(max(1, totalBorder)) * 0.4
        return .init(cornerDamage: corner, edgeDamage: edgeDarkRatio * 0.6, surfaceScratches: 0.05, whitening: edgeDarkRatio * 0.3, isBent: false)
    }
}
