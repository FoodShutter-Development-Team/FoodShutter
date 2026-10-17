# README visual design

The repository's SVG assets follow the native iOS application's palette and serif typography. The personal profile at [tingyangxie](https://github.com/tingyangxie) was inspected as a read-only reference for self-contained SVG and animation techniques. Its colors, handwritten type and retro windows are not the FoodShutter visual system.

## Source palette

Source: [`Color+Custom.swift`](../../iOSApp/FoodShutter/Shared/Extensions/Color+Custom.swift).

| Token | Color | Use |
| --- | --- | --- |
| `backGround` | `#FAFAF0` | Cream background |
| `backGroundDark` | `#F0EEE7` | Secondary surface |
| `mainText` | `#3D3D3A` | Text |
| `mainEnable` | `#D2785A` | Interaction and motion accent |
| `userEnable` | `#50589C` | Profile selection in the application |
| `protein` | `#7B9FAD` | Protein and model-related diagram accents |
| `fat` | `#C9A96E` | Fat segment of the nutrition ring |
| `carbohydrate` | `#8B9A7E` | Carbohydrate and data-related diagram accents |

The SwiftUI views use system serif text. SVG headings use Georgia with Times New Roman and generic serif fallback. Chinese assets additionally prefer a CJK serif fallback. No font files are redistributed or requested from a remote font service.

## Composition and motion

The README begins with the original app icon, a plain product title, description and text navigation. The generator retains optional cover and navigation assets from the earlier presentation, but the README does not embed them. The architecture and pipeline diagrams keep labels stationary and animate small markers along existing connectors. They illustrate data flow rather than actual service activity.

Diagram animation is contained in SVG image assets. `prefers-reduced-motion: reduce` hides the animated overlays while retaining the complete static design. The centered animated WebP preview loops the full recording silently at two-thirds speed, with a 600-pixel source displayed at 360-pixel width for sharper detail; a `<picture>` source selects a static nutrition screenshot when reduced motion is requested. The original-speed video players are centered inside expandable sections. Navigation uses ordinary Markdown/HTML links; no scripts, tracking or external animation service is used.

GitHub strips README inline styles, so the native prose retains the reader's GitHub font and theme. The section headings, footer and diagrams carry the application's visual styling. Body text remains selectable and readable instead of being converted to an image.

## Regenerate

From the repository root:

```bash
python docs/design/build_assets.py
```

The generator uses the Python standard library only. It produces SVGs and native draw.io sources. The diagram SVGs embed their diagram XML; no remote resources are needed to render them.

After regeneration, verify both README languages, dark-theme contrast, narrow viewports, reduced-motion behavior and native video playback on GitHub. The full media files are transcoded originals with their audio preserved, rather than generated promotional footage.
