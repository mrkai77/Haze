//
//  RoundedRectangleMaskProvider.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-14.
//

import CoreImage
import SwiftUI

/// A blurred, rounded rectangle mask used for variable blur effects.
public struct RoundedRectangleMaskProvider: MaskProvider {
    /// The radius of the corners for the rounded rectangle mask.
    public let cornerRadius: CGFloat

    /// The radius of the Gaussian blur applied to the rounded rectangle.
    public let blurRadius: CGFloat

    /// The edges to which the blur is applied. Unlisted edges remain sharp.
    public let featherEdges: Edge.Set

    /// Whether the alpha channel should be inverted, such that the rounded rectangle is clear and the edges are blurred.
    public let invertAlpha: Bool

    private static let roundedRectGen: (CIFilter & CIRoundedRectangleGenerator) = CIFilter.roundedRectangleGenerator()
    private static let blurFilter: (CIFilter & CIGaussianBlur) = CIFilter.gaussianBlur()

    /// Initializes a new `RoundedRectangleMaskProvider`.
    /// - Parameters:
    ///   - cornerRadius: The radius of the corners for the rounded rectangle mask.
    ///   - blurRadius: The radius of the Gaussian blur applied to the rounded rectangle.
    ///   - featherEdges:The edges to which the blur is applied. Unlisted edges remain sharp.
    ///   - invertAlpha: Whether the alpha channel should be inverted, such that the rounded rectangle is clear and the edges are blurred.
    public init(
        cornerRadius: CGFloat,
        blurRadius: CGFloat,
        featherEdges: Edge.Set = .all,
        invertAlpha: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.blurRadius = blurRadius
        self.featherEdges = featherEdges
        self.invertAlpha = invertAlpha
    }

    public func draw(in bounds: CGRect, scale: CGFloat, in ciContext: CIContext) -> CGImage? {
        autoreleasepool {
            let scaledCornerRadius = max(0, cornerRadius * scale)
            let scaledBlurRadius = max(0, blurRadius * scale)
            let maskRect = getMaskRect(in: bounds, scale: scale)

            let totalExtent = CGRect(
                x: 0,
                y: 0,
                width: max(1, Int(ceil(bounds.width * scale))),
                height: max(1, Int(ceil(bounds.height * scale)))
            ).integral

            let maskExtent = CGRect(
                x: maskRect.origin.x * scale,
                y: maskRect.origin.y * scale,
                width: maskRect.width * scale,
                height: maskRect.height * scale
            ).integral

            Self.roundedRectGen.setDefaults()
            Self.roundedRectGen.extent = maskExtent
            Self.roundedRectGen.radius = Float(scaledCornerRadius)
            Self.roundedRectGen.color = .black

            guard let rounded = Self.roundedRectGen.outputImage else { return nil }

            Self.blurFilter.setDefaults()
            Self.blurFilter.inputImage = rounded
            Self.blurFilter.radius = Float(scaledBlurRadius)

            guard let blurredMask = Self.blurFilter.outputImage else { return nil }

            // Crop to the final size (in case it expands out of the needed frame)
            let croppedMask = blurredMask.cropped(to: totalExtent)

            if invertAlpha {
                guard let inverted = invertAlpha(croppedMask) else {
                    return nil
                }
                return ciContext.createCGImage(inverted, from: totalExtent)
            }

            return ciContext.createCGImage(croppedMask, from: totalExtent)
        }
    }

    private func getMaskRect(in bounds: CGRect, scale: CGFloat) -> CGRect {
        let insetFactor = 2 * blurRadius * scale
        // outsetFactor ensures we expand enough to cover feather + corner smoothing
        let outsetFactor = insetFactor + max(insetFactor, cornerRadius)

        // Start by inseting so non-feathered edges move inward
        var rect = bounds.insetBy(dx: insetFactor, dy: insetFactor)

        if !featherEdges.contains(.top) {
            rect.size.height += outsetFactor
        }

        if !featherEdges.contains(.bottom) {
            rect.origin.y -= outsetFactor
            rect.size.height += outsetFactor
        }

        if !featherEdges.contains(.leading) {
            rect.origin.x -= outsetFactor
            rect.size.width += outsetFactor
        }

        if !featherEdges.contains(.trailing) {
            rect.size.width += outsetFactor
        }

        // Prevent negative dimensions (just in case)
        if rect.width < 0 { rect.size.width = 0 }
        if rect.height < 0 { rect.size.height = 0 }

        return rect.integral
    }

    private func invertAlpha(_ image: CIImage) -> CIImage? {
        let filter = CIFilter.colorMatrix()
        filter.inputImage = image

        filter.rVector = CIVector(x: 1, y: 0, z: 0, w: 0)
        filter.gVector = CIVector(x: 0, y: 1, z: 0, w: 0)
        filter.bVector = CIVector(x: 0, y: 0, z: 1, w: 0)
        filter.aVector = CIVector(x: 0, y: 0, z: 0, w: -1)
        filter.biasVector = CIVector(x: 0, y: 0, z: 0, w: 1)

        return filter.outputImage
    }
}
