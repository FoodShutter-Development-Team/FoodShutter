# Demo guide

[Documentation index](README.md) · [Repository overview](../README.md#demo)

The supplied final presentation contains two embedded screen recordings. Repository screenshots and excerpts come from those recordings or screenshots already included in the slides.

| Excerpt | Content | Duration |
| --- | --- | ---: |
| [iOS demo](assets/ios-demo.mp4) | Capture, analysis, nutrition and dish ingredients | 22 seconds |
| [Web demo](assets/web-demo.mp4) | Statistics and appearance/settings views | 14 seconds |

These silent H.264 MP4 excerpts total approximately 2.56 MB. If GitHub's file viewer does not play them, download and open them locally.

## Screens

| Capture | Meal nutrition | Ingredients |
| --- | --- | --- |
| ![Capture](assets/ios-capture.png) | ![Meal nutrition](assets/ios-nutrition.png) | ![Ingredients](assets/ios-ingredients.png) |

![Web statistics](assets/web-statistics.png)

Displayed nutrition values are estimates from the demonstrated build. The images are original application evidence, and do not establish current service availability.

## Asset provenance

Source deck: `FoodShutter_finalversion.pptx`, supplied in the course project folder. Numbers below refer to the actual order in the 87-slide deck.

| Asset | Source |
| --- | --- |
| `ios-capture.png` | Slide 52, `media1.mp4`, 22 seconds |
| `ios-nutrition.png` | Slide 52, `media1.mp4`, 32 seconds |
| `ios-ingredients.png` | Slide 52, `media1.mp4`, 38 seconds |
| `ios-demo.mp4` | Slide 52, `media1.mp4`, seconds 20–42 |
| `web-statistics.png` | Slide 68, embedded `image24.png` |
| `web-demo.mp4` | Slide 67, `media2.mp4`, seconds 20–34 |
| Architecture and pipeline SVGs | Diagrams derived from current source, with editable draw.io sources |

Videos were resized, transcoded, stripped of audio and stripped of embedded metadata. Extracted frames were resized without changing the displayed application content. The full PPT and original large videos remain outside Git.

To repeat the demonstration, configure your own services, sign in, create a profile, capture a sample meal and review it on both clients. See [capability status](architecture.md#capability-status) and [deployment requirements](deployment.md) for differences between the recorded build and current source.
