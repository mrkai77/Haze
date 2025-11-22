//
//  UIHazeEffectView.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-14.
//

import SwiftUI

#if os(iOS)
/// A UIKit view that manages a variable blur mask and applies a variable blur effect to its content for display.
@MainActor
public final class UIHazeEffectView<Provider>: UIView where Provider: MaskProvider {
    /// The mask provider used by this variable blur.
    public private(set) var maskProvider: Provider

    /// The variable blur engine applied to this view.
    public private(set) var variableBlur: VariableBlurEngine

    /// The scale factor at which the mask is applied to the variable blur.
    /// Lower values may reduce quality but can improve performance.
    public private(set) var scale: CGFloat

    private var lastFrame: CGRect = .zero
    private var needsToRedrawMask: Bool = true

    private let ciContext: CIContext = if let device = MTLCreateSystemDefaultDevice() {
        .init(mtlDevice: device, options: [.cacheIntermediates: true])
    } else {
        .init(options: [.cacheIntermediates: true])
    }

    override public class var layerClass: AnyClass {
        (NSClassFromString("CABackdropLayer") as? CALayer.Type) ?? CALayer.self
    }

    /// Initializes a new `HazeEffectView`.
    /// - Parameters:
    ///   - maskProvider: The mask provider used by this variable blur.
    ///   - variableBlur: The variable blur engine applied to this view.
    ///   - scale: The scale factor at which the mask is applied to the variable blur.
    ///   - frame: The frame of this view.
    public init(
        maskProvider: Provider,
        variableBlur: VariableBlurEngine,
        scale: CGFloat = 0.5,
        frame: CGRect = .zero
    ) {
        self.maskProvider = maskProvider
        self.variableBlur = variableBlur
        self.scale = scale

        super.init(frame: frame)

        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Updates the mask provider and autmatically triggers a re-render of the mask.
    /// - Parameter provider: The new mask provider used by this variable blur.
    public func setMaskProvider(to maskProvider: Provider) {
        guard self.maskProvider != maskProvider else {
            return
        }

        self.maskProvider = maskProvider
        needsToRedrawMask = true
    }

    /// Updates the mask's scale and autmatically triggers a re-render of the mask.
    /// - Parameter scale: The new scale factor at which the mask is applied to the variable blur.
    public func setScale(to scale: CGFloat) {
        guard self.scale != scale else {
            return
        }

        self.scale = scale
        needsToRedrawMask = true
    }

    /// Re-renders the current mask and applies it to the variable blur effect.
    func renderFilter() {
        guard let filter = variableBlur.filter else {
            return
        }

        if needsToRedrawMask || lastFrame != bounds {
            let backing = window?.contentScaleFactor ?? 2.0
            let scale = max(0.25, min(2.0, backing * scale))

            if let image = maskProvider.draw(
                in: bounds,
                scale: scale,
                in: ciContext
            ) {
                variableBlur.setMaskImage(to: image)
            }
            
            needsToRedrawMask = false
            lastFrame = bounds
        }

        // Applies filter
        layer.filters = []
        layer.filters = [filter]
    }

    // MARK: Private

    private func setup() {
        layer.setValue(true, forKey: "isEnabled")
        layer.setValue(true, forKey: "windowServerAware")
        layer.setValue(true, forKey: "allowsInPlaceFiltering")

        renderFilter()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        renderFilter()
    }
}
#endif
