# Demo guide

[Documentation index](README.md) · [Repository overview](../README.md#demo)

The supplied final presentation contains two embedded screen recordings. Repository screenshots and excerpts come from those recordings or screenshots already included in the slides.

| Excerpt | Content | Duration |
| --- | --- | ---: |
| [Complete iOS film](assets/foodshutter-film.mp4) | Full sign-in, onboarding, capture, analysis and recommendation demonstration, with original audio | About 60 seconds |
| [Complete web walkthrough](assets/web-walkthrough.mp4) | Full web recording, with original audio | About 35 seconds |
| [Looping iOS preview](assets/foodshutter-preview.webp) | Complete silent recording at two-thirds speed, automatic infinite loop | About 90 seconds |
| [iOS demo](assets/ios-demo.mp4) | Capture, analysis, nutrition and dish ingredients | 22 seconds |
| [Web demo](assets/web-demo.mp4) | Statistics and appearance/settings views | 14 seconds |

The complete H.264 recordings retain the full recording duration and content, including audio. They were transcoded to approximately 5.9 MB and 0.9 MB respectively. The earlier silent excerpts remain available. The overview pages also embed the full iOS recording using a GitHub video attachment.

## Inline playback

The README shows a centered, automatically looping WebP preview of the complete iOS recording. A static screenshot replaces it for readers who request reduced motion. Expand the centered GitHub-hosted player below it for the full video with audio; the web player remains in the web companion section. The same compressed videos are tracked in the repository for portability. [The media manifest](assets/media-manifest.json) records their checksums and source slide.

The animated WebP is encoded directly from the original 886×1920 recording at 600 pixels wide, using quality 88. The README displays it at 360 pixels wide to retain more detail on higher-density screens. It samples 12 frames per original second and stretches timestamps by 1.5, giving approximately 8 frames per playback second and a 90-second loop. It preserves the full sequence without cuts and has no audio. The original-speed video with audio remains available below it.

To regenerate it with FFmpeg, extract `ppt/media/media1.mp4` from the supplied presentation, then run the command from the repository root, replacing the input path with the extracted file's location:

```bash
ffmpeg -i /path/to/media1.mp4 -vf "fps=12,scale=600:-2:flags=lanczos,setpts=1.5*(PTS-STARTPTS)" -fps_mode vfr -c:v libwebp_anim -quality 88 -compression_level 6 -an -loop 0 -map_metadata -1 -y docs/assets/foodshutter-preview.webp
```

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
| `foodshutter-film.mp4` | Complete slide 52 `media1.mp4`, approximately 60.23 seconds |
| `foodshutter-preview.webp` | Complete slide 52 `media1.mp4`, directly encoded from the original recording at 600-pixel width, silent infinite loop at two-thirds speed |
| `web-walkthrough.mp4` | Complete slide 67 `media2.mp4`, approximately 34.92 seconds |
| `ios-capture.png` | Slide 52, `media1.mp4`, 22 seconds |
| `ios-nutrition.png` | Slide 52, `media1.mp4`, 32 seconds |
| `ios-ingredients.png` | Slide 52, `media1.mp4`, 38 seconds |
| `ios-demo.mp4` | Slide 52, `media1.mp4`, seconds 20–42 |
| `web-statistics.png` | Slide 68, embedded `image24.png` |
| `web-demo.mp4` | Slide 67, `media2.mp4`, seconds 20–34 |
| Architecture and pipeline SVGs | Diagrams derived from current source, with editable draw.io sources |

Complete recordings were resized, transcoded and stripped of embedded metadata, with their original audio retained. Earlier short excerpts are silent. Extracted frames were resized without changing the displayed application content. The full PPT and original high-bitrate files remain outside Git.

To repeat the demonstration, configure your own services, sign in, create a profile, capture a sample meal and review it on both clients. See [capability status](architecture.md#capability-status) and [deployment requirements](deployment.md) for differences between the recorded build and current source.
