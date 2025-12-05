//
//  ImageMaskProvider.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-15.
//

import CoreImage
import SwiftUI

#if os(iOS)
public typealias PlatformImage = UIImage
#elseif os(macOS)
public typealias PlatformImage = NSImage
#endif

/// A mask that enables the usage of images as masks for variable blur effects.
///
/// ![Image Mask](image_mask)
///
public struct ImageMaskProvider: MaskProvider {
    /// The CGImage backing the mask image.
    public let cgImage: CGImage

    /// The content mode applied to the image when rendering.
    public let contentMode: ContentMode

    /// Determines how the image is interpreted for the mask.
    /// Pass `false` to use the alpha channel, or `true` to treat white pixels as fully transparent.
    public let useGrayscaleAsAlpha: Bool

    /// Defines how the mask image is scaled and positioned within its bounds.
    public enum ContentMode: Sendable {
        /// The image fills the bounds, preserving its aspect ratio. Portions may be clipped.
        case fill

        /// The image fits entirely within the bounds, preserving its aspect ratio. May leave empty space.
        case fit

        /// The image stretches to exactly fill the bounds, ignoring its aspect ratio.
        case stretch
    }

    private static let grayscaleFilter: (CIFilter & CIColorControls) = CIFilter.colorControls()
    private static let invertFilter: (CIFilter & CIColorInvert) = CIFilter.colorInvert()
    private static let maskFilter: (CIFilter & CIMaskToAlpha) = CIFilter.maskToAlpha()

    /// Initializes a new `EllipseMaskProvider`.
    /// - Parameters:
    ///   - image: The image to be used as the mask.
    ///   - contentMode: The content mode applied to the image when rendering.
    ///   - useGrayscaleAsAlpha: Pass `false` to use the alpha channel, or `true` to treat white pixels as fully transparent.
    public init(
        image: PlatformImage,
        contentMode: ContentMode = .fill,
        useGrayscaleAsAlpha: Bool = false
    ) {
        #if os(iOS)
        guard let cgImage = image.cgImage else {
            preconditionFailure()
        }
        #elseif os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            preconditionFailure()
        }
        #endif

        self.cgImage = cgImage
        self.contentMode = contentMode
        self.useGrayscaleAsAlpha = useGrayscaleAsAlpha
    }

    public func draw(in bounds: CGRect, scale: CGFloat, in ciContext: CIContext) -> CGImage? {
        autoreleasepool {
            let totalExtent = CGRect(
                x: 0,
                y: 0,
                width: max(1, Int(ceil(bounds.width * scale))),
                height: max(1, Int(ceil(bounds.height * scale)))
            ).integral

            var ciImage = CIImage(cgImage: cgImage)

            if useGrayscaleAsAlpha {
                ciImage = convertLuminanceToAlpha(ciImage)
            }

            let transform = calculateTransform(
                imageSize: ciImage.extent.size,
                targetSize: totalExtent.size,
                contentMode: contentMode
            )

            let transformedImage = ciImage.transformed(by: transform)
            let croppedImage = transformedImage.cropped(to: totalExtent)
            return ciContext.createCGImage(croppedImage, from: totalExtent)
        }
    }

    private func calculateTransform(
        imageSize: CGSize,
        targetSize: CGSize,
        contentMode: ContentMode
    ) -> CGAffineTransform {
        let scaleX: CGFloat
        let scaleY: CGFloat
        let translateX: CGFloat
        let translateY: CGFloat

        switch contentMode {
        case .fill:
            let scale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
            scaleX = scale
            scaleY = scale
            translateX = (targetSize.width - imageSize.width * scale) / 2
            translateY = (targetSize.height - imageSize.height * scale) / 2

        case .fit:
            let scale = min(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
            scaleX = scale
            scaleY = scale
            translateX = (targetSize.width - imageSize.width * scale) / 2
            translateY = (targetSize.height - imageSize.height * scale) / 2

        case .stretch:
            scaleX = targetSize.width / imageSize.width
            scaleY = targetSize.height / imageSize.height
            translateX = 0
            translateY = 0
        }

        var transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        transform = transform.translatedBy(x: translateX / scaleX, y: translateY / scaleY)

        return transform
    }

    private func convertLuminanceToAlpha(_ image: CIImage) -> CIImage {
        Self.grayscaleFilter.setDefaults()
        Self.grayscaleFilter.inputImage = image
        Self.grayscaleFilter.saturation = 0.0

        guard let grayscaleImage = Self.grayscaleFilter.outputImage else {
            return image
        }

        Self.invertFilter.setDefaults()
        Self.invertFilter.inputImage = grayscaleImage

        guard let invertedImage = Self.invertFilter.outputImage else {
            return grayscaleImage
        }

        Self.maskFilter.setDefaults()
        Self.maskFilter.inputImage = invertedImage
        return Self.maskFilter.outputImage ?? invertedImage
    }
}
