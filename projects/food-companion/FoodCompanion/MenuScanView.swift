import PhotosUI
import SwiftUI

struct MenuScanView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var menuImage: UIImage?
    @State private var menuText = ""
    @State private var isScanning = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("What looks good?")
                        .font(.largeTitle.bold())
                    Text("Start with a menu photo. Read and correct the text before choosing a dish.")
                        .foregroundStyle(.secondary)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(menuImage == nil ? "Choose a menu photo" : "Choose another menu", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isScanning)
                    .accessibilityIdentifier("chooseMenuPhoto")

                    if isScanning {
                        ProgressView("Reading your menu…")
                            .accessibilityIdentifier("scanProgress")
                    }

                    if let menuImage {
                        Image(uiImage: menuImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Original menu photo. Compare it with the extracted text below.")

                        Text("Check your menu")
                            .font(.headline)
                        Text("Correct dish names, descriptions, and prices. Columns may be read in the wrong order.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $menuText)
                            .frame(minHeight: 260)
                            .padding(8)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                            .disabled(isScanning)
                            .accessibilityLabel("Editable menu text")
                            .accessibilityIdentifier("menuText")
                    } else if !isScanning {
                        ContentUnavailableView("Your menu starts here", systemImage: "fork.knife", description: Text("Take a clear photo with Camera, then choose it from your library."))
                    }

                    Label("Text recognition runs on your iPhone.", systemImage: "iphone")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Food Companion")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: selectedPhoto) {
                guard let selectedPhoto else { return }
                isScanning = true
                defer { isScanning = false }
                do {
                    guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        throw MenuOCR.ScanError.unreadableImage
                    }
                    let text = try await Task.detached(priority: .userInitiated) {
                        try MenuOCR.recognize(data)
                    }.value
                    try Task.checkCancellation()
                    menuImage = image
                    menuText = text
                } catch is CancellationError {
                    // A cancelled import must not replace the current scan.
                } catch {
                    guard !Task.isCancelled else { return }
                    errorMessage = error.localizedDescription
                }
            }
            .alert("Couldn’t read this menu", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Try another photo.")
            }
        }
    }
}
