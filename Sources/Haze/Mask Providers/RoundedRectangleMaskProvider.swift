//
//  RoundedRectangleMaskProvider.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-14.
//

import CoreImage
import SwiftUI

/// A blurred, rounded rectangle mask used for variable blur effects.
///
/// ![Rounded Rectangle Mask](rounded_rectangle_mask)
///
public struct RoundedRectangleMaskProvider: MaskProvider {
    /// The radius of the corners for the rounded rectangle mask.
    public let cornerRadius: CGFloat

    /// The radius of the Gaussian blur applied to the rounded rectangle.
    public let blurRadius: CGFloat

    /// Per-edge configuration for padding and feather visibility.
    public let edgeConfigurations: [Edge: EdgeConfiguration]

    public struct EdgeConfiguration: Sendable, Equatable {
        public let isFeathered: Bool
        public let padding: PaddingUnit

        public enum PaddingUnit: Equatable, Sendable {
            case points(CGFloat)
            case percentage(CGFloat)
        }

        public init(feathered: Bool, padding: PaddingUnit = .points(0)) {
            self.isFeathered = feathered
            self.padding = padding
        }

        static let `default`: Self = .init(feathered: false)
    }

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
        var result = [Edge: EdgeConfiguration]()
        if featherEdges.contains(.top) { result[.top] = .init(feathered: true) }
        if featherEdges.contains(.bottom) { result[.bottom] = .init(feathered: true) }
        if featherEdges.contains(.leading) { result[.leading] = .init(feathered: true) }
        if featherEdges.contains(.trailing) { result[.trailing] = .init(feathered: true) }

        self.init(
            cornerRadius: cornerRadius,
            blurRadius: blurRadius,
            edgeConfigurations: result,
            invertAlpha: invertAlpha
        )
    }

    /// Initializes a new `RoundedRectangleMaskProvider`.
    /// - Parameters:
    ///   - cornerRadius: The radius of the corners for the rounded rectangle mask.
    ///   - blurRadius: The radius of the Gaussian blur applied to the rounded rectangle.
    ///   - edgeConfigurations: Per-edge padding and feather visibility. Missing edges use defaults (feathered: true, padding: 0).
    ///   - invertAlpha: Whether the alpha channel should be inverted, such that the rounded rectangle is clear and the edges are blurred.
    @_disfavoredOverload
    public init(
        cornerRadius: CGFloat,
        blurRadius: CGFloat,
        edgeConfigurations: [Edge: EdgeConfiguration] = [:],
        invertAlpha: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.blurRadius = blurRadius
        self.edgeConfigurations = edgeConfigurations
        self.invertAlpha = invertAlpha
    }

    public func draw(in bounds: CGRect, scale: CGFloat, in ciContext: CIContext) -> CGImage? {
        autoreleasepool {
            let scaledCornerRadius = max(1, cornerRadius * scale)
            let scaledBlurRadius = max(0, blurRadius * scale)

            let totalExtent = CGRect(
                x: 0,
                y: 0,
                width: max(1, Int(ceil(bounds.width * scale))),
                height: max(1, Int(ceil(bounds.height * scale)))
            ).integral

            let (maskExtent, maskClipRect) = getMaskExtent(
                in: totalExtent,
                scale: scale,
                scaledBlurRadius: scaledBlurRadius
            )

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
            let croppedMask = blurredMask
                .cropped(to: maskClipRect)
                .cropped(to: totalExtent)

            if invertAlpha {
                guard let inverted = invertAlpha(croppedMask) else {
                    return nil
                }
                return ciContext.createCGImage(inverted, from: totalExtent)
            }

            return ciContext.createCGImage(croppedMask, from: totalExtent)
        }
    }

    private func getMaskExtent(
        in totalExtent: CGRect,
        scale: CGFloat,
        scaledBlurRadius: CGFloat
    ) -> (extent: CGRect, clipRect: CGRect) {
        let insetFactor = 2 * scaledBlurRadius

        // outsetFactor ensures we expand enough to cover feather + corner radius
        let outsetFactor = insetFactor + max(insetFactor, cornerRadius)

        // Start by inseting so non-feathered edges move inward
        var maskExtent = totalExtent.insetBy(dx: insetFactor, dy: insetFactor)
        var clipRect = totalExtent

        let top = edgeConfigurations[.top] ?? .default
        let bottom = edgeConfigurations[.bottom] ?? .default
        let leading = edgeConfigurations[.leading] ?? .default
        let trailing = edgeConfigurations[.trailing] ?? .default

        let scaledPadding = getPaddingInsets(
            top: top,
            bottom: bottom,
            leading: leading,
            trailing: trailing,
            insetFactor: insetFactor,
            totalExtent: totalExtent,
            scale: scale
        )

        if top.isFeathered {
            maskExtent.size.height -= scaledPadding.top
        } else {
            maskExtent.size.height += outsetFactor
            clipRect.size.height -= scaledPadding.top
        }

        if bottom.isFeathered {
            maskExtent.origin.y += scaledPadding.bottom
            maskExtent.size.height -= scaledPadding.bottom
        } else {
            maskExtent.origin.y -= outsetFactor
            maskExtent.size.height += outsetFactor
            clipRect.origin.y += scaledPadding.bottom
            clipRect.size.height -= scaledPadding.bottom
        }

        if leading.isFeathered {
            maskExtent.origin.x += scaledPadding.leading
            maskExtent.size.width -= scaledPadding.leading
        } else {
            maskExtent.origin.x -= outsetFactor
            maskExtent.size.width += outsetFactor
            clipRect.origin.x += scaledPadding.leading
            clipRect.size.width -= scaledPadding.leading
        }

        if trailing.isFeathered {
            maskExtent.size.width -= scaledPadding.trailing
        } else {
            maskExtent.size.width += outsetFactor
            clipRect.size.width -= scaledPadding.trailing
        }

        // Prevent negative dimensions (just in case)
        if maskExtent.width < 0 { maskExtent.size.width = 0 }
        if maskExtent.height < 0 { maskExtent.size.height = 0 }

        return (maskExtent, clipRect)
    }

    private func getPaddingInsets(
        top: EdgeConfiguration,
        bottom: EdgeConfiguration,
        leading: EdgeConfiguration,
        trailing: EdgeConfiguration,
        insetFactor: CGFloat,
        totalExtent: CGRect,
        scale: CGFloat
    ) -> (top: CGFloat, bottom: CGFloat, leading: CGFloat, trailing: CGFloat) {
        let insetFactorCompensation = -insetFactor / 2
        var topPadding: CGFloat = insetFactorCompensation
        var bottomPadding: CGFloat = insetFactorCompensation
        var leadingPadding: CGFloat = insetFactorCompensation
        var trailingPadding: CGFloat = insetFactorCompensation

        switch top.padding {
        case let .points(points):
            topPadding += points * scale
        case let .percentage(percentage):
            topPadding += totalExtent.height * percentage * scale
        }

        switch bottom.padding {
        case let .points(points):
            bottomPadding += points * scale
        case let .percentage(percentage):
            bottomPadding += totalExtent.height * percentage * scale
        }

        switch leading.padding {
        case let .points(points):
            leadingPadding += points * scale
        case let .percentage(percentage):
            leadingPadding += totalExtent.width * percentage * scale
        }

        switch trailing.padding {
        case let .points(points):
            trailingPadding += points * scale
        case let .percentage(percentage):
            trailingPadding += totalExtent.width * percentage * scale
        }

        return (
            max(0, topPadding),
            max(0, bottomPadding),
            max(0, leadingPadding),
            max(0, trailingPadding)
        )
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
