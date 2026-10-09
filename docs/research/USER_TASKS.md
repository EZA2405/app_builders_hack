# What older and non-technical people actually ask for help with on a computer

Research date: Oct 9, 2026. Public pages only (read-only). Nothing was posted, submitted or signed up for. This builds on `POSITIONING.md` (PH seniors, anti-scam, competitors), which it doesn't repeat. This file is about **concrete tasks**.

**Legend:**
- **[E]** = evidence from a cited source.
- **[I]** = our inference or recommendation.
- Gabay columns:
  - **Yes-Mac** = Gabay can guide it today with Mac app menus, dialogs, System Settings, Dock or menu bar.
  - **Yes-Web** = a web page through the extension.
  - **Partial** = Gabay can point the way, but the person must type content or passwords, use their phone, or handle hardware.
  - **No** = out of reach.
- Model scores quoted here come only from `ml/RESULTS.md`.

---

## TL;DR

- **The same four things top every list:** passwords and logins, email and attachments, printing, and video calls. After those come Wi-Fi, text size, "where did my file or window go", pop-ups and scams, and online forms and banking.
  - **[E]** Sources: [MicroSec](https://www.microcybersec.com/post/top-tech-support-options-for-senior-citizens-and-their-families), [Half Price Geeks](https://halfpricegeeks.com/senior-tech-support/), [Candoo Tech 2024](https://www.candootech.com/blog-page/impact24), [Age UK/Lloyds](https://www.ageuk.org.uk/latest-press/articles/2023/age-uk-analysis-reveals-that-almost-6-million-people-5800000-aged-65-are-either-unable-to-use-the-internet-safely-and-successfully-or-arent-online-at-all/).
- **Most of these are "find the control" problems, not "understand the concept" problems.** The most-failed basic tasks in the UK are:
  - connecting to Wi-Fi: 35% of over-65s can't;
  - finding and opening an app: 28%;
  - logging in: 23%;
  - adjusting settings such as font size or volume.
  - **[E]** Source: [Age UK analysis of Lloyds data](https://www.ageuk.org.uk/latest-press/articles/2023/age-uk-analysis-reveals-that-almost-6-million-people-5800000-aged-65-are-either-unable-to-use-the-internet-safely-and-successfully-or-arent-online-at-all/).
  - **[I]** Pointing at the exact control is a good fit for this.
- **Helpers suffer most when they can't see the screen.**
  - Most "it's broken" calls turn out to be "something moved, something popped up, or it's buried" **[E]** ([yourfriendrich](https://www.yourfriendrich.com/simple-phone-helper/guides/help-elderly-parent-phone-remotely/)).
  - In a diary study, 24 of 57 older adults' help requests lacked the context needed to answer them **[E]** ([arXiv 2601.10018](https://arxiv.org/html/2601.10018v1)).
- **Philippines: the phone is primary.**
  - 98.8% of internet users go online by cellphone; only 14.7% use a laptop **[E]** ([PSA NICTHS 2024 via NoypiGeeks](https://www.noypigeeks.com/spotlight/ph-internet-mobile-devices-usage-2024-govt-survey/)).
  - Only 10.6% of older persons' households have a PC or laptop **[E]** ([ERIA/LSAHP ch. 9](https://www.eria.org/uploads/media/Books/2019-Dec-Ageing-and-Health-Philippines/15-Ageing-and-Health-Philippines-Chapter-9-new.pdf)).
  - GCash and eGovPH are **phone-only**.
  - **[I]** The laptop wins for **"requirements" tasks**: SSS and PhilHealth portals, downloading and printing forms, emailing scanned IDs, online banking on the web, Shopee, and video calls on a bigger screen.
- **Best demo goals** (§4):
  1. Photo resize in Preview (offline)
  2. "They can't see me on the video call" (camera permission in System Settings, offline)
  3. Taglish text size
  4. YouTube captions or search
  5. A PhilHealth or SSS portal step

---

## 0. Evidence base at a glance

| Source | What it says about tasks | Type |
|---|---|---|
| **Pew Research, 2017** ([link](https://www.pewresearch.org/internet/2017/05/17/tech-adoption-climbs-among-older-adults/)) | 48% of seniors say "when I get a new device, I usually need someone else to set it up or show me" describes them *very well*. 34% have little or no confidence doing online tasks. | Survey, US |
| **Pew, 2014** ([link](https://www.pewresearch.org/internet/2014/04/03/older-adults-and-technology-use/)) | 77% of 65+ would need someone to walk them through a new device. | Survey, US |
| **AARP Tech Trends 2025** ([link](https://www.aarp.org/pri/topics/technology/internet-media-devices/2025-technology-trends-older-adults/)) | Among 50+:<br>• 72% own a laptop; 50% own a desktop<br>• 19% name set-up and support as the main barrier<br>• 59% say tech isn't designed for their age<br>• **71% are interested in a tech support service built for older users** | Survey, n=3,605, US |
| **Age UK / Lloyds Essential Digital Skills** ([2023](https://www.ageuk.org.uk/latest-press/articles/2023/age-uk-analysis-reveals-that-almost-6-million-people-5800000-aged-65-are-either-unable-to-use-the-internet-safely-and-successfully-or-arent-online-at-all/), [2024](https://www.ageuk.org.uk/latest-press/articles/2024/more-than-1-in-3-over-65s-4.7-million-lack-the-basic-skills-to-use-the-internet-successfully/)) | Among over-65s:<br>• 46% can't do all 8 foundation tasks (69% of 75+)<br>• Wi-Fi is the hardest, at 35%<br>• Opening apps 28%; logging in 23%<br>• Settings (font size, volume), passwords and browser use all fail at similar rates | Survey analysis, UK |
| **Lloyds EDS 2021** ([PDF](https://charnwood.moderngov.co.uk/documents/s9362/DTSP%2029%20March%202022%20-%20Itm%20XX%20-%20Ann%203%20-%20211109-lloyds-essential-digital-skills-report-2021.pdf)) | For over-65s, "adjusting menu settings and connecting to Wi-Fi are the two hardest tasks". | Survey, UK |
| **Ofcom Adults' Media Use 2026** ([PDF](https://www.ofcom.org.uk/siteassets/resources/documents/research-and-data/media-literacy-research/adults/adults-media-use-and-attitudes-2026/adults-media-use-and-attitudes-2026-report.pdf)) | Among adults without home internet, 42% asked someone to do something online for them, most often online shopping (56%) or health services (37%). | Survey, UK |
| **Candoo Tech Impact Survey 2024** ([link](https://www.candootech.com/blog-page/impact24)) | Most-requested 1:1 topics:<br>1. staying safe online<br>2. **Zoom**<br>3. social media<br>4. dealing with doctors online<br><br>**Laptops and desktops are the most-used devices**, ahead of iPhone. Over 50% of respondents are 80+. | Vendor survey, US |
| **MicroSec / Half Price Geeks** ([1](https://www.microcybersec.com/post/top-tech-support-options-for-senior-citizens-and-their-families), [2](https://halfpricegeeks.com/senior-tech-support/)) | Top requests:<br>• password resets (#1)<br>• email (#2)<br>• printer and Wi-Fi<br>• setting up devices<br>• scam pop-ups<br>• video calls | Vendor lists (no method) |
| **Hunsaker, Hargittai et al. 2019** ([Socius](https://journals.sagepub.com/doi/10.1177/2378023119887866), [abstract](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6846104/)) | N=58, ages 59+. They needed help with:<br>• social media features<br>• security<br>• connecting devices<br>• internet banking<br>• managing photos online<br>• shopping<br><br>Support "can lack immediacy". | Qualitative, EU |
| **Older-adult help-request diary** ([arXiv 2601.10018](https://arxiv.org/html/2601.10018v1)) | 27 adults, median age 66, 57 queries.<br>• Incomplete: 24<br>• Under-specified: 13<br>• Over-specified: 12<br>• Too wordy: 9<br><br>Dark mode was described as "screen going dark". They asked family first. | Diary study |
| **Telehealth studies** ([VA observation](https://pmc.ncbi.nlm.nih.gov/articles/PMC10736894/), [JAMA IM](https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/2768772), [MA 65+ survey](https://pmc.ncbi.nlm.nih.gov/articles/PMC9538237/)) | • **Over 80% of older veterans hit tech problems joining a video visit**, and 60% needed in-person help.<br>• 27% of 65+ video visits fell back to audio-only.<br>• 72% of 85+ were "not ready" for video visits. | Clinical studies, US |
| **Hacker News family-support threads** ([40127400](https://news.ycombinator.com/item?id=40127400), [29685115](https://news.ycombinator.com/item?id=29685115)) | Firsthand reports: printing; logging in or paying on websites; cookie banners blocking pages; "Your Computer is Infected" ads; web notification prompts; a hidden Inbox folder; vague error descriptions. | Firsthand |
| **PSA NICTHS 2024** ([PSA release](https://psa.gov.ph/content/laptop-computer-was-most-commonly-used-filipinos-aged-10-years-and-over-2024-sending)) | Among PH computer users: **83.8% send messages with file attachments** (the top activity), 66.4% copy and paste, and 51.6% write documents. 17.9% of Filipinos aged 10+ used a computer. | Gov survey, PH |

**Reddit:** our crawler and Reddit's JSON were blocked this session. The r/AgingParents evidence is the two threads already cited in `POSITIONING.md`. We used Hacker News, MetaFilter, forums and studies as firsthand stand-ins.

---

## 1. Top ~30 concrete computer tasks

"Desktop?" shows where the task usually happens for this group.
- **D** = mainly on a computer
- **B** = both computer and phone
- **P** = mainly on a phone

**[I]** The Gabay column reflects current capability: the macOS AX tree for apps, System Settings, the Dock and menu bar, and the Chrome DOM through the extension. Gabay never types or clicks for the user.

### A. Email and attachments
| # | Task, in their words | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 1 | "How do I send this photo or document by email?" | **[E]** The top PH computer activity is 83.8% sending attachments ([PSA](https://psa.gov.ph/content/laptop-computer-was-most-commonly-used-filipinos-aged-10-years-and-over-2024-sending)). Attaching a photo "can send some into a rabbit hole" ([Cyber-Seniors](https://cyberseniors.org/stories/cyber-seniors-in-the-news/fantastic-free-tech-support-for-your-older-parent-or-you/)). | D | **Partial.** It rings Mail's `File > Attach Files…` or Gmail's paperclip, and the Finder file dialog. The user types the address and message. |
| 2 | "They sent me a file, how do I open, save or print it?" | **[E]** Parents forget "how to open/save/print attachments" ([AnandTech forum](https://forums.anandtech.com/threads/technology-question-from-my-mom.279831)). | D | **Yes-Mac / Yes-Web.** Download icon, then Preview, then `File > Print…` |
| 3 | "My emails disappeared" (hidden mailbox, spam) | **[E]** "Hiding the Inbox folder in Email is another classic I need to fix monthly" ([HN](https://news.ycombinator.com/item?id=40127400)). Spam filters hide important mail ([MicroSec](https://www.microcybersec.com/post/top-tech-support-options-for-senior-citizens-and-their-families)). | B | **Yes-Mac** (Mail `View > Show Mailbox List`). **Yes-Web** (Gmail Spam folder). |
| 4 | "Set up an email so I can register for SSS or a job" | **[E]** Gmail setup is the first item in Globe's senior curriculum ([Globe](https://www.globe.com.ph/blog/essential-skills-for-senior-citizens)). My.SSS requires a unique email ([SSS registration guide](https://filipiknow.net/sss-online-registration/)). | B | **Partial.** It points through the sign-up form; the user types everything. |

### B. Passwords and logins
| # | Task | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 5 | "I forgot my password" (email, Facebook, Apple ID) | **[E]** The #1 request at senior tech-support firms ([MicroSec](https://www.microcybersec.com/post/top-tech-support-options-for-senior-citizens-and-their-families)). "Every elderly family member with an iPhone has forgotten the iCloud password" ([HN](https://news.ycombinator.com/item?id=40127400)). | B | **Partial.** It rings "Forgot password?" and the Apple Account pane. Recovery still needs their phone or email. |
| 6 | "Where do I log in?" | **[E]** A 90-year-old's trouble is "mostly bad UI on web sites… finding the login button" ([HN, sherr](https://news.ycombinator.com/item?id=40127400)). An 84-year-old calls about "logging in to a website or paying for something" (same thread). | D | **Yes-Web.** Shopee "Log in" and PhilHealth "Log in" are already held-out goals. |
| 7 | "It says change my password" | **[E]** Updating passwords is a Lloyds foundation task that many over-65s fail ([Age UK](https://www.ageuk.org.uk/latest-press/articles/2023/age-uk-analysis-reveals-that-almost-6-million-people-5800000-aged-65-are-either-unable-to-use-the-internet-safely-and-successfully-or-arent-online-at-all/)). | B | **Partial.** |

### C. Video calls
| # | Task | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 8 | "How do I join the Zoom or Meet from the email?" | **[E]** Zoom is Candoo's #2 topic ([Candoo](https://www.candootech.com/blog-page/impact24)). Older adults struggle with "finding meeting links in emails" ([caregiver study](https://pmc.ncbi.nlm.nih.gov/articles/PMC9770694/)). | D/B | **Yes-Mac / Yes-Web.** Link in Mail, then "Open zoom.us" or "Join from browser", then "Join with Computer Audio". |
| 9 | **"They can't see me / can't hear me"** (camera or mic blocked, muted) | **[E]**<br>• Over 80% hit problems and 60% needed in-person help ([VA](https://pmc.ncbi.nlm.nih.gov/articles/PMC10736894/)).<br>• 27% fell back to audio-only ([MA study](https://pmc.ncbi.nlm.nih.gov/articles/PMC9538237/)).<br>• On a Mac the fix is buried in `System Settings > Privacy & Security > Camera` ([Zoom KB](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0064868)). | D | **Yes-Mac.** It walks through the Privacy & Security pane and the in-app Unmute and Start Video buttons. **[I]** The Zoom app's AX tree is untested. |
| 10 | "Video-call my child abroad on Messenger or FaceTime" | **[E]**<br>• A 67-year-old in Legazpi uses Messenger to reach her daughter in Saudi Arabia ([Rappler](https://www.rappler.com/newsbreak/in-depth/senior-citizens-digital-gap-scam-targets/)).<br>• Meta **killed the Mac Messenger app** on Dec 15, 2025 ([TechCrunch](https://techcrunch.com/2025/10/16/meta-to-shut-down-messenger-desktop-apps-for-mac-and-windows/)) and **messenger.com** in April 2026. On a Mac, Messenger is now only at `facebook.com/messages` ([TechCrunch](https://www.techcrunch.com/2026/02/19/meta-is-shutting-down-messengers-standalone-website/)). | P (mostly), D on Mac | **Yes-Web** (facebook.com), **untested.** **Yes-Mac** for FaceTime. **[I]** Browser camera prompts are browser UI, not page DOM, so verify they're visible to Gabay. |

### D. Photos
| # | Task | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 11 | "Make this photo smaller so I can email it" | **[E]** In the original family-support story, sending one email took 20 minutes (POSITIONING). | D | **Yes-Mac.** Preview `Tools > Adjust Size…`. This is a held-out goal; Preview group scores 7/10. |
| 12 | "The picture is sideways" | **[E]** A rotation complaint ("won't turn… What happened?!!") appears in the diary study ([arXiv](https://arxiv.org/html/2601.10018v1)). | B | **Yes-Mac** (`Tools > Rotate`). |
| 13 | "Get the photos from my phone onto the computer" / "where are my photos?" | **[E]** Copying photos and videos for parents is a recurring helper job ([HN](https://news.ycombinator.com/item?id=29685115)). | D | **Partial.** Photos `File > Import…` works, but it needs a cable or AirDrop and a phone prompt. |
| 14 | "Print this" | **[E]**<br>• "The only real issue he has is printing" ([HN](https://news.ycombinator.com/item?id=40127400)).<br>• Printers are the #1 MicroSec service ([MicroSec](https://www.microcybersec.com/senior-citizen-it-support)).<br>• A relative "needs something printed, she's the one they call" ([AAA](https://cluballiance.aaa.com/the-extra-mile/advice/life/technology-with-my-older-relatives)). | D | **Yes-Mac** for `File > Print…`, the print sheet, and `System Settings > Printers > Add`. **No** for jams, ink, drivers or Wi-Fi pairing. |

### E. Files and downloads
| # | Task | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 15 | "Where did my download go?" | **[E]** The Downloads folder becomes "technically accessible, practically lost" ([TheDrive](https://thedrive.ai/blog/how-to-find-old-email-attachment)). How-To Geek has a page just for this ([HTG](https://www.howtogeek.com/771533/where-are-my-downloads-on-windows/)). | D | **Yes-Mac.** Finder `Go > Downloads`, or search. Finder is a held-out app (8/8). |
| 16 | "Fill in this PDF form, save it and send it back" | **[E]** Older people can email but lack confidence "to safely apply for support online… uploading photos or other evidence" ([Age UK](https://committees.parliament.uk/writtenevidence/119057/pdf/)). | D | **Partial.** Preview form fields and `File > Export as PDF…` work. The user types the content. |
| 17 | "Make a folder for my documents", "zip it to send", "rename it" | **[E]** These are Finder held-out goals. Basic file chores are recurring warm-expert work ([Hänninen et al.](https://journals.sagepub.com/doi/10.1177/1461444820917353)). | D | **Yes-Mac.** |

### F. Screen, sound and connections
| # | Task | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 18 | **"Make the letters bigger, I can't read it"** | **[E]**<br>• Adjusting font size is a foundation task many fail ([Age UK](https://www.ageuk.org.uk/latest-press/articles/2024/more-than-1-in-3-over-65s-4.7-million-lack-the-basic-skills-to-use-the-internet-successfully/)).<br>• "Make screens easier to use" is in the WSJ family tune-up ([Axios](https://www.axios.com/newsletters/axios-finish-line-fd85a410-df5a-11f0-898f-25ce8a816c13)).<br>• "Text too small" appears in the diary study. | B | **Yes-Mac** (`Accessibility > Display > Text size`, `Displays > Larger Text`). **Yes-Web** (`View > Zoom In`). |
| 19 | **"Connect to the Wi-Fi"** | **[E]** The hardest foundation task: 35% of over-65s can't do it ([Age UK](https://www.ageuk.org.uk/latest-press/articles/2023/age-uk-analysis-reveals-that-almost-6-million-people-5800000-aged-65-are-either-unable-to-use-the-internet-safely-and-successfully-or-arent-online-at-all/)). | B | **Yes-Mac** (Control Center or `System Settings > Wi-Fi`). The user types the password. **No** if the router is down. |
| 20 | "No sound", "too quiet", "connect my Bluetooth headphones" | **[E]** These are System Settings held-out goals. Volume is a foundation-task example (Age UK). | B | **Yes-Mac.** |
| 21 | "The screen went dark or dim" | **[E]** Dark mode was called "screen going dark" ([arXiv](https://arxiv.org/html/2601.10018v1)). | B | **Yes-Mac** (Displays, Appearance). |
| 22 | "The internet is gone" (airplane mode, Wi-Fi turned off) | **[E]** Parents "keep turning airplane mode on… and can't figure out how to disable it" (phones; [HN](https://news.ycombinator.com/item?id=40127400)). **[I]** The Mac equivalent is Wi-Fi switched off in Control Center. | B | **Yes-Mac** for turning Wi-Fi back on. **No** for an ISP outage. |

### G. Updates and messages
| # | Task | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 23 | "A box says update, should I click it?" / "update my computer" | **[E]** "Windows updates, security warnings" are core MicroSec coaching topics ([MicroSec](https://www.microcybersec.com/senior-citizen-it-support)). Turning on automatic updates is the #1 WSJ tip ([Axios](https://www.axios.com/newsletters/axios-finish-line-fd85a410-df5a-11f0-898f-25ce8a816c13)). "Update my mac" is a System Settings held-out goal. | D | **Yes-Mac** (`General > Software Update`). **[I]** Gabay reads the dialog, so the helper doesn't have to ask what it says. |
| 24 | "My computer is slow or full" | **[E]** Every 3–6 months: "it's 'stopped working'… moving at a crawl" ([HN](https://news.ycombinator.com/item?id=12900515)). | D | **Partial.** It can open `General > Storage`. Diagnosing the cause is out of scope. |

### H. Browser
| # | Task | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 25 | "The page or window disappeared" / "go back" / "I closed it by mistake" | **[E]** A parent couldn't find "his accidentally-collapsed browser window" ([Carley K.](https://carleyk.com/kids/6-ways-better-tech-support-parents/)). These are Safari held-out goals. | D | **Yes-Mac.** `History > Reopen Last Closed Window`, `Window` menu, Dock. |
| 26 | "Something is covering the page" (cookie banner, sign-up pop-up, "allow notifications") | **[E]** "Cookie/consent popups blocking page and causing confusion, finding the close button" ([HN](https://news.ycombinator.com/item?id=40127400)). "Accepting spammy Web Notification prompts" (same thread). | D | **Yes-Web** for in-page overlays (a Wikipedia banner-close goal exists). **Partial** for browser-native prompts. |
| 27 | "Save this site so I can find it again" (bookmark the real bank or PhilHealth site) | **[E]** Fake PhilHealth logins rank in search, so the advice is to use a bookmark ([guide](https://philhealth-portal.ph/philhealth-member-portal/), unofficial). | D | **Yes-Mac** (`Bookmarks > Add Bookmark`). |

### I. Online services
| # | Task | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 28 | **Government portal: register, check records, upload an ID** | **[E]**<br>• UK: Blue Badge applications are hard without "a friend or family member to help" ([Age UK](https://committees.parliament.uk/writtenevidence/119057/pdf/)).<br>• PH: only 20% of seniors were registered on My.SSS ([BusinessMirror 2021](https://www.pressreader.com/philippines/businessmirror/20210331/281681142670321)). | D (PH web portals) | **Partial / Yes-Web.** Gabay navigates; the user types and uploads. The file picker is **Yes-Mac**. |
| 29 | Pay a bill or use online banking | **[E]** Internet banking appears among support needs ([Hunsaker](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6846104/)). Only 7% of UK over-70s can shop or manage money online ([Lloyds 2020](https://www.lloydsbankinggroup.com/assets/pdfs/media/consumer-digital-index/2020-consumer-digital-index-report.pdf)). | B | **Partial.** Navigation works; the OTP arrives on their phone. |
| 30 | Shop online and track the order | **[E]** Shopping is the top thing UK offline adults ask others to do (56%) ([Ofcom 2026](https://www.ofcom.org.uk/siteassets/resources/documents/research-and-data/media-literacy-research/adults/adults-media-use-and-attitudes-2026/adults-media-use-and-attitudes-2026-report.pdf)). | B | **Yes-Web.** Shopee held-out group: 6/10. |
| 31 | Watch YouTube: search, captions, full screen | **[E]** YouTube is a top Candoo guide ([Candoo](https://www.candootech.com/blog-page/top-most-requested-tech-how-to-guides-in-2025)). "Can't understand what they're saying" appears in the diary study. | B | **Yes-Web.** YouTube held-out group: 8/10. |
| 32 | Facebook: see the grandkids' posts, post a photo | **[E]** Social media is Candoo's #3 topic. Facebook setup is in Globe's curriculum. | P (mostly) | **Yes-Web**, untested on facebook.com. |

### J. Scams and alarming pop-ups
| # | Task | Evidence | Desktop? | Gabay today |
|---|---|---|---|---|
| 33 | **"A warning says I have a virus and to call this number"** | **[E]** The FTC's advice is to close it without clicking inside it ([FTC](https://consumer.ftc.gov/consumer-alerts/2025/04/seemingly-urgent-security-messages-could-lead-tech-support-scams)). A relative "clicked a fullscreen 'Your Computer is Infected' ad" ([HN](https://news.ycombinator.com/item?id=40127400)). See also POSITIONING §3. | D | **Yes-Mac** for `Apple menu > Force Quit…` and the browser's Quit. **[I]** It doesn't *detect* scams; it gives a calm way out. |
| 34 | "Is this email real?" | **[E]** Less media-literate people rely on family when they suspect a scam ([Ofcom Media Lives 2024](https://www.ofcom.org.uk/siteassets/resources/documents/research-and-data/media-literacy-research/adults/adults-media-use-and-attitudes-2024/adults-media-lives-2024-a-qualitative-study-wave-19.pdf)). | B | **No.** It's a judgment call, not a click. |

**[I] Gabay coverage:**
- About 20 of 34 are **Yes** (Mac or Web) and about 12 are **Partial**.
- The **No** cases need typed content, judgment, hardware, or a phone-only app.

---

## 2. What wears out the helper most: the "you have to be there" tasks

**Why "you have to be there":**
- **[E]** The helper can't see the screen. Hotline staff start by asking "What kind of device do you have? Is it Windows, Android? What app is it?" ([AARP Senior Planet](https://www.aarp.org/advocacy/senior-planet-technology-hotline/)).
- **[E]** Parents describe errors vaguely ("it just said no"). Remote desktop removed the need to ask what the error actually said ([HN](https://news.ycombinator.com/item?id=29685115)).
- **[E]** Older adults' problem reports are mostly incomplete (24/57) ([arXiv](https://arxiv.org/html/2601.10018v1)).
- **[E]** Help carries an emotional cost: shame at being a burden, and helpers frustrated by slow teaching ([Hänninen & Taipale 2025](https://doi.org/10.1177/14614448251385087)).

**[I] Ranked by helper pain** (hard to describe, buried, multi-step, transient):

| Rank | Task | Why it's hard to help with remotely | Why a ring on the exact control wins |
|---|---|---|---|
| 1 | **Camera or mic not working on a video call** (#9) | The call itself is the channel that's broken. The fix is 4 levels deep in System Settings, and the right toggle depends on the app. | Gabay sees the real pane and app names (e.g. "Google Chrome", "zoom.us"), so nobody has to guess. |
| 2 | **Pop-ups and dialogs: update, permission, "virus"** (#23, #26, #33) | They're transient. The parent can't read them back, and clicking the wrong button is costly. | Gabay reads the dialog's buttons from the AX tree or DOM and rings the safe one. |
| 3 | **"Where did it go?"** (window, download, attachment) (#2, #15, #25) | The parent doesn't know what they did. | Gabay rings the Window menu, the Dock, or `Go > Downloads`. |
| 4 | **Wi-Fi, sound, text size, brightness** (#18–22) | Settings are buried and their names differ by OS version (helpers say "match their OS version"). | Gabay uses the names on *this* Mac. |
| 5 | **Printing** (#14) | The print sheet has many options, and the failure is often physical. | The dialog part is solvable. Be honest that hardware isn't. |
| 6 | **Attach a file or photo to email** (#1) | It means switching between Mail and the Finder dialog, and file locations are unknown. | Gabay rings each step across both apps. |
| 7 | **Portal navigation** (#28) | Every portal is different, and the screen is full of IDs the parent won't share. | Local means it never leaves the Mac (POSITIONING §2). |

**Not worth targeting:**
- Password recall
- Hardware faults
- "Is it a scam?" judgment
- Composing messages

---

## 3. Philippines specifics

### Laptop vs phone (be honest about this)
- **[E] All ages (2024 NICTHS):**
  - Among internet users: cellphone 98.8%, laptop 14.7%, desktop 10.0%.
  - 17.9% of Filipinos aged 10+ used a computer.
  - Among computer users, 67.5% use laptops.
  - Sources: [NoypiGeeks](https://www.noypigeeks.com/spotlight/ph-internet-mobile-devices-usage-2024-govt-survey/), [PSA](https://psa.gov.ph/content/laptop-computer-was-most-commonly-used-filipinos-aged-10-years-and-over-2024-sending).
- **[E] Older people:**
  - In 2019, only 13% of Filipinos aged 55+ used a computer, while 59% owned a cellphone ([PIDS DP 2021-13](https://pidswebs.pids.gov.ph/CDN/PUBLICATIONS/pidsdps2113.pdf)).
  - Older persons' households (LSAHP 2018): **PC or laptop 10.6% vs cellphone 65.4%**.
  - When they need gadget help, OPs go to a **daughter (32%), son (22%) or grandchild (16%)** ([ERIA/LSAHP ch. 9](https://www.eria.org/uploads/media/Books/2019-Dec-Ageing-and-Health-Philippines/15-Ageing-and-Health-Philippines-Chapter-9-new.pdf)).
- **[I] Implication:** the PH Gabay user is the **senior using the household laptop** (often the child's or a grandchild's) for jobs the phone does badly:
  - long forms
  - printing
  - downloading PDFs
  - uploading scans
  - reading small print on a big screen

  Don't claim seniors mainly use laptops.

### Tasks and channels
| Task | Where it happens | Gabay | Evidence |
|---|---|---|---|
| **Video-calling a child abroad** (Messenger, also Viber, FaceTime, Zoom) | Mainly phone. On a Mac, Messenger is only at facebook.com/messages since Apr 2026 | **Yes-Web** (untested). **Yes-Mac** for FaceTime and camera permissions | **[E]**<br>• IM and video calls are the main OFW family channel ([IJRPR](https://ijrpr.com/uploads/V4ISSUE1/IJRPR9603.pdf)).<br>• TikTok posts show people teaching a lola to video-call on Messenger ([TikTok discover](https://www.tiktok.com/discover/how-to-facetime-on-messenger)).<br>• The Messenger shutdowns ([TechCrunch](https://www.techcrunch.com/2026/02/19/meta-is-shutting-down-messengers-standalone-website/)). |
| **GCash** | **Phone only.** No web login for personal accounts; "web GCash" pages are phishing | **No.** At most, a laptop checkout shows a QR the phone scans | **[E]** [GCash Help](https://help.gcash.com/hc/en-us/articles/41329110227737-Are-there-other-ways-to-log-in-to-GCash) |
| **eGovPH / digital senior ID** | **Phone app only** | **No** | **[E]** [FilipiKnow](https://filipiknow.net/egovph-app-guide-2026-how-to-register-on-your-phone/), [PIA](https://pia.gov.ph/digital-senior-citizens-id-now-accessible-through-egov-ph-app/) |
| **SSS:** My.SSS registration, pension, Annual Confirmation of Pensioners (ACOP) | Web (member.sss.gov.ph, plus an ACOP icon on sss.gov.ph) and app | **Yes-Web** (navigation). The user types numbers | **[E]**<br>• Only 20% of seniors were registered online in 2021.<br>• Officials tell pensioners to ask "someone who knows how to go online" at home ([BusinessMirror](https://www.pressreader.com/philippines/businessmirror/20210331/281681142670321)).<br>• ACOP is online for under-80s ([PEP](https://www.pep.ph/pepalerts/fyi/191405/sss-pensioners-annual-confirmation-pensioners-online-a717-20260318)).<br>• SSS warns about paid "help" Facebook groups ([SSS via search](https://www.sss.gov.ph/news-and-updates/sss-launches-its-pilot-digital-branch-in-san-pedro-city-laguna/)). |
| **PhilHealth:** member portal, contributions, printing the MDR, PMRF form | **Browser only.** Reportedly no official app | **Yes-Web.** Held-out group 7/15 | **[E]** A printed MDR is useful backup at hospitals. The PMRF is printed, filled in, scanned and emailed. Source: an *unofficial* guide ([philhealth-portal.ph](https://philhealth-portal.ph/philhealth-member-portal/)); verify on philhealth.gov.ph. |
| **Online banking** (BDO, BPI) | Web and app. The OTP goes to the phone | **Partial** | **[E]** BDO sign-up fails if the email or mobile on file is outdated ([BDO](https://www.bdo.com.ph/personal/digital/bdo-online)). BPI's web login works after enrollment ([BPI](https://www.bpi.com.ph/personal/bank/digital-banking/online)). |
| **Shopee / Lazada:** search, cart, track, return | Mainly app; web works | **Yes-Web.** Shopee held-out 6/10 | **[E]** Online shopping is in Globe's senior curriculum ([Globe](https://www.globe.com.ph/blog/essential-skills-for-senior-citizens)). |
| **Email for requirements** (job, SSS, school, scanned IDs) | Laptop is better | **Partial** | **[E]** PSA: attachments are the top computer activity. Email is in the Globe and #SeniorDigizen sessions ([Globe](https://www.globe.com.ph/blog/essential-skills-for-senior-citizens)). |
| **Download and print forms** (PMRF, OSCA senior ID application, CS Form) | Laptop | **Yes-Mac / Yes-Web** | **[I]** Common practice. No PH firsthand source found. |
| **Pag-IBIG (Virtual Pag-IBIG), Meralco** | Web and app | Likely **Yes-Web** | **[I]** Not verified this session. |

### Who teaches them now
- **[E]** Globe #SeniorDigizen covers smartphones, email, GCash, GlobeOne and KonsultaMD ([Globe](https://www.globe.com.ph/blog/essential-skills-for-senior-citizens), [Radar Oct 2026](https://radar.ph/its-never-too-late-for-lolos-and-lolas-to-learn-their-way-around-digital-services)).
- **[E]** Techie Seniors PH runs member-requested sessions, e.g. SIM registration ([Decade of Healthy Ageing](https://www.decadeofhealthyageing.org/find-knowledge/innovation/reports-from-the-field/techie-seniors-ph-(techie-seniors-training-meet-and-greet-sessions-techie-seniors-quiz-bee))).
- **[I]** Most of this is phone-first. Laptop "requirements" tasks fall to the family.

---

## 4. Five demo-worthy goals (Mac, 5-minute demo)

**Ground rules:**
- **[I]** Rehearse each exact phrase 10× on the demo Mac and keep it only if it passes every time (POSITIONING §6).
- Several goals below are **held-out test goals**. Demoing them is fine. Don't change the model or training data because of how they do in rehearsal (AGENTS.md rule 4).
- Paths are written for macOS 26. Verify on the demo machine.

| # | Say it like Lola (EN / Taglish) | App or site | Expected click path | Why it scores | Readiness and risk |
|---|---|---|---|---|---|
| **1. OFFLINE** | "Make this photo smaller so I can email it to my daughter." / "Paliitin natin yung picture para ma-email ko kay Anak." | **Preview** (Wi-Fi off on camera) | 1. `Tools` menu<br>2. `Adjust Size…`<br>3. Ring the **Fit into** pop-up and choose a preset (e.g. 1024×768) so there's no typing<br>4. `OK`<br>5. `File` menu<br>6. `Export…`<br>7. `Save` | It's the classic family-support task (#11). It's multi-step and runs fully offline. | Held-out goal; Preview group 7/10 on v3. Rehearse one deliberate wrong menu to show the calm redirect. |
| **2. OFFLINE** | "My grandson says he can't see me on the video call." / "Hindi daw ako nakikita ng apo ko sa video call." | **System Settings** | 1. Apple menu<br>2. `System Settings…`<br>3. `Privacy & Security`<br>4. `Camera`<br>5. Toggle **Google Chrome** (or zoom.us)<br>6. `Quit & Reopen` | It's the most painful helper task (§2 rank 1), it's very relatable for OFW families, and it's 4–5 steps deep. | **Not in any benchmark yet.** **[I]** The toggle may ask for Touch ID or the password; the user enters it. The app only appears after it has asked for the camera once. Test, and add to val (not test). |
| **3** | "Make the letters on the screen bigger, I can't read them." / "Paano palakihin yung letters sa screen? Hindi ko mabasa." | **System Settings** | 1. `System Settings…`<br>2. `Accessibility`<br>3. `Display`<br>4. Text size<br><br>Alternative: `Displays`, then `Larger Text` | It's universal (#18) and shows Taglish understanding. | Held-out family; System Settings group 6/8. Both paths are valid, so accept either. |
| **4** | "I want to watch how to cook adobo, and turn on the words at the bottom." / "Hanapin natin kung paano magluto ng adobo, tapos lagyan ng subtitles." | **YouTube** in Chrome | 1. Search box (the user types "adobo")<br>2. Search button<br>3. First video<br>4. **CC / Subtitles** button<br>5. Optionally, **Full screen** ("Pakilakihin yung video") | It's relatable to judges, multi-step, and a web page. | YouTube group 8/10. The search and captions goals exist in the fixtures. |
| **5** | "I want to check my PhilHealth contributions." / "Gusto kong makita yung hulog ko sa PhilHealth." | **philhealth.gov.ph** in Chrome | 1. Ring the member portal / online services link<br>2. Member login<br>3. Stop at the login: "Type your PIN here"<br>4. Narrate that the page never leaves the Mac | It's the PH problem, the DPA and anti-scam story, and it's real. | **Weakest group (7/15).** Use a fixed rehearsed path and a demo account, and **never show real PINs**. Fallback: Shopee "Paano ko makikita yung mga nilagay ko sa cart?" (6/10), or SSS ACOP (untested). |

**Optional anti-scam beat** (only if it's built and rehearsed):
- Open a *local* fake "Your Mac is infected, call…" page and say "May lumabas na warning, sabi tumawag daw ako."
- Gabay rings `Chrome > Quit Google Chrome` (or `Apple menu > Force Quit…`) and says: "Don't call the number. Let's close this."
- **[I]** Don't claim scam detection.

---

## 5. Target user and pitch vignettes

**Sharpened target-user statement [I]:**
> Gabay is for the **older Filipino, and the non-technical adult anywhere, who uses the family laptop for the jobs a phone does badly**: joining the video call with a child abroad, fixing "they can't see me", making the text readable, sending or printing a photo or form, and getting through SSS, PhilHealth, bank and shopping pages. Today they phone a daughter, son or grandchild (in the PH, 70% of the time it's one of them **[E]**), who can't see the screen and has to guess. Gabay sees exactly what's on *this* screen, rings the next button in plain English or Taglish, and lets them click it themselves. It never sends their IDs, PINs or health records anywhere, because the AI runs on the laptop.

**Three opening vignettes.** These are illustrative composites built from the evidence above, not real people. Say "imagine" on stage.
1. **Lola Remy, 68, Quezon City.**
   - Her daughter is a nurse in Riyadh. Sunday is video-call day on the laptop her daughter left her.
   - Today the call connects, but her daughter only sees a black square: "Ma, wala kang video!"
   - The setting that's blocking the camera is four screens deep. The one person who knows where it is, is the person on the other end of the broken call. *(Evidence: #9, §2 rank 1, the Messenger shutdowns.)*
2. **Tito Ben, 63, retired jeepney operator, Batangas.**
   - The hospital billing clerk asked for his PhilHealth record, and SSS wants his annual pension confirmation.
   - The site is full of links, and his son is on a night shift.
   - A Facebook page offers to "help" for ₱300, and a stranger on Messenger asks him to share his screen. *(Evidence: SSS's 20% registration and its warning about paid helper groups; the fake eGov screen-share scam in POSITIONING §3.)*
3. **Lola Cora, 74, Iloilo.**
   - Her granddaughter's school wants a scanned copy of Lola's senior ID and a photo by email, "smaller than 2 MB".
   - Lola has the photo on the laptop but can't make it smaller, can't find where the download went, and can't attach it.
   - Each step is easy for her granddaughter, who is 400 km away. *(Evidence: PSA says attachments are the top computer activity; #1, #11, #15.)*

---

## Gaps and caveats
- **Reddit was blocked** for both our crawler and the JSON API this session. There are no new r/AgingParents, r/talesfromtechsupport or r/sysadmin quotes; HN, MetaFilter and studies stand in.
- **No PH firsthand posts** (Facebook groups, Taglish forums) about teaching parents laptop tasks turned up. PH task evidence comes from surveys, news, curricula and official sites.
- Vendor lists (MicroSec, Half Price Geeks) don't publish their methods. MicroSec's "62% password problems" figure is unsourced and not used here.
- The claim that PhilHealth has no official app, and the PhilHealth portal details, come from unofficial guide sites. Verify them.
- Pag-IBIG and Meralco web flows were not checked.
- Gabay feasibility marks are our reading of current capability. Zoom's AX tree, facebook.com, and Chrome's own permission prompts are **untested**.
