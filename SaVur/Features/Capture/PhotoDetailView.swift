import SwiftUI
import SwiftData

/// Full-screen pager over one week's photos, with delete.
struct PhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var photos: [FoodPhoto]
    @State private var selection: UUID

    init(weekPhotos: [FoodPhoto], initial: FoodPhoto) {
        _photos = State(initialValue: weekPhotos)
        _selection = State(initialValue: initial.id)
    }

    private var currentPhoto: FoodPhoto? {
        photos.first { $0.id == selection }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.cream.ignoresSafeArea()

                TabView(selection: $selection) {
                    ForEach(photos) { photo in
                        PhotoPage(photo: photo)
                            .tag(photo.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                    }
                }

                ToolbarItem(placement: .principal) {
                    if let currentPhoto {
                        Text(currentPhoto.capturedAt.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        deleteCurrent()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Theme.accentRed)
                    }
                }
            }
            .toolbarBackground(Theme.cream, for: .navigationBar)
        }
    }

    private func deleteCurrent() {
        guard let photo = currentPhoto, let index = photos.firstIndex(of: photo) else { return }

        PhotoStore.shared.delete(photo.fileName)
        modelContext.delete(photo)
        photos.remove(at: index)

        guard !photos.isEmpty else {
            dismiss()
            return
        }
        selection = photos[min(index, photos.count - 1)].id
    }
}

/// One zoom-free page: the photo on a cream mat.
private struct PhotoPage: View {
    let photo: FoodPhoto

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .padding(16)
            } else {
                ProgressView()
                    .tint(Theme.inkSoft)
            }
        }
        .task(id: photo.fileName) {
            image = await PhotoStore.shared.loadImage(for: photo.fileName)
        }
    }
}
