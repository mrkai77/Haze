//
//  HazeEffect.swift
//  Haze
//
//  Created by Kai Azim on 2025-11-05.
//

import SwiftUI

#if os(iOS)
public typealias PlatformViewRepresentable = UIViewRepresentable
#elseif os(macOS)
public typealias PlatformViewRepresentable = NSViewRepresentable
#endif

public struct HazeEffect<Provider>: PlatformViewRepresentable where Provider: MaskProvider {
    /// The type of mask to use for the variable blur effect.
    private let maskProvider: Provider

    /// The maximum blur radius to apply.
    private let maxBlurRadius: CGFloat

    /// The scale factor used when rendering the mask image.
    /// Lower values can improve performance at the cost of quality.
    private let scale: CGFloat

    /// Initializes a new `HazeEffect`.
    /// - Parameters:
    ///   - maskProvider: The type of mask to use for the variable blur effect.
    ///   - maxBlurRadius: The maximum blur radius to apply.
    ///   - scale: The scale factor used when rendering the mask image. Lower values can improve performance at the cost of quality.
    public init(
        maskProvider: Provider,
        maxBlurRadius: CGFloat,
        scale: CGFloat = 0.5
    ) {
        self.maskProvider = maskProvider
        self.maxBlurRadius = maxBlurRadius
        self.scale = scale
    }

    #if os(iOS)
    public func makeUIView(context _: Context) -> HazeEffectView<Provider> { makeView() }
    public func updateUIView(_ view: HazeEffectView<Provider>, context: Context) { updateView(view, context) }
    #elseif os(macOS)
    public func makeNSView(context _: Context) -> HazeEffectView<Provider> { makeView() }
    public func updateNSView(_ view: HazeEffectView<Provider>, context: Context) { updateView(view, context) }
    #endif

    private func makeView() -> HazeEffectView<Provider> {
        HazeEffectView(
            maskProvider: maskProvider,
            variableBlur: VariableBlurEngine(maxBlurRadius: maxBlurRadius),
            scale: scale
        )
    }

    private func updateView(_ view: HazeEffectView<Provider>, _: Context) {
        view.setMaskProvider(to: maskProvider)
        view.variableBlur.setMaxBlurRadius(to: maxBlurRadius)
        view.setScale(to: scale)
        view.renderFilter()
    }
}

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

#Preview("Rounded Rectangle Mask (Inverted Alpha & padding)") {
    GridView()
        .frame(width: 400, height: 400)
        .overlay {
            HazeEffect(
                maskProvider: RoundedRectangleMaskProvider(
                    cornerRadius: 48,
                    blurRadius: 12,
                    edgeConfigurations: [
                        .top: .init(feathered: true, padding: .percentage(0.25)),
                        .bottom: .init(feathered: true, padding: .percentage(0.25)),
                        .leading: .init(feathered: true),
                        .trailing: .init(feathered: true)
                    ],
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
