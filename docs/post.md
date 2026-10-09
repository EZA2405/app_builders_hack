# Launch posts (X and LinkedIn)

**Nothing here has been posted.**

The video post is a hard requirement:
- post the video on X or LinkedIn;
- tag Cognition;
- include #AppBuildersPH;
- paste the post's URL into the submission form.

Before posting:
- Replace `VIDEO_LINK`. If you upload the video file into the post instead, delete it.
- Check the clip for names and faces: blur everything from Facebook, as listed in [video-shotlist.md](video-shotlist.md).
- On X, Cognition is **@cognition** (the old @cognition_labs now points there). Devin's own account is @DevinAI, if you want to tag it too. It costs 9 characters, and there is room only if you upload the video instead of linking it.
- On LinkedIn, type `@Cognition` and pick the Cognition company page from the list, so it becomes a real tag.

## X

*(277 characters, counting the link as 23)*

```text
A fake "PhilHealth" caller wants Lola's OTP. Gabay says Wait. Wi-Fi off? It rings the switch. YouTube adobo with subtitles, asked in Taglish. Our fine-tuned 0.4B model runs on her Mac; nothing leaves it. It points, she clicks.

@cognition #AppBuildersPH VIDEO_LINK
```

## LinkedIn

*(126 words)*

```text
Every bank tells Lola: never share your screen. So who helps her when the laptop won't cooperate?

For the AppBuildersPH Hackathon 2026 (theme: Local AI), we built Gabay, a Mac guide for older and non-technical people. She asks in English or Taglish, by voice or typing. Gabay reads the real buttons on her screen, a 0.4B model we fine-tuned picks the next one on the laptop itself, and a ring shows where to click. She clicks; Gabay never does.

In the video, a fake "PhilHealth" caller wants her OTP, and Gabay says Wait. With Wi-Fi off, it walks her to the Wi-Fi switch. Then adobo on YouTube with subtitles, and Facebook friend requests.

On apps it never trained on: 29/35 (cloud models: 33–35/35).

VIDEO_LINK

@Cognition #AppBuildersPH
```

## Where the claims come from

- **29/35, 33–35/35:** the held-out apps test (Preview, Finder, System Settings, Safari; never in training). Our v6en scored 29/35. The cloud references were OpenAI's Decisions API at 33/35 and TypeSafe Jev at 35/35 ([ml/RESULTS.md](../ml/RESULTS.md)).
- **"0.4B":** Laya has 421M parameters.
- **"Nothing leaves it":** Gabay's screen reading, voice (Whisper), decisions (Laya) and wording (Apple's on-device model) all run on the Mac. Websites still load from the internet.
- **Demo moments:** the Wi-Fi switch, YouTube adobo with subtitles and Facebook friend requests were demonstrated live on the dev Mac. They are demonstrations, not benchmarks.
- **The scam "Wait" card:** this is the local scam check, which is measured: on our 30-request set it caught 13 of 14, with 0 false alarms out of 16. Rehearse the exact phrase before filming ([video-shotlist.md](video-shotlist.md)).
