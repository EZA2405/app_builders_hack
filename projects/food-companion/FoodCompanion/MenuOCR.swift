import Foundation
import ImageIO
import Vision

enum MenuOCR {
    static func recognize(_ data: Data) throws -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ScanError.unreadableImage
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let rawOrientation = (properties?[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: rawOrientation) ?? .up
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: image, orientation: orientation).perform([request])
        var lines = (request.results ?? []).compactMap { observation in
            observation.topCandidates(1).first.map { (text: $0.string, bounds: observation.boundingBox) }
        }
        let pricePattern = #"^(?:₱\s*|PHP\s*)?\d[\d,.]*$"#
        // shortcut: rejoin standalone peso-style prices only; complex layouts need confirmed menu items.
        for index in lines.indices where lines[index].text.range(of: pricePattern, options: .regularExpression) != nil {
            let priceBounds = lines[index].bounds
            let neighbor = lines.indices.filter { candidate in
                let bounds = lines[candidate].bounds
                return !lines[candidate].text.isEmpty
                    && lines[candidate].text.range(of: pricePattern, options: .regularExpression) == nil
                    && bounds.maxX < priceBounds.minX
                    && abs(bounds.midY - priceBounds.midY) < min(bounds.height, priceBounds.height) / 2
            }.max { lines[$0].bounds.maxX < lines[$1].bounds.maxX }
            if let neighbor {
                lines[neighbor].text += " " + lines[index].text
                lines[index].text = ""
            }
        }
        let text = lines.map(\.text).filter { !$0.isEmpty }.joined(separator: "\n")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScanError.noText
        }
        return text
    }

    enum ScanError: LocalizedError {
        case unreadableImage
        case noText

        var errorDescription: String? {
            switch self {
            case .unreadableImage: "This photo could not be opened. Try another image."
            case .noText: "No text was found. Try a closer, sharper photo of the menu."
            }
        }
    }
}
