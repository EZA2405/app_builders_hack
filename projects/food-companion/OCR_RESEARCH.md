# Offline menu OCR for the iPhone food companion

Research date: 2026-10-09. Scope agreed with the user: native iPhone app; short taste questionnaire; selected food photos with confirmed classifications and meal ratings; menu photo → three personalized dish choices offline; optional static mascot. Restaurant discovery and cooking are deferred. This is source research, not an implementation or hardware benchmark.

Demo hardware confirmed by the user: **iPhone 15 Pro Max**, running "the latest" iOS. The exact version has not been read from the device; confirm it through Xcode before choosing an API deployment target.

## Recommendation

Use **Apple Vision for the first build** unless open-source OCR itself is a requirement. It performs recognition on the device, supports offline use, and avoids an additional inference runtime. Vision is an Apple framework, **not an open-source OCR engine**. An open-source wrapper around Vision does not change that distinction. [Apple text recognition](https://developer.apple.com/documentation/vision/recognizing-text-in-images)

The best verified open-source alternative is **PaddleOCR's official iOS demo**, preferably the `PP-OCRv6_tiny` preset for the first feasibility check. It genuinely contains native SwiftUI code and on-device ONNX inference; this recommendation does not rely on Android support. Keep a maximum one-hour experiment: build, run one real menu photo on the demo iPhone, measure extraction quality and latency, then choose one OCR engine. Do not ship both during this deadline. This time limit and ranking are engineering judgments.

OCR only supplies text and positions. Personalized local classification, ranking, and explanations still need their own implementation; installing OCR alone does not deliver the agreed product.

## Candidates

| Candidate | Verified iPhone integration | License evidence | Deadline assessment |
| --- | --- | --- | --- |
| Apple Vision | Native framework; on-device text recognition | Proprietary Apple framework | First choice for minimum integration work |
| PaddleOCR | Official SwiftUI demo, iOS 16+, ONNX Runtime Objective-C API | Apache-2.0 code and inspected model cards; additional dependency notices | Best open-source option; attempt one bounded spike |
| Tesseract | C++ engine; existing Swift package with XCFramework | Apache-2.0 engine/data; MIT Swift wrapper | Possible, but convenient wrapper is archived |
| EasyOCR | Python/PyTorch installation; no official native iOS package found in inspected docs | Apache-2.0 code | Porting/model conversion exceeds this scope |
| RapidOCR | Main repository's `ios/` has only a README asking for a contributor | Apache-2.0 code | Not a verified turnkey iPhone solution |

## PaddleOCR: actual native path

The official demo requires Xcode 16+ and iOS 16+, installs CocoaPods dependencies, downloads detection/recognition ONNX bundles, and runs SwiftUI over ONNX Runtime's Objective-C API. Supported presets are `PP-OCRv6_small`, `PP-OCRv6_tiny`, and `PP-OCRv5_mobile`. CPU, XNNPACK, and Core ML execution providers are selectable; unsupported operators can fall back to CPU. These are supported settings, not measured acceleration on our phone. [Official iOS deployment guide](https://www.paddleocr.ai/main/version3.x/inference_deployment/cross_platform/ios_deployment.html)

The demo is present in release **v3.7.0**, published June 11, 2026; the introducing commit is `6a8b8f1e32622e2b1e868cca3529e388d5f038c1`. Start from the tagged code rather than an unpinned moving branch. [Release](https://github.com/PaddlePaddle/PaddleOCR/releases/tag/v3.7.0), [introduction commit](https://github.com/PaddlePaddle/PaddleOCR/commit/6a8b8f1e32622e2b1e868cca3529e388d5f038c1)

`Podfile` uses `onnxruntime-objc ~> 1.24`, `Yams ~> 5.0`, and `OpenCV ~> 4.3.0`; it also includes a workaround for newer Xcode framework-header warnings. Therefore this is a multi-dependency native integration, not a drop-in Swift-only component. [Podfile](https://github.com/PaddlePaddle/PaddleOCR/blob/v3.7.0/deploy/ios_demo/Podfile)

The demo accepts library images with `PhotosPicker` and normalizes image orientation before inference. A direct camera capture UI would need to be added; importing a photo taken with the Camera app already fits its input path. [Image picker source](https://github.com/PaddlePaddle/PaddleOCR/blob/v3.7.0/deploy/ios_demo/PaddleOCRDemo/Views/ImagePickerSection.swift), [view model source](https://github.com/PaddlePaddle/PaddleOCR/blob/v3.7.0/deploy/ios_demo/PaddleOCRDemo/ViewModels/OCRViewModel.swift)

The model-fetch script's official `PP-OCRv6_tiny` URLs returned HTTP 200 on the research date. HEAD responses reported detection archive **1,792,000 bytes** and recognition archive **4,526,080 bytes**, about **6.32 MB combined**. These are download archive sizes, not measured memory use or final app size. Runtime libraries and other resources add size. [Fetch script](https://github.com/PaddlePaddle/PaddleOCR/blob/v3.7.0/deploy/ios_demo/scripts/fetch_ios_demo_models.sh), [detection archive](https://paddle-model-ecology.bj.bcebos.com/paddlex/official_inference_model/paddle3.0.0/PP-OCRv6_tiny_det_onnx_infer.tar), [recognition archive](https://paddle-model-ecology.bj.bcebos.com/paddlex/official_inference_model/paddle3.0.0/PP-OCRv6_tiny_rec_onnx_infer.tar)

PaddleOCR code is Apache-2.0. The inspected official `PP-OCRv6_tiny_rec` and `PP-OCRv5_mobile_rec` model cards declare Apache-2.0. The demo bundles Clipper under Boost Software License 1.0 and instructs distributors to inspect CocoaPods dependencies' own licenses. Before distribution, retain notices and verify the exact selected detection/recognition artifacts and resolved dependencies; model-card declarations do not replace an audit of every downloaded file. [Demo NOTICE](https://github.com/PaddlePaddle/PaddleOCR/blob/v3.7.0/deploy/ios_demo/NOTICE), [v6 tiny recognition model card](https://huggingface.co/PaddlePaddle/PP-OCRv6_tiny_rec), [v5 mobile recognition model card](https://huggingface.co/PaddlePaddle/PP-OCRv5_mobile_rec)

## Other open-source options

**Tesseract:** the engine is Apache-2.0 and supports more than 100 languages; its own documentation warns that image quality often needs improvement. `tessdata_fast` supplies Apache-2.0 integer LSTM language models, usable with Tesseract 4/5. No menu-photo accuracy comparison was found or performed. [Engine](https://github.com/tesseract-ocr/tesseract), [fast models](https://github.com/tesseract-ocr/tessdata_fast)

`SwiftyTesseract` offers Swift Package Manager and a libtesseract XCFramework, but was archived April 8, 2022; its maintainer explicitly recommends Apple Vision when supported. Its MIT wrapper license is separate from the engine/data licenses. The README also records an App Store framework-packaging caveat; whether it still applies to current Xcode requires a build check. [Swift wrapper](https://github.com/SwiftyTesseract/SwiftyTesseract)

**EasyOCR:** the official path is `pip install easyocr`, Python calls, and PyTorch-based recognition; CPU mode is supported, but that is not native iOS packaging. The inspected repository provides no turnkey Swift/iOS integration. Exporting models and reproducing preprocessing/postprocessing would be a separate engineering effort. Code is Apache-2.0; individual third-party/pretrained artifacts still require inspection if selected. [Repository and installation](https://github.com/JaidedAI/EasyOCR), [license](https://github.com/JaidedAI/EasyOCR/blob/master/LICENSE)

**RapidOCR:** its current iOS directory contains only a contributor request, not an application or inference implementation. ONNX support elsewhere does not establish working iPhone integration. The project code is Apache-2.0, but it is not the shortest verified path here. [iOS README](https://github.com/RapidAI/RapidOCR/blob/main/ios/README.md), [license](https://github.com/RapidAI/RapidOCR/blob/main/LICENSE)

## Apple implementation notes

`VNRecognizeTextRequest` supports accurate recognition, custom words, automatic language detection, and querying supported recognition languages. Add user-confirmed dish names to custom vocabulary when useful, but let users correct extracted menu items. [API](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)

Apple's newer `RecognizeDocumentsRequest` extracts layout including tables, lists, and paragraphs on device; the local SDK marks it iOS 26+. It could help menu layout, but requiring iOS 26 before the demo phone is known adds a device constraint. Use established text recognition first. [WWDC 2025 document recognition](https://developer.apple.com/videos/play/wwdc2025/272/)

## First check and acceptance criteria

1. Connect the confirmed iPhone 15 Pro Max; read its exact iOS version and check signing access.
2. Test five representative menus: clear single column, multiple columns, low light, mixed English/Filipino dish names, and decorative fonts.
3. Compare recovered dish names, descriptions, and price associations with a manually checked reference. Record cold/warm latency and failures on the actual phone.
4. In airplane mode, import a newly captured menu and recover items without a backend; make incorrect text editable.
5. Feed only confirmed menu items into the recommendation step. Every choice must exist on the scanned menu, and changing a taste preference must affect ranking.

Not checked: compilation, signing, real-device latency/memory, menu accuracy, complete transitive license inventory, or model classification quality. No OCR output or food photo can establish hidden ingredients or allergen safety.
