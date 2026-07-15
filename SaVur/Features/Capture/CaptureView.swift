import SwiftUI
import SwiftData
import PhotosUI
import OSLog

/// The journal: this week's filmstrip up top, past weeks below.
/// Import from the roll (primary, EXIF-backfilled) or shoot with the + camera.
struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodPhoto.capturedAt, order: .reverse) private var photos: [FoodPhoto]

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isCameraPresented = false
    @State private var importErrorMessage: String?
    @State private var detailPhoto: FoodPhoto?

    // MARK: - Week grouping

    private var weeks: [(weekStart: Date, photos: [FoodPhoto])] {
        Dictionary(grouping: photos, by: \.weekStart)
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value.sorted(by: FoodPhoto.inWeekOrder)) }
    }

    private var currentWeekStart: Date {
        FoodPhoto.weekStart(for: .now)
    }

    private var thisWeekPhotos: [FoodPhoto] {
        weeks.first { $0.weekStart == currentWeekStart }?.photos ?? []
    }

    private var pastWeeks: [(weekStart: Date, photos: [FoodPhoto])] {
        weeks.filter { $0.weekStart != currentWeekStart }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        thisWeekSection
                        pastWeeksSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    cameraButton
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker { image in
                addPhoto(image, source: .camera)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $detailPhoto) { photo in
            PhotoDetailView(
                weekPhotos: weeks.first { $0.weekStart == photo.weekStart }?.photos ?? [photo],
                initial: photo
            )
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
    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This week")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            if thisWeekPhotos.isEmpty {
                emptyStrip
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(thisWeekPhotos) { photo in
                            stripCell(for: photo)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }

    /// This-week cells are tappable, deletable, and drag-reorderable.
    private func stripCell(for photo: FoodPhoto) -> some View {
        PhotoCell(photo: photo)
            .onTapGesture {
                detailPhoto = photo
            }
            .contextMenu {
                Button(role: .destructive) {
                    delete(photo)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .draggable(photo.id.uuidString)
            .dropDestination(for: String.self) { droppedIDs, _ in
                handleDrop(droppedIDs, on: photo)
            }
    }

    @ViewBuilder
    private var pastWeeksSection: some View {
        ForEach(pastWeeks, id: \.weekStart) { week in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(FoodPhoto.weekTitle(for: week.weekStart))
                        .font(.headline)
                        .foregroundStyle(Theme.ink)

                    Text("\(week.photos.count)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(week.photos) { photo in
                            PhotoCell(photo: photo, size: Theme.pastStripPhotoSize)
                                .onTapGesture {
                                    detailPhoto = photo
                                }
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

    private var bottomBar: some View {
        VStack(spacing: 12) {
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
            .padding(.horizontal, 20)

            cameraFab
        }
        .padding(.bottom, 8)
        .background {
            LinearGradient(
                colors: [Theme.cream.opacity(0), Theme.cream, Theme.cream],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
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

    private func addPhoto(_ image: UIImage, source: FoodPhoto.Source, capturedAt: Date = .now) {
        let id = UUID()
        do {
            let fileName = try PhotoStore.shared.save(image, id: id)
            let photo = FoodPhoto(id: id, capturedAt: capturedAt, fileName: fileName, source: source)
            // Front of its week, without breaking any manual drag-order.
            let weekMates = photos.filter { $0.weekStart == photo.weekStart }
            photo.sortIndex = FoodPhoto.nextSortIndex(existingInWeek: weekMates)
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
                    // EXIF backfill: the photo joins the week it was taken.
                    let capturedAt = ImageMetadata.captureDate(from: data) ?? .now
                    addPhoto(image, source: .library, capturedAt: capturedAt)
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

    /// Drag reorder within this week: move dragged photo to the target's slot, reindex the week.
    private func handleDrop(_ droppedIDs: [String], on target: FoodPhoto) -> Bool {
        guard
            let idString = droppedIDs.first,
            let draggedID = UUID(uuidString: idString),
            draggedID != target.id
        else {
            return false
        }

        var week = thisWeekPhotos
        guard
            let fromIndex = week.firstIndex(where: { $0.id == draggedID }),
            let toIndex = week.firstIndex(where: { $0.id == target.id })
        else {
            return false
        }

        let moved = week.remove(at: fromIndex)
        week.insert(moved, at: toIndex)
        for (index, photo) in week.enumerated() {
            photo.sortIndex = index
        }
        return true
    }
}

private extension Logger {
    static let photoImport = Logger(subsystem: "com.matthewpark.SaVur", category: "photo-import")
}

#Preview {
    CaptureView()
        .modelContainer(for: FoodPhoto.self, inMemory: true)
}
