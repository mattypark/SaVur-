import SwiftUI
import SwiftData
import PhotosUI
import OSLog

/// Stage 1 core loop: import food photos from the roll (primary)
/// or shoot one on the spot with the + camera button.
struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodPhoto.capturedAt, order: .reverse) private var photos: [FoodPhoto]

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isCameraPresented = false
    @State private var importErrorMessage: String?

    private var thisWeekPhotos: [FoodPhoto] {
        let currentWeek = FoodPhoto.weekStart(for: .now)
        return photos.filter { $0.weekStart == currentWeek }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.cream.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    header
                    weekStrip
                    Spacer()
                    importButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    cameraButton
                }
            }
            .safeAreaInset(edge: .bottom) {
                cameraFab
                    .padding(.bottom, 8)
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker { image in
                addPhoto(image, source: .camera)
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickerItems) {
            importPickedItems()
        }
        .alert(
            "Couldn't add photo",
            isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { if !$0 { importErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Placeholder wordmark until Matthew's iPad logo arrives.
            Text("SaVur")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)

            Text("Your organic week")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    @ViewBuilder
    private var weekStrip: some View {
        if thisWeekPhotos.isEmpty {
            emptyStrip
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(thisWeekPhotos) { photo in
                        PhotoCell(photo: photo)
                            .contextMenu {
                                Button(role: .destructive) {
                                    delete(photo)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    private var emptyStrip: some View {
        RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .strokeBorder(Theme.inkSoft.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
            .frame(height: Theme.stripPhotoSize.height)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "leaf")
                        .font(.title2)
                        .foregroundStyle(Theme.accentBlue)

                    Text("No food yet this week")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
    }

    private var importButton: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: 10,
            matching: .images
        ) {
            Label("Add from your photos", systemImage: "photo.on.rectangle.angled")
                .font(.headline)
                .foregroundStyle(Theme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    /// Top-left camera entry point (Matthew asked for top-left OR bottom-center — both ship, same action).
    private var cameraButton: some View {
        Button {
            isCameraPresented = true
        } label: {
            Image(systemName: "plus")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
        }
        .disabled(!CameraPicker.isCameraAvailable)
    }

    /// Bottom-center + button for shooting food on the spot.
    private var cameraFab: some View {
        Button {
            isCameraPresented = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.cream)
                .frame(width: 60, height: 60)
                .background(Theme.accentRed, in: Circle())
                .shadow(color: Theme.ink.opacity(0.25), radius: 10, y: 4)
        }
        .disabled(!CameraPicker.isCameraAvailable)
        .opacity(CameraPicker.isCameraAvailable ? 1 : 0.4)
    }

    // MARK: - Actions

    private func addPhoto(_ image: UIImage, source: FoodPhoto.Source) {
        let id = UUID()
        do {
            let fileName = try PhotoStore.shared.save(image, id: id)
            let photo = FoodPhoto(id: id, fileName: fileName, source: source)
            modelContext.insert(photo)
        } catch {
            importErrorMessage = "That photo couldn't be saved. Try again."
        }
    }

    private func importPickedItems() {
        guard !pickerItems.isEmpty else { return }
        let items = pickerItems
        pickerItems = []

        // Explicit main-actor hop: modelContext + @State writes must stay on main.
        Task { @MainActor in
            for item in items {
                do {
                    guard
                        let data = try await item.loadTransferable(type: Data.self),
                        let image = UIImage(data: data)
                    else {
                        importErrorMessage = "One of the photos couldn't be imported."
                        continue
                    }
                    addPhoto(image, source: .library)
                } catch {
                    Logger.photoImport.error("Photo import failed: \(error, privacy: .public)")
                    importErrorMessage = "One of the photos couldn't be imported."
                }
            }
        }
    }

    private func delete(_ photo: FoodPhoto) {
        PhotoStore.shared.delete(photo.fileName)
        modelContext.delete(photo)
    }
}

private extension Logger {
    static let photoImport = Logger(subsystem: "com.matthewpark.SaVur", category: "photo-import")
}

#Preview {
    CaptureView()
        .modelContainer(for: FoodPhoto.self, inMemory: true)
}
