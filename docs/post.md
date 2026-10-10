# Launch posts (X and LinkedIn)

**Nothing here has been posted.**

The video post is a hard requirement:
- post the video on X or LinkedIn;
- tag Devin / Cognition;
- include #AppBuildersPH;
- paste the post's URL into the submission form.

Upload the video file into the post itself: `launch-videos/brag-output-2026-10-10-051615/gabay-launch-landscape.mp4`. The 4:5 `gabay-launch-feed.mp4` fits the LinkedIn and X feeds better.

Tagging:
- On LinkedIn, type `@Cognition` and pick the Cognition company page from the list, so it becomes a real tag.
- On X, Cognition is **@cognition** (Devin is @DevinAI).

## LinkedIn

```text
we built gabay: it shows your lola exactly where to click on her mac.

she asks in her own words, in english or taglish, by voice or typing. gabay puts a ring around the next button. she does the clicking.

the usual help is "share your screen", which is also exactly how scammers get in. so gabay never sees her screen and nothing leaves the laptop. it works offline, and it tells her to stop when a caller asks for her otp.

under the hood, whisper hears her, macos accessibility reads the real buttons (never pixels), and laya, a 421m model we fine-tuned on 28,250 examples, picks the next one. apple's on-device model says it in plain words.

on apps it never saw in training, our fine-tune went from 8/35 to 29/35. the big cloud models get 33 to 35. not perfect yet, but close, without the cloud.

built in 24 hours for the AppBuildersPH hackathon (local ai). huge shoutout to the qtr.zip team ❤️

github in the comments 👇

@Cognition #AppBuildersPH
```

First comment:

```text
github.com/EZA2405/app_builders_hack
```

## X

*(about 270 characters with the video uploaded; check the counter before posting)*

```text
we built gabay: it shows lola exactly where to click on her mac, without ever seeing her screen.

a 421m model we fine-tuned runs on the laptop, even offline, and it stops her when a caller asks for her otp.

8/35 → 29/35 on apps it never saw.

@cognition #AppBuildersPH
```

## Where the claims come from

- **8/35 → 29/35, cloud 33 to 35:** the held-out apps test (Preview, Finder, System Settings, Safari; never in training). Base Laya scored 8/35, and our v6en 29/35. The cloud references were OpenAI's Decisions API at 33/35 and TypeSafe Jev at 35/35 ([ml/RESULTS.md](../ml/RESULTS.md)).
- **421m, 28,250 examples:** Laya has 421M parameters. The v6 training set has 28,250 rows (README › Models, tools, data and disclosures).
- **"nothing leaves the laptop", "works offline":** Gabay's screen reading, voice (Whisper), decisions (Laya) and wording (Apple's on-device model) all run on the Mac. The Wi‑Fi rescue in the video was recorded while the Mac showed "Not connected". Websites still need the internet to load.
- **The otp stop:** this is the local scam check. On our 30-request set it caught 13 of 14, with 0 false alarms out of 16.

## YouTube

Title:

```text
gabay: local ai that shows lola where to click | AppBuildersPH 2026
```

Description:

```text
gabay shows your lola exactly where to click on her mac. she asks in her own words, in english or taglish, by voice or typing. gabay rings the next button, and she does the clicking.

it never sees her screen and nothing leaves the laptop. it works offline, and it tells her to stop when a caller asks for her otp.

under the hood, all on the mac:
• whisper large-v3-turbo hears her
• macos accessibility reads the real buttons, never pixels
• laya 421m, fine-tuned by us on 28,250 examples, picks the next one
• apple's on-device model says it in plain words

on apps it never saw in training, our fine-tune went from 8/35 to 29/35. the cloud references (openai decisions api, typesafe jev) get 33 to 35. not perfect yet, but close, without the cloud.

built in 24 hours by qtr.zip for the AppBuildersPH Hackathon 2026 (theme: local ai).

code: https://github.com/EZA2405/app_builders_hack

0:00 gabay, explained
0:15 why it never sees your screen
0:31 under the hood
0:46 it points, she clicks

narration: kokoro-82m, generated on the laptop. music: heygen audio library. footage: real screen recordings, with personal info blurred.

#AppBuildersPH
```
