# Device OCR check — 9 October 2026

Device: iPhone 15 Pro Max (iPhone16,2), iOS 27.0. Signed build installed and launched. All five existing synthetic OCR tests passed on the physical phone. The Liquid Glass presentation is tracked separately in #8.

Five public restaurant-menu photographs were downloaded and bundled into a temporary device-test target. These are stress examples, not a representative accuracy benchmark or the user's own menu photos. Photographs and full OCR transcripts are deliberately excluded from this repository.

| Photograph | Selected name substring checks | Exact expected price on same output line | Scan time |
|---|---:|---:|---:|
| [Bill's BBQ](https://www.kenrockwell.com/trips/2010-01-dv-395/25.htm), angled small print | 1/3 | 0/3 | 0.490 s |
| [Chirio's](https://www.foodpantryfeasts.com/home/va-local-eats-chirios-ny-pizza-deli), clear chalkboard columns | 5/5 | 5/5 | 0.212 s |
| [Coop's](https://zydecocruiser.net/CarnivalTriumph/nola/nolaSept12a.htm), low light and glare | 3/3 | Not scored | 0.231 s |
| [Vik's](https://restaurantguru.com/Viks-Chaat-and-Market-San-Francisco/menu), distant chalkboards | 3/4 | 1/4 | 0.114 s |
| [La Ciacolada](https://restaurantguru.it/La-Ciacolada-Grado/menu), dense outdoor print | 1/4 | 0/4 | 0.179 s |

Names were compared case-insensitively after removing punctuation and spaces; prices required their expected literal format on the same line as a matching name. These are extraction smoke checks, not verified menu-item identification: a shared name such as “Marinara” can match another dish. A recovered name does not establish that its description, price, or other menu text is correct. Coop's prices were not scored because the source was too unclear to confidently label the cents.

The deliberately strict real-photo test failed. Small print and glare caused omissions; positional price joining can attach a price from a neighboring column. Therefore Vision has not passed the arbitrary-menu decision gate. The clear photograph worked well enough to support a guided scan-and-correct workflow, but every menu still needs review before recommendation logic trusts it.

Timings cover one recognition call per photograph with image bytes already in memory; they exclude photo-picker loading and are not sustained-performance measurements. Airplane Mode and Wi-Fi-off settings were not confirmed, so this is not a verified offline end-to-end run. The recognition implementation makes no network calls.

Next comparison: PaddleOCR's official iOS demo, pinned to v3.7.0 with PP-OCRv6_tiny, using the same image bytes. Results pending; no engine substitution has been made.
