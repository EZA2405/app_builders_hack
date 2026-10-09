# Demo video shot list (60 seconds)

**Story:** Lola's afternoon on the laptop:
1. a scam call;
2. lost Wi-Fi;
3. an adobo video with subtitles;
4. her friend requests;
5. one wrong guess she sends back.

Gabay points, she clicks, and nothing leaves the laptop.

**One file, two uses:** the same video goes to the submission form (about 1 minute) and to the X or LinkedIn post ([post.md](post.md)).

## Rules for this video
- **Real takes only.** Every ring, card and result on screen must come from a real Gabay session. Don't composite rings, and don't stage a model mistake.
- **Label speed-ups.** Real steps take a few seconds each: a median of 2.1 s per decision on the M4, plus Whisper and page loads. If you speed a stretch up to fit 60 s, show the factor (for example "2×") on screen while it plays.
- **Numbers only from [ml/RESULTS.md](../ml/RESULTS.md)**, exactly as on the numbers card below.
- **Say "never trained on" only for YouTube.** YouTube is a held-out site. Facebook pages were in the training data, so don't call Facebook unseen.
- **Keep the Wi-Fi icon visible** in the menu bar during shots 1–3, so viewers can see it's off.

## Privacy: blur before export
- **Facebook:**
  - Blur every name, face and profile photo: friend-request cards, "People you may know", contacts, chat heads, notifications, and the account's own name and photo.
  - Use a test account if you can.
- **YouTube:** the account avatar, plus any recommendations or history that identify the account.
- **Browser:** the bookmarks bar, other tabs and address-bar suggestions.
- **Phone (shot 1):**
  - Stage the call from a teammate's phone, and hide the caller ID and number.
  - Never show a real OTP or code.
- **Mac:** turn on Do Not Disturb. No Mail, Messages, desktop files or notification banners in frame.

## Setup
- **Gabay:** run it with v6en (`./run.sh`), with Whisper installed, read aloud on, and text size at "Larger" so the cards are readable in a small video.
- **Recording:** record the screen at 1920×1080 with the microphone (QuickTime, or Shift-Command-5).
  - Speak close to the mic.
  - Mix Gabay's read-aloud voice under hers.
  - Shot 1 can use a phone camera.
- **Starting state:** Wi-Fi off (from Control Center), System Settings closed, the browser behind or closed.
- **Rehearsal:** say each line about 10 times and keep only lines that work every time ([POSITIONING.md](research/POSITIONING.md) §6). Have the fallback ready.

## Shots

| # | Time | Picture | Audio | Captions (burned in) | On-screen text |
|---|---|---|---|---|---|
| 1 | 0:00–0:04 | Close-up: a phone buzzing next to the laptop, caller ID hidden. Cut to the menu bar: the Wi-Fi icon is off. | Phone ringing | — | Lola's laptop. Wi-Fi: off. (arrow to the icon) |
| 2 | 0:04–0:12 | Screen. She presses Option+Space; the Ask card opens and the mic pulses. A calm "Wait" card appears, with no ring. | Lola: "A man from PhilHealth called. He needs my OTP." Gabay reads the card aloud. | A man from PhilHealth called. He needs my OTP. | Scam check on the laptop. No internet. |
| 3 | 0:12–0:24 | Screen. Rings in order: Apple menu → System Settings… → Wi-Fi in the sidebar → the Wi-Fi switch. She clicks each one, and the Wi-Fi icon fills in. "Did that do it?" → she clicks **Yes, all done**. | Lola: "Nawalan ako ng Wi-Fi." Gabay reads each step. | Nawalan ako ng Wi-Fi. (My Wi-Fi is gone.) | Voice, choices and wording: all on this Mac. Then, once connected: Wi-Fi: on. |
| 4 | 0:24–0:38 | Screen, browser on youtube.com. Rings: the search box (she types "adobo" and presses Enter) → a video → **Subtitles (CC)**. Captions appear on the video. | Lola: "Gusto kong manood kung paano magluto ng adobo, tapos lagyan ng subtitles." | (I want to watch how to cook adobo, with subtitles.) | YouTube: a site the model never trained on. Then: The page needs internet. What Gabay reads stays on the laptop. |
| 5 | 0:38–0:44 | Screen, facebook.com (blurred). Rings lead to Friend requests. "Is this what you wanted?" → **Yes, this is it**. | Lola: "Saan ko makikita yung friend requests ko?" | (Where do I see my friend requests?) | It asks before it assumes. |
| 6 | 0:44–0:49 | Screen. A real take where the first ring isn't what she meant. She clicks **Not this one**; the ring moves to the next-best control, and she clicks it. | Gabay reads the new step. | — | Wrong guess? Not this one. |
| 7 | 0:49–0:56 | Numbers card over the dimmed last frame. | Music | — | See "Numbers card" below |
| 8 | 0:56–1:00 | End card. | Music ends | — | It points. She clicks. Nothing leaves the laptop. / Gabay · AppBuildersPH 2026 · Local AI / github.com/EZA2405/app_builders_hack |

**The Wait card (shot 2)** shows the app's own words. When the local model catches this request, the card says "Wait. Never give the code sent to your phone to anyone, even someone who says they're from your bank or the government." Below it: "If someone asked you to do this, stop and call your family first."

## Numbers card (shot 7)

Use these lines exactly:

> **Apps it never trained on (35 tasks)**
> - Base model, on the laptop: 8/35
> - Gabay's fine-tuned model, on the laptop: 29/35
> - Cloud references: 33/35 (OpenAI) · 35/35 (TypeSafe Jev)
>
> *Small print:* Websites it never trained on: 32 of 45 steps. Measured; details in ml/RESULTS.md.

## Spoken lines and fallbacks
- **Scam (shot 2):** "A man from PhilHealth called. He needs my OTP." With this wording the local model, not the keyword rules, raises the Wait card.
  - **Taglish option** (rehearse it first): "Sabi ng taga-PhilHealth, ibigay ko daw yung OTP ko."
  - "Ibigay" also trips the keyword rule, which shows a shorter card: "Wait. Never give your one-time code to anyone."
- **Wi-Fi (shot 3):** "Nawalan ako ng Wi-Fi." Fallback: "My Wi-Fi is off. How do I turn it on?"
- **YouTube (shot 4):** fallback is two separate requests: "Hanapin natin kung paano magluto ng adobo", then "Lagyan ng subtitles."
- **Facebook (shot 5):** fallback is Marketplace, which was also demonstrated live.
- **Not this one (shot 6):** take it from any real session where the first ring missed. If no take has one, cut shot 6 and give its time to shots 3 and 4. Don't stage a miss.

## Export
- 1920×1080, H.264 MP4, about 60 seconds.
- Burn in the captions; many people watch muted.
- Before uploading, watch the whole export once, only checking for unblurred names, faces or codes.
