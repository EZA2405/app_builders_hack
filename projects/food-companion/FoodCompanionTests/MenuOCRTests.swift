import XCTest
import ImageIO
import UniformTypeIdentifiers
@testable import FoodCompanion

final class MenuOCRTests: XCTestCase {
    func testSingleColumnMenuPreservesDishNamesAndPrices() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(
            forResource: "single-column", withExtension: "png", subdirectory: "Fixtures"
        ))
        let text = try MenuOCR.recognize(Data(contentsOf: url))
        XCTAssertTrue(text.contains("Chicken Adobo"), text)
        XCTAssertTrue(text.contains("180"), text)
        XCTAssertTrue(text.contains("Sinigang"), text)
        XCTAssertTrue(text.contains("220"), text)
    }

    func testRepresentativeMenusKeepDishNamesWithTheirPrices() throws {
        let menus: [(String, [(String, String)])] = [
            ("multi-column", [("Chicken Adobo", "180"), ("Sinigang", "220"), ("Garlic Rice", "50"), ("Lumpia", "90")]),
            ("low-contrast", [("Chicken Adobo", "180"), ("Sinigang", "220")]),
            ("filipino", [("Kare-Kare", "280"), ("Pancit Canton", "150"), ("Halo-Halo", "120")]),
            ("decorative", [("Chicken Adobo", "180"), ("Sinigang", "220")])
        ]
        for (name, dishes) in menus {
            let url = try XCTUnwrap(Bundle(for: Self.self).url(
                forResource: name, withExtension: "png", subdirectory: "Fixtures"
            ))
            let start = Date()
            let text = try MenuOCR.recognize(Data(contentsOf: url))
            print("Synthetic menu \(name): \(Date().timeIntervalSince(start)) seconds\n\(text)")
            let lines = text.components(separatedBy: .newlines)
            for (dish, price) in dishes {
                XCTAssertTrue(lines.contains { $0.contains(dish) && $0.contains(price) }, "\(name): \(dish) / \(price)\n\(text)")
            }
        }
    }

    func testUnreadableImageReportsAnError() {
        do {
            _ = try MenuOCR.recognize(Data("not an image".utf8))
            XCTFail("Expected unreadable image error")
        } catch {
            guard let error = error as? MenuOCR.ScanError, case .unreadableImage = error else {
                return XCTFail("Expected unreadable image error, got \(error)")
            }
        }
    }

    func testBlankPhotoRequestsAnotherPhoto() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(
            forResource: "blank", withExtension: "png", subdirectory: "Fixtures"
        ))
        do {
            _ = try MenuOCR.recognize(Data(contentsOf: url))
            XCTFail("Expected no text error")
        } catch {
            guard let error = error as? MenuOCR.ScanError, case .noText = error else {
                return XCTFail("Expected no text error, got \(error)")
            }
        }
    }

    func testCameraOrientationIsAppliedBeforeRecognition() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(
            forResource: "single-column", withExtension: "png", subdirectory: "Fixtures"
        ))
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let context = try XCTUnwrap(CGContext(data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.translateBy(x: CGFloat(image.width), y: CGFloat(image.height))
        context.rotate(by: .pi)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let rotated = try XCTUnwrap(context.makeImage())
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, rotated, [kCGImagePropertyOrientation: 3] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let text = try MenuOCR.recognize(data as Data)
        XCTAssertTrue(text.contains("Chicken Adobo 180"), text)
        XCTAssertTrue(text.contains("Sinigang 220"), text)
    }
}
