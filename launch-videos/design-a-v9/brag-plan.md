# Brag Plan: Gabay — v9 (v4 approach, every v6 use case, Filipino)

User direction (2026-10-10): "show more use cases like the video in v6. and also use more filipino."

**Approach (v3/v4):**
- gravity text opener and the bounce-in line;
- the ring draw and iris reveal;
- the ring curving to its target;
- studio framing with a 3D float;
- caption pills;
- the live "carousel" of extra apps;
- the elastic logo.

**Use cases:**
- all three full v6 scenes (Wi‑Fi offline, full disk with "Your call", headphones);
- plus a carousel of three more real fixture goals.

**Language:** Rosa's words, the messages, captions, day cards and end card are in Filipino/Taglish. Gabay's own instruction cards stay in English, because that is what the app shows today.

| Time | Beat |
|---|---|
| 0–5.9 | "Lunes, 10:41 AM" · "Anak, nawala na naman ang internet 😭" → **Not Delivered** → falls away → "Hindi dapat hinihintay **ang tulong.**" bounces in |
| 5.9–7.5 | The ring draws; the iris opens on her offline Mac |
| 7.5–18.2 | **Lunes · Wi‑Fi:** "Tulungan mo akong ibalik yung Wi‑Fi." → checklist → the ring curves to the Wi‑Fi symbol → Bluetooth detour → switch on → ✓ → the adobo recipe loads. Captions: "Binabasa niya ang screen mo, dito lang sa Mac." · "Siya ang tumuturo. Ikaw ang nagki-click." · "Walang mali. Konting liko lang." · "Walang internet? Gumagana pa rin." |
| 18.3–27.3 | **Miyerkules · Storage** (v6 scene 2, +6.3 s): ring wipe → "Disk Almost Full" → she types "Sam…" and deletes it → Option + Space → "Paano ako maglilinis ng space?" → Trash → Empty → "This erases them for good. Take your time." → she decides ✓. Caption: "Siya ang gumagabay. Ikaw ang nagpapasya." |
| 27.3–35.0 | **Biyernes · Headphones** (v6 scene 3, +6.3 s): ring wipe → "Walang tunog…" → "Sam, paano—" deleted → "Gabay, tulungan mo akong i-connect headphones ko." → Rosa's Headphones ✓ → music plays. Caption: "Hindi na kailangang tumawag kay Sam." |
| 35.0–39.0 | **"At marami pang iba."** Three live cards: Preview "paliitin ang litrato" → Adjust Size… ✓ · Safari "palakihin ang mga letra" → Zoom In ✓ · System Settings "paliwanagin ang screen" → Displays ✓ |
| 39.0–42.8 | Sam: "Ma, kailangan mo ba ng tulong?" → "Okay na, anak. **Kaya ko na :)**" → ♥ |
| 42.8–47 | Ring → Gabay mark → "Tulong na nandiyan **kahit offline.**" → • Hindi kailangan ng cloud. • Nasa Mac mo lang ang screen mo. • Ikaw pa rin ang nagki-click. |

**Grounding:**
- The extra cards map to real held-out goals: Preview resize; Safari "make the words on this page bigger" → View > Zoom In; System Settings "make the screen brighter" → Displays.
- Everything else is as in v6.

**Notes for Q&A:**
- Rosa speaking Taglish assumes on-device dictation understands Taglish. That is untested; the current build uses Apple's on-device recognizer.
- Hosted Jev versus local Laya, as in v6.

**Implementation:** scenes 2 and 3 reuse v6's choreography verbatim as nested GSAP timelines placed at +6.3 s (`master.add(tl, 6.3)`).
