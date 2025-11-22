//
//  LinearGradientMaskProvider.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-15.
//

import CoreImage
import SwiftUI

/// A linear gradient mask used for variable blur effects.
///
/// ![Linear Gradient Mask](linear_gradient_mask)
///
public struct LinearGradientMaskProvider: MaskProvider {
    /// The starting point of the linear gradient.
    public let startPoint: UnitPoint

    /// The ending point of the linear gradient.
    public let endPoint: UnitPoint

    /// The opacity at the start of the gradient.
    public let startOpacity: CGFloat

    /// The opacity at the end of the gradient.
    public let endOpacity: CGFloat

    /// Whether the gradient interpolates linearly (`false`) or uses a smooth sigmoid curve (`true`).
    public let isSmooth: Bool

    private static let gradientFilter: (CIFilter & CILinearGradient) = CIFilter.linearGradient()
    private static let smoothGradientFilter: (CIFilter & CISmoothLinearGradient) = CIFilter.smoothLinearGradient()

    /// Initializes a new `LinearGradientMaskProvider`.
    /// - Parameters:
    ///   - startPoint: The starting point of the linear gradient.
    ///   - endPoint: The ending point of the linear gradient.
    ///   - startOpacity: The opacity at the start of the gradient.
    ///   - endOpacity: The opacity at the end of the gradient.
    ///   - isSmooth: Whether the gradient interpolates linearly (`false`) or uses a smooth sigmoid curve (`true`).
    public init(
        startPoint: UnitPoint,
        endPoint: UnitPoint,
        startOpacity: CGFloat,
        endOpacity: CGFloat,
        isSmooth: Bool = true
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.startOpacity = startOpacity
        self.endOpacity = endOpacity
        self.isSmooth = isSmooth
    }

    public func draw(in bounds: CGRect, scale: CGFloat, in ciContext: CIContext) -> CGImage? {
        autoreleasepool {
            // Compute the extents
            let totalExtent = CGRect(
                x: 0,
                y: 0,
                width: max(1, Int(ceil(bounds.width * scale))),
                height: max(1, Int(ceil(bounds.height * scale)))
            )

            // Scale them to pixel space
            let startPt = CGPoint(
                x: startPoint.x * totalExtent.width,
                y: (1 - startPoint.y) * totalExtent.height
            )
            let endPt = CGPoint(
                x: endPoint.x * totalExtent.width,
                y: (1 - endPoint.y) * totalExtent.height
            )

            let color0 = CIColor(red: 0, green: 0, blue: 0, alpha: startOpacity)
            let color1 = CIColor(red: 0, green: 0, blue: 0, alpha: endOpacity)

            let gradientImage: CIImage?

            if isSmooth {
                Self.smoothGradientFilter.setDefaults()
                Self.smoothGradientFilter.setDefaults()
                Self.smoothGradientFilter.point0 = startPt
                Self.smoothGradientFilter.point1 = endPt
                Self.smoothGradientFilter.color0 = color0
                Self.smoothGradientFilter.color1 = color1
                gradientImage = Self.smoothGradientFilter.outputImage
            } else {
                Self.gradientFilter.setDefaults()
                Self.gradientFilter.setDefaults()
                Self.gradientFilter.point0 = startPt
                Self.gradientFilter.point1 = endPt
                Self.gradientFilter.color0 = color0
                Self.gradientFilter.color1 = color1
                gradientImage = Self.gradientFilter.outputImage
            }

            guard let gradientImage else {
                return nil
            }

            let cropped = gradientImage.cropped(to: totalExtent)
            return ciContext.createCGImage(cropped, from: totalExtent)
        }
    }
}
