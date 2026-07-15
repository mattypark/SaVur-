import SwiftUI
import SwiftData

/// Stage 1 stub. Stage 3 rebuilds this against Matthew's Retro profile recordings —
/// the profile is the most important surface in the app.
struct ProfileView: View {
    @Query(sort: \FoodPhoto.capturedAt, order: .reverse) private var photos: [FoodPhoto]

    private let gridColumns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        identityHeader
                        statsRow
                        photoGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
    }

    private var identityHeader: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Theme.surface)
                .frame(width: 88, height: 88)
                .overlay {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Theme.inkSoft.opacity(0.5))
                }

            Text("Matthew")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)

            Text("@matthew")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    /// Friends count is a placeholder until the backend stage.
    private var statsRow: some View {
        HStack(spacing: 32) {
            stat(value: "\(photos.count)", label: "Photos")
            stat(value: "0", label: "Friends")
            stat(value: "\(Set(photos.map(\.weekStart)).count)", label: "Weeks")
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Theme.ink)

            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    @ViewBuilder
    private var photoGrid: some View {
        if photos.isEmpty {
            Text("Photos you add will build your journal here.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
                .padding(.top, 24)
        } else {
            LazyVGrid(columns: gridColumns, spacing: 4) {
                ForEach(photos) { photo in
                    GridPhoto(photo: photo)
                }
            }
        }
    }
}

/// Square grid thumbnail.
private struct GridPhoto: View {
    let photo: FoodPhoto

    @State private var image: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.inkSoft.opacity(0.1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .task(id: photo.fileName) {
                image = await PhotoStore.shared.loadImage(for: photo.fileName)
            }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: FoodPhoto.self, inMemory: true)
}
