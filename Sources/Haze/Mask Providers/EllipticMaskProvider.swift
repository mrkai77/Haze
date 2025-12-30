//
//  EllipticMaskProvider.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-15.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

/// A blurred, elliptic mask used for variable blur effects.
///
/// ![Elliptic Mask](elliptic_mask)
///
public struct EllipticMaskProvider: MaskProvider {
    /// The radius of the Gaussian blur applied to the ellipse.
    public let blurRadius: CGFloat

    private static let blurFilter: (CIFilter & CIGaussianBlur) = CIFilter.gaussianBlur()

    /// Initializes a new `EllipseMaskProvider`.
    /// - Parameters:
    ///   - blurRadius: The radius of the Gaussian blur applied to the ellipse.
    public init(blurRadius: CGFloat) {
        self.blurRadius = blurRadius
    }

    public func draw(in bounds: CGRect, scale: CGFloat, in ciContext: CIContext) -> CGImage? {
        autoreleasepool {
            let maskRect = getEllipseRect(in: bounds, scale: scale)

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

            context.clear(totalExtent)
            context.setFillColor(CGColor(gray: 0, alpha: 1))
            context.fillEllipse(in: maskExtent)

            guard let image = context.makeImage() else {
                return nil
            }

            let ciMask = CIImage(cgImage: image)

            Self.blurFilter.setDefaults()
            Self.blurFilter.inputImage = ciMask
            Self.blurFilter.radius = Float(blurRadius * scale) / 2.0

            guard let blurred = Self.blurFilter.outputImage else {
                return nil
            }

            let cropped = blurred.cropped(to: totalExtent)
            return ciContext.createCGImage(cropped, from: totalExtent)
        }
    }

    private func getEllipseRect(in bounds: CGRect, scale: CGFloat) -> CGRect {
        let insetFactor = blurRadius * scale
        return bounds.insetBy(dx: insetFactor, dy: insetFactor)
    }
}
