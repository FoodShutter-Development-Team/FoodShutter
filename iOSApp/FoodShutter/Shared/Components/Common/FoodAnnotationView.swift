//
//  FoodAnnotationView.swift
//  FoodShutter
//

import SwiftUI

struct FoodAnnotationView: View {
    let image: UIImage
    let dishes: [Dish]

    // Cache the normalized image so it isn't recomputed on every render.
    private let normalizedImage: UIImage

    init(image: UIImage, dishes: [Dish]) {
        self.image = image
        self.dishes = dishes
        self.normalizedImage = image.normalizedOrientation()
    }

    var body: some View {
        GeometryReader { geo in
            let rects = computeRects(in: geo.size)
            ZStack(alignment: .topLeading) {
                Image(uiImage: normalizedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                ForEach(rects, id: \.id) { item in
                    BBoxOverlay(dish: item.dish, rect: item.rect)
                }
            }
        }
    }

    // MARK: - Layout helpers

    private struct AnnotatedDish: Identifiable {
        let id: UUID
        let dish: Dish
        let rect: CGRect
    }

    private func computeRects(in size: CGSize) -> [AnnotatedDish] {
        let imgSize = normalizedImage.size
        guard imgSize.width > 0, imgSize.height > 0 else { return [] }

        let scale  = min(size.width / imgSize.width, size.height / imgSize.height)
        let drawW  = imgSize.width  * scale
        let drawH  = imgSize.height * scale
        let offsetX = (size.width  - drawW) / 2
        let offsetY = (size.height - drawH) / 2

        return dishes.compactMap { dish in
            guard let b = dish.bbox, b.count == 4 else { return nil }
            let rect = CGRect(
                x:      offsetX + b[0] * drawW,
                y:      offsetY + b[1] * drawH,
                width:  (b[2] - b[0]) * drawW,
                height: (b[3] - b[1]) * drawH
            )
            return AnnotatedDish(id: dish.id, dish: dish, rect: rect)
        }
    }
}

// MARK: - Single bbox + icon

private struct BBoxOverlay: View {
    let dish: Dish
    let rect: CGRect

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.mainEnable.opacity(0.9), lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

            Text(String(dish.icon.prefix(1)))
                .font(.system(size: 16))
                .padding(4)
                .background(Circle().fill(.ultraThinMaterial))
                .position(x: rect.minX + 16, y: rect.minY + 16)
        }
    }
}
