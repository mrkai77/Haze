# ``Haze``

Haze provides you with the ability to create fully custom variable blur effects in SwiftUI, UIKit and AppKit.
Powered by `CAFilter`, Haze is very performant.
What makes Haze unique is that it's fully customizable, as you'll see below.
Linear variable blurs are just the beginning when it comes to variable blur effects, so I hope you enjoy using this package as much as I have :)

## Usage

The examples below focus on SwiftUI implementations, but equivalent UIKit/AppKit alternatives are available and actually power the SwiftUI views behind the scenes.
Haze internally uses masking to tell the underlying `CAFilter` exactly where to apply different blur intensities - from full blur to semi-blur to complete pass-through. 
Creating these masks from scratch can be complex, so Haze includes several ready-to-use presets to help you get started immediately:

### Linear Gradient Mask

![Linear Gradient Mask](linear_gradient_mask)

```swift
SomeView()
    .overlay {
        HazeEffect(
            maskProvider: LinearGradientMaskProvider(
                startPoint: .top,
                endPoint: .bottom,
                startOpacity: 0.0,
                endOpacity: 1.0
            ),
            maxBlurRadius: 5
        )
    }
```

### Rounded Rectangle Mask

![Rounded Rectangle Mask](rounded_rectangle_mask)

```swift
SomeView()
    .overlay {
        HazeEffect(
            maskProvider: RoundedRectangleMaskProvider(
                cornerRadius: 24,
                blurRadius: 10 // <- This blur radius affects the mask, not the variable blur effect
            ),
            maxBlurRadius: 5
        )
    }
```

You can choose which edges to feather/transition. For example, to blur everything except the top edge:

![Rounded Rectangle Mask (no top edge)](rounded_rectangle_no_top_edge_mask)

```swift
SomeView()
    .overlay {
        HazeEffect(
            maskProvider: RoundedRectangleMaskProvider(
                cornerRadius: 24,
                blurRadius: 10,
                featherEdges: [.bottom, .leading, .trailing] // <- Excludes the top, so it will be fully blurred.
            ),
            maxBlurRadius: 5
        )
    }
```

To blur the outer edges instead of the inside, invert the mask:

![Rounded Rectangle Mask (inverted)](rounded_rectangle_inverted_mask)

```swift
SomeView()
    .overlay {
        HazeEffect(
            maskProvider: RoundedRectangleMaskProvider(
                cornerRadius: 48,
                blurRadius: 12,
                invertAlpha: true // <- Sets the outer edges to blur out.
            ),
            maxBlurRadius: 5
        )
    }
```

### Elliptic Mask

![Elliptic Mask](elliptic_mask)

```swift
SomeView()
    .overlay {
        HazeEffect(
            maskProvider: EllipticMaskProvider(
                blurRadius: 8
            ),
            maxBlurRadius: 5
        )
    }
```

### Image Mask

![Image Mask](image_mask)

```swift
SomeView()
    .overlay {
        HazeEffect(
            maskProvider: ImageMaskProvider(
                image: UIImage(named: "Mask"), // <- This will be a UIImage on iOS, NSImage on macOS.
                contentMode: .fit
            ),
            maxBlurRadius: 5
        )
    }
```

By default, ImageMaskProvider uses the alpha channel of the image as the mask.
If you prefer to use a grayscale spectrum (e.g. a heightmap‑style mask), set: `useGrayscaleAsAlpha: true`.

## Topics

### Mask Providers

- ``LinearGradientMaskProvider``
- ``RoundedRectangleMaskProvider``
- ``EllipticMaskProvider``
- ``ImageMaskProvider``

### Views

- ``HazeEffect``
- ``UIHazeEffectView``
- ``NSHazeEffectView``

### Other

- ``VariableBlurEngine``
