//
//  VariableBlurEngine.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-14.
//

import CoreImage

/// Manages a variable blur `CAFilter` object, and exposes a type-safe API.
@MainActor
public final class VariableBlurEngine {
    /// The `CAFilter` object that is managed by this class.
    let filter: NSObject?

    /// The max blur radius of the variable blur effect.
    public var maxBlurRadius: CGFloat? {
        if let value = filter?.value(forKey: "inputRadius") {
            value as? CGFloat
        } else {
            nil
        }
    }

    /// The image to use as the mask for this variable blur effect.
    public var maskImage: CGImage? {
        if let value = filter?.value(forKey: "inputMaskImage") {
            (value as! CGImage) // Cannot optionally downcast here
        } else {
            nil
        }
    }

    /// Initializes a new `VariableBlurEngine`
    /// - Parameter maxBlurRadius: The max blur radius of the variable blur effect.
    public init(maxBlurRadius: CGFloat) {
        self.filter = Self.makeVariableBlurFilter()
        setMaxBlurRadius(to: maxBlurRadius)
    }

    /// Updates the max blur radius of the variable blur effect and automatically triggers a re-render of the associated view.
    /// - Parameter radius: The max blur radius of the variable blur effect.
    public func setMaxBlurRadius(to radius: CGFloat) {
        guard maxBlurRadius != radius else { return }
        filter?.setValue(radius, forKey: "inputRadius")
    }

    /// Updates the mask image of the variable blur effect and automatically triggers a re-render of the associated view.
    /// - Parameter image: The image to use as the mask for this variable blur effect.
    public func setMaskImage(to image: CGImage) {
        guard maskImage != image else { return }
        filter?.setValue(image, forKey: "inputMaskImage")
    }

    private static func makeVariableBlurFilter() -> NSObject? {
        let filterWithTypeSelector = Selector(("filterWithType:"))

        guard
            let caFilterClass = NSClassFromString("CAFilter") as AnyObject as? NSObject,
            caFilterClass.responds(to: filterWithTypeSelector),
            let variableBlur = caFilterClass
            .perform(filterWithTypeSelector, with: "variableBlur")
            .takeUnretainedValue() as? NSObject
        else {
            return nil
        }

        variableBlur.setValue(true, forKey: "inputNormalizeEdges")
        return variableBlur
    }
}
