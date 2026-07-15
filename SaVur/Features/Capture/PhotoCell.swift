import SwiftUI

/// One photo in the weekly strip. Rounded Retro-style card.
struct PhotoCell: View {
    let photo: FoodPhoto

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Theme.inkSoft.opacity(0.15)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(Theme.inkSoft)
                    }
            }
        }
        .frame(width: Theme.stripPhotoSize.width, height: Theme.stripPhotoSize.height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(Theme.ink.opacity(0.08), lineWidth: 1)
        }
        .task(id: photo.fileName) {
            image = await PhotoStore.shared.loadImage(for: photo.fileName)
        }
    }
}
