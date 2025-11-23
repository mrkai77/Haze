//
//  ShapeMaskProvider.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-22.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

// TODO: somehow put this in ShapeMaskProvider without breaking Equatable, but also only initalize once
@MainActor
private let blurFilter: (CIFilter & CIGaussianBlur) = CIFilter.gaussianBlur()

/// A blurred shape-based mask used for variable blur effects.
public struct ShapeMaskProvider<S>: MaskProvider where S: Shape & Equatable {
    /// The SwiftUI shape used to form the mask.
    public let shape: S

    /// The radius of the Gaussian blur applied to the shape.
    public let blurRadius: CGFloat

    /// Initializes a new `ShapeMaskProvider`.
    /// - Parameters:
    ///   - shape: The SwiftUI shape used to form the mask.
    ///   - blurRadius: The radius of the Gaussian blur applied to the shape.
    public init(shape: S, blurRadius: CGFloat) {
        self.shape = shape
        self.blurRadius = blurRadius
    }

    public func draw(in bounds: CGRect, scale: CGFloat, in ciContext: CIContext) -> CGImage? {
        autoreleasepool {
            // Full output extent in pixel space
            let totalExtent = CGRect(
                x: 0,
                y: 0,
                width: max(1, Int(ceil(bounds.width * scale))),
                height: max(1, Int(ceil(bounds.height * scale)))
            ).integral

            let insetAmount = 2 * blurRadius
            let shapeRect = bounds.insetBy(dx: insetAmount, dy: insetAmount).integral

            let colorSpace = CGColorSpaceCreateDeviceGray()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.alphaOnly.rawValue)

            guard let context = CGContext(
                data: nil,
                width: Int(totalExtent.width),
                height: Int(totalExtent.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                return nil
            }

            // Clear to transparent
            context.clear(totalExtent)

            // Shape area opaque, background transparent
            context.setFillColor(CGColor(gray: 0, alpha: 1))

            let swiftUIPath = shape.path(in: shapeRect)
            var cgPath = swiftUIPath.cgPath

            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: -bounds.origin.x, y: -bounds.origin.y)
            transform = transform.scaledBy(x: scale, y: scale)

            // Flip vertically within the pixel extent (SwiftUI has y-down, Core Graphics has y-up)
            transform = transform
                .translatedBy(x: 0, y: totalExtent.height)
                .scaledBy(x: 1, y: -1)

            if let transformedPath = cgPath.copy(using: &transform) {
                cgPath = transformedPath
            }

            context.addPath(cgPath)
            context.fillPath()

            guard let image = context.makeImage() else {
                return nil
            }

            let ciMask = CIImage(cgImage: image)

            blurFilter.setDefaults()
            blurFilter.inputImage = ciMask
            blurFilter.radius = Float(blurRadius * scale)

            guard let blurred = blurFilter.outputImage else {
                return nil
            }

            let cropped = blurred.cropped(to: totalExtent)
            return ciContext.createCGImage(cropped, from: totalExtent)
        }
    }
}
