//
//  HazeEffectView.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-14.
//

import SwiftUI

#if os(iOS)
public typealias PlatformView = UIView
#elseif os(macOS)
public typealias PlatformView = NSView
#endif

public final class HazeEffectView<Provider>: PlatformView where Provider: MaskProvider {
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

    #if os(iOS)
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

        setupBackdropLayer()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        renderFilter()
    }

    #elseif os(macOS)
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

        setupBackdropLayer()
    }

    override public func layout() {
        super.layout()
        renderFilter()
    }
    #endif

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
        guard
            let filter = variableBlur.filter,
            bounds != .zero,
            needsToRedrawMask || lastFrame != bounds
        else {
            return
        }

        #if os(iOS)
        let backing = window?.contentScaleFactor ?? 2.0
        #elseif os(macOS)
        guard let layer else {
            return
        }

        let backing = window?.backingScaleFactor ?? 2.0
        #endif

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

        // Applies filter
        layer.filters = []
        layer.filters = [filter]
    }

    private func setupBackdropLayer() {
        #if os(macOS)
        guard let caBackdropLayerClass = NSClassFromString("CABackdropLayer") as? CALayer.Type else {
            return
        }

        wantsLayer = true
        layer = caBackdropLayerClass.init()

        guard let layer else {
            return
        }
        #endif

        layer.masksToBounds = true
        layer.setValue(true, forKey: "windowServerAware")
        layer.setValue(false, forKey: "allowsInPlaceFiltering")
        layer.setValue(true, forKey: "allowsGroupBlending")
        layer.setValue(true, forKey: "allowsGroupOpacity")
        layer.setValue(false, forKey: "allowsEdgeAntialiasing")
        layer.setValue(true, forKey: "disablesOccludedBackdropBlurs")
        layer.setValue(true, forKey: "ignoresOffscreenGroups")
    }
}
