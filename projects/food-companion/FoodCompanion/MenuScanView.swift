import PhotosUI
import SwiftUI

struct MenuScanView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var menuImage: UIImage?
    @State private var menuText = ""
    @State private var isScanning = false
    @State private var errorMessage: String?

    @FocusState private var isEditing: Bool
    private let accent = Color(red: 0.72, green: 0.28, blue: 0.13)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if let menuImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Let's read the menu.")
                                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                            Text("Check the details. A good choice starts here.")
                                .foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Label("YOUR MENU", systemImage: "photo")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Image(uiImage: menuImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .accessibilityLabel("Original menu photo. Compare it with the extracted text below.")
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Make it yours")
                                    .font(.system(.title2, design: .serif).weight(.semibold))
                                Spacer()
                                Image(systemName: "pencil.line")
                                    .foregroundStyle(accent)
                                    .accessibilityHidden(true)
                            }
                            Text("Tap to correct names, descriptions, and prices before choosing a dish.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $menuText)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 280)
                                .focused($isEditing)
                                .disabled(isScanning)
                                .accessibilityLabel("Editable menu text")
                                .accessibilityIdentifier("menuText")
                        }
                        .padding(20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Good food.\nLess guesswork.")
                                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text("A little help with a big menu.\nChoose a photo to get started.")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        menuBuddy
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Bring the menu into focus", systemImage: "viewfinder")
                                .font(.headline)
                            Text("Fill the photo with the menu and avoid glare. For small print, try one column at a time.")
                                .foregroundStyle(.secondary)
                            Divider()
                            Label("Your photos stay on your iPhone", systemImage: "lock.shield")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background {
                ZStack {
                    Color(uiColor: .systemGroupedBackground)
                    RadialGradient(colors: [accent.opacity(0.13), .clear], center: .topLeading, startRadius: 0, endRadius: 500)
                }
                .ignoresSafeArea()
            }
            .safeAreaInset(edge: .bottom) {
                if !isEditing {
                    importControl
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("Food Companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isEditing = false }
                }
            }
            .tint(accent)
            .task(id: selectedPhoto) {
                guard let selectedPhoto else { return }
                isScanning = true
                defer { isScanning = false; self.selectedPhoto = nil }
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

    @ViewBuilder
    private var importControl: some View {
        if #available(iOS 26, *) {
            photoPicker.buttonStyle(.glassProminent)
        } else {
            photoPicker.buttonStyle(.borderedProminent)
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            HStack(spacing: 10) {
                if isScanning {
                    ProgressView().tint(.white)
                    Text(dynamicTypeSize.isAccessibilitySize ? "Reading…" : "Reading your menu…")
                } else {
                    if !dynamicTypeSize.isAccessibilitySize {
                        Image(systemName: "photo.badge.plus")
                    }
                    Text(dynamicTypeSize.isAccessibilitySize ? "Choose photo" : (menuImage == nil ? "Choose a menu photo" : "Scan another menu"))
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonBorderShape(.capsule)
        .disabled(isScanning)
        .accessibilityIdentifier("chooseMenuPhoto")
    }

    private var menuBuddy: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.08))
                .frame(width: 220, height: 220)
            Image(systemName: "leaf.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
                .rotationEffect(.degrees(-30))
                .offset(x: 30, y: -70)
            RoundedRectangle(cornerRadius: 60)
                .fill(Color.orange.gradient)
                .frame(width: 150, height: 130)
                .shadow(color: accent.opacity(0.18), radius: 16, y: 10)
            HStack(spacing: 34) {
                Capsule().frame(width: 7, height: 13)
                Capsule().frame(width: 7, height: 13)
            }
            .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05))
            .offset(y: -6)
            Circle().trim(from: 0, to: 0.5)
                .stroke(Color(red: 0.25, green: 0.12, blue: 0.05), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 22, height: 16)
                .offset(y: 15)
        }
        .accessibilityHidden(true)
    }

}
