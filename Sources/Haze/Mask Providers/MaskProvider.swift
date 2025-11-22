//
//  MaskProvider.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-14.
//

import CoreImage

/// A protocol that enables creating custom masks for use with `HazeEffectView`.
@MainActor
public protocol MaskProvider: Equatable {
    /// Renders the mask into an image for the given bounds and scale.
    /// - Parameters:
    ///   - bounds: The rectangle in which to draw the mask.
    ///   - scale: The scale factor to apply when rendering.
    ///   - ciContext: The context in which this mask should be rendered in.
    /// - Returns: A `CGImage` containing the rendered mask, or `nil` if rendering fails.
    func draw(in bounds: CGRect, scale: CGFloat, in ciContext: CIContext) -> CGImage?
}
