//
//  HazeEffect.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-05.
//

import SwiftUI

/// A protocol to ensure that both the iOS/macOS versions of `HazeEffect` provide the same API.
@MainActor
public protocol HazeEffectProtocol {
    associatedtype Provider: MaskProvider

    /// Initializes a new `HazeEffect`.
    /// - Parameters:
    ///   - maskProvider: The type of mask to use for the variable blur effect.
    ///   - maxBlurRadius: The maximum blur radius to apply.
    ///   - scale: The scale factor used when rendering the mask image. Lower values can improve performance at the cost of quality.
    init(
        maskProvider: Provider,
        maxBlurRadius: CGFloat,
        scale: CGFloat
    )
}

#if os(iOS)
/// A SwiftUI API for `UIHazeEffectView`.
@MainActor
public struct HazeEffect<Provider>: UIViewRepresentable, HazeEffectProtocol where Provider: MaskProvider {
    /// The type of mask to use for the variable blur effect.
    private let maskProvider: Provider

    /// The maximum blur radius to apply.
    private let maxBlurRadius: CGFloat

    /// The scale factor used when rendering the mask image.
    /// Lower values can improve performance at the cost of quality.
    private let scale: CGFloat

    public init(
        maskProvider: Provider,
        maxBlurRadius: CGFloat,
        scale: CGFloat = 0.5
    ) {
        self.maskProvider = maskProvider
        self.maxBlurRadius = maxBlurRadius
        self.scale = scale
    }

    public func makeUIView(
        context _: Context
    ) -> UIHazeEffectView<Provider> {
        let view = UIHazeEffectView(
            maskProvider: maskProvider,
            variableBlur: VariableBlurEngine(maxBlurRadius: maxBlurRadius),
            scale: scale
        )
        return view
    }

    public func updateUIView(
        _ view: UIHazeEffectView<Provider>,
        context _: Context
    ) {
        view.setMaskProvider(to: maskProvider)
        view.variableBlur.setMaxBlurRadius(to: maxBlurRadius)
        view.setScale(to: scale)
        view.renderFilter()
    }
}
#else
/// A SwiftUI API for `NSHazeEffectView`.
public struct HazeEffect<Provider>: NSViewRepresentable, HazeEffectProtocol where Provider: MaskProvider {
    /// The type of mask to use for the variable blur effect.
    private let maskProvider: Provider

    /// The maximum blur radius to apply.
    private let maxBlurRadius: CGFloat

    /// The scale factor used when rendering the mask image.
    /// Lower values can improve performance at the cost of quality.
    private let scale: CGFloat

    public init(
        maskProvider: Provider,
        maxBlurRadius: CGFloat,
        scale: CGFloat = 0.5
    ) {
        self.maskProvider = maskProvider
        self.maxBlurRadius = maxBlurRadius
        self.scale = scale
    }

    public func makeNSView(
        context _: Context
    ) -> NSHazeEffectView<Provider> {
        let view = NSHazeEffectView(
            maskProvider: maskProvider,
            variableBlur: VariableBlurEngine(maxBlurRadius: maxBlurRadius),
            scale: scale
        )
        return view
    }

    public func updateNSView(
        _ view: NSHazeEffectView<Provider>,
        context _: Context
    ) {
        view.setMaskProvider(to: maskProvider)
        view.variableBlur.setMaxBlurRadius(to: maxBlurRadius)
        view.setScale(to: scale)
        view.renderFilter()
    }
}
#endif

// MARK: - Previews

#if DEBUG
private struct GridView: View {
    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 18) {
                ForEach(0 ..< 30, id: \.self) { _ in
                    Color.white
                        .frame(height: 1.5)
                }
            }

            HStack(spacing: 18) {
                ForEach(0 ..< 30, id: \.self) { _ in
                    Color.white
                        .frame(width: 1.5)
                }
            }
        }
    }
}

#Preview("Smooth Linear Gradient Mask") {
    GridView()
        .frame(width: 400, height: 400)
        .overlay {
            HazeEffect(
                maskProvider: LinearGradientMaskProvider(
                    startPoint: .top,
                    endPoint: .bottom,
                    startOpacity: 0.0,
                    endOpacity: 1.0,
                    isSmooth: true
                ),
                maxBlurRadius: 5
            )
        }
}

#Preview("Rounded Rectangle Mask") {
    GridView()
        .frame(width: 400, height: 400)
        .overlay {
            HazeEffect(
                maskProvider: RoundedRectangleMaskProvider(
                    cornerRadius: 24,
                    blurRadius: 10
                ),
                maxBlurRadius: 3
            )
        }
}

#Preview("Rounded Rectangle Mask (Inverted Alpha)") {
    GridView()
        .frame(width: 400, height: 400)
        .overlay {
            HazeEffect(
                maskProvider: RoundedRectangleMaskProvider(
                    cornerRadius: 48,
                    blurRadius: 12,
                    featherEdges: .all,
                    invertAlpha: true
                ),
                maxBlurRadius: 3
            )
        }
}

#Preview("Rounded Rectangle Mask (Bottom, Leading & Trailing)") {
    GridView()
        .frame(width: 400, height: 400)
        .overlay {
            HazeEffect(
                maskProvider: RoundedRectangleMaskProvider(
                    cornerRadius: 24,
                    blurRadius: 10,
                    featherEdges: [.bottom, .leading, .trailing]
                ),
                maxBlurRadius: 3
            )
        }
}

#Preview("Elliptic Mask") {
    GridView()
        .frame(width: 400, height: 400)
        .overlay {
            HazeEffect(
                maskProvider: EllipticMaskProvider(
                    blurRadius: 8
                ),
                maxBlurRadius: 3
            )
        }
}

#if os(macOS)
#Preview("Image Mask") {
    GridView()
        .frame(width: 400, height: 400)
        .overlay {
            HazeEffect(
                maskProvider: ImageMaskProvider(
                    image: NSImage(named: NSImage.fontPanelName)!,
                    contentMode: .fit
                ),
                maxBlurRadius: 3
            )
        }
}

#Preview("Image Mask (Grayscale as alpha)") {
    GridView()
        .frame(width: 400, height: 400)
        .overlay {
            HazeEffect(
                maskProvider: ImageMaskProvider(
                    image: NSImage(named: NSImage.infoName)!,
                    contentMode: .fit,
                    useGrayscaleAsAlpha: true
                ),
                maxBlurRadius: 3
            )
        }
}
#endif
#endif
