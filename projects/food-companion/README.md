# Food Companion

Native SwiftUI iPhone app, iOS 17+. Current slice: import a menu photo, recognize text with Apple Vision on the device, and edit the result alongside the original image. No backend, API key, third-party package, or model download is required for this OCR slice. Scans are held in memory; they are not saved between launches.

The accepted full-product scope and OCR comparison are in [OCR_RESEARCH.md](OCR_RESEARCH.md). Taste questionnaire, food-photo classification, personalized ranking, and optional mascot are subsequent slices. Restaurant discovery and cooking are deferred.

## Run

Open `FoodCompanion.xcodeproj`, select the **FoodCompanion** scheme, and run on an iPhone simulator. For a physical iPhone, select your development team under Signing & Capabilities and change the bundle identifier if necessary. Connect/unlock the phone and enable Developer Mode when Xcode requests it.

Take a menu photo with the Camera app, then choose it in the app's photo picker. Photos stored only in iCloud may need downloading before airplane mode; recognition itself uses no network.

## Automated check

From the repository root, replace the destination with an available simulator UUID:

```sh
xcodebuild test \
  -project projects/food-companion/FoodCompanion.xcodeproj \
  -scheme FoodCompanion \
  -destination 'platform=iOS Simulator,id=<simulator-uuid>' \
  -derivedDataPath /tmp/food-companion-build \
  CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES
```

The fixtures are original synthetic images rendered locally with system fonts. Their checks cover single and multiple columns, low contrast, English/Filipino dish names, decorative typography, camera orientation, blank images, and invalid data. They are not photographs from restaurants and do not establish real-device accuracy or latency.

The basic text API recovered fixture text but sometimes split prices from their labels. The shared OCR function reconnects standalone peso-style prices to the nearest label on the same row. Complex layouts, wrapped descriptions, and price variants still require user confirmation. Apple document recognition was also evaluated; its plain transcript did not consistently preserve fixture price associations, so it is not used.

## Physical-phone decision gate

Demo device: iPhone 15 Pro Max; exact iOS version and signing are still unverified. Before deciding Vision is sufficient:

1. Photograph five real menus: clear single column, multiple columns, low light, mixed English/Filipino names, and decorative fonts.
2. Make the photos available locally, enable airplane mode, and import each into the app.
3. Check recovered dish names, descriptions, and prices against the original. Check that the app stays responsive and that corrections are manageable.
4. Record failures and wall-clock scan time on the phone. A failed import should leave the previous successful image and edited text intact.
5. If Vision repeatedly omits dishes or misassociates descriptions/prices, evaluate PaddleOCR's official iOS demo on the same photos before changing engines.

No automatic price or ingredient interpretation is trusted yet; menu text must be confirmed before personalized recommendations are added.
