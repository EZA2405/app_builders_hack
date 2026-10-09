# Gabay: positioning, users, and pitch prep

Research date: Oct 9, 2026. Sources are public pages only. Nothing was posted, submitted or signed up for.

**Legend:** **[E]** = evidence from a cited source. **[I]** = our inference or recommendation. Model numbers come only from `ml/RESULTS.md`, which were measured on our M4.

---

## TL;DR

- **Who:** older Filipinos and the family member who is their "24/7 tech support" (often abroad), doing high-stakes tasks on government and finance portals.
- **Why local, in one line:** these screens show government IDs, health records, OTPs and balances. Every PH bank and e-wallet tells people *never share your screen*, and a cloud screen assistant is a screen share.
- **Wedge vs HeyClicky:** same "point, don't click" interaction. Ours runs on the Mac, works offline for Mac apps, has no message cap, and nothing on screen leaves the device.
- **Honest weak spots:**
  - Mac is about 7% of PH desktop traffic.
  - Our local model is 26/35 on held-out apps, where a hosted frontier model scores 35/35.
  - The product is designed around being wrong sometimes: the user clicks, Gabay says when it's unsure, and it redirects calmly.

---

## 1. Target users and use cases, ranked

| # | User | Pain size (evidence) | What they do today | Why a pointing guide helps |
|---|---|---|---|---|
| 1 | **Older adults and their family helper** (incl. OFW families) | **[E]** Only 6% of older Filipinos use the internet, vs 43% of the general population ([PIDS, Sep 2025](https://www.pids.gov.ph/details/news/press-releases/ai-can-help-but-weak-support-systems-put-older-filipinos-at-risk)). About 6 in 10 rely on their children, and 18% get remittances (same source). Only 18% of people 65+ have even one basic ICT skill ([UN ESCAP workshop summary](https://jocellebatapasigue.com/2025/11/30/future-proofing-the-philippines-un-escap-signals-the-urgent-need-for-digital-inclusion-for-seniors/)). There are 11.42M Filipinos aged 60+ (10.2%) ([PSA 2024 census](https://psa.gov.ph/statistics/population-and-housing/node/1684083861)) and 2.19M OFWs ([PSA](https://www.gmanetwork.com/news/pinoyabroad/dispatch/969755/ofws-grew-to-2-19m-in-2024-psa/story/)). Firsthand: a parent can't describe their screen, and one email takes 20 minutes ([r/AgingParents](https://www.reddit.com/r/AgingParents/comments/1fzeqx5)); "losing my mind being their 24/7 tech support" ([r/AgingParents](https://www.reddit.com/r/AgingParents/comments/1lsy4m9/im_losing_my_mind_being_their_247_tech_support_is/)). | They phone or video-call a child, who tries to guess what's on the screen, or they share the screen. They queue at a branch. | **[I]** Help arrives at the moment of need without a person and without sharing the screen. The family helper stops being the bottleneck. |
| 2 | **First-time users of PH e-government and finance portals** (eGovPH, My.SSS, PhilHealth, Pag-IBIG, Meralco, online banking) | **[E]** Over 1M seniors signed up for the digital senior ID on eGovPH. A 72-year-old needed DICT staff to set up his account ([PIA](https://pia.gov.ph/digital-senior-citizens-id-now-accessible-through-egov-ph-app/)). App reviews cite verification and slowness problems ([Inquirer](https://technology.inquirer.net/147360/egov-app-a-digital-government-halfway-there)). SSS added an online face check for pensioners in 2026 so they could skip My.SSS ([SSS](https://www.sss.gov.ph/news-and-updates/sss-launches-facial-authentication-for-annual-confirmation-of-pensioners-with-liveness-check/)). That is a sign the portal itself is a barrier. | Branch visits, fixers, asking strangers. Fake "eGov helpers" on video calls (see §3). | **[I]** These are the most sensitive screens (IDs, SSS numbers, health records), so they are where local matters most. Our web held-out set already includes PhilHealth. |
| 3 | **Micro and small business owners** (BIR ORUS/eFPS/eBIRForms, invoicing) | **[E]** A Batangas taxpayer spent 4 days registering a sari-sari store. The BIR Commissioner admitted ORUS "sometimes goes down" ([GMA](https://www.gmanetwork.com/news/money/personalfinance/982824/taxpayers-face-delays-inconvenience-in-bir-process-document-handling/story/)). BIR eLounges cap help at 3 transactions or 1 hour per day ([summary of RMC 34-2025](https://businessregistrationphilippines.com/ebirforms-filing-requirements-2025-rr-no-6-2014-rmc-no-34-2025/)). On Oct 9, 2026 the BIR warned of a fake ORUS site ([Tribune](https://tribune.net.ph/2026/10/09/bir-warns-taxpayers-against-fake-orus-website)). | Bookkeepers, RDO eLounges, YouTube tutorials. | **[I]** The screens show tax returns, which are Sensitive PI under the DPA. The audience is desktop-heavy. Deadlines bring urgency. |
| 4 | **BPO and IT help desks onboarding staff to internal tools** | **[E]** The IT-BPM workforce is 1.9M (2025) ([IBPAP via Inquirer](https://business.inquirer.net/567026/it-bpm-industry-in-ph-outpaced-global-growth-in-2025)). The enterprise "digital adoption" category is proven: SAP bought WalkMe for $1.5B ([Orrick](https://www.orrick.com/en/News/2024/06/SAP-Agrees-to-Acquire-WalkMe-Enriching-SAPs-Business-AI-Solutions)). Among organizations, 27% banned GenAI apps and 63% limit what data can be entered ([Cisco 2024 via Security Magazine / CFO Dive](https://www.cfodive.com/news/one-in-four-companies-ban-genai/705966/)). | Shadowing, wikis, scripted DAP tours that someone has to author by hand. | **[I]** Works on any internal app with no authored tours. No screen data leaves the client's network, so it passes policies that block cloud screen tools. This is the strongest **business** case, but it is not the demo story. |
| 5 | **Digital-literacy centers** (Tech4ED/DTC, LGU senior offices, libraries) | **[E]** Tech4ED had about 2,683 centers by 2018, and "Digital Literacy for Senior Citizens" is a listed service ([Tech4ED handbook](https://anyflip.com/jsqu/epko/basic)). In 2019, 4G reached 43.8% of rural barangays vs 82.6% of urban ones ([DICT policy note](https://ictstatistics.dict.gov.ph/wp-content/uploads/2022/06/1_Policy-Note_Digital-Infrastructure.pdf)). | One facilitator for many learners. | **[I]** A patient helper on every seat that keeps working on a weak or absent uplink. |
| 6 | **People with low vision** | **[E]** About 2.17M Filipinos have visual impairment, mostly cataract and refractive error ([DOH via SunStar](https://www.sunstar.com.ph/manila/doh-217-million-filipinos-suffer-from-visual-impairment); [PERI](https://www.peri.ph/philippine-eye-disease-study)). | Zoom, a family member reading the screen. | **[I]** A large ring plus one plain sentence helps people with partial sight. It is **not** a screen-reader replacement; don't pitch it as one. |
| 7 | Teachers and students | **[I]** Lower pain and already tech-comfortable. | | Mention as an adjacent group only. |

**[I] Sharp wedge for the pitch:** rank 1 doing rank 2 tasks. That means *"Lola paying the Meralco bill / checking PhilHealth on the laptop the kids left her"*. Rank 4 is the business model answer.

---

## 2. Why local beats cloud for *this* product

| Argument | Evidence | Strength |
|---|---|---|
| **The screen is legally sensitive** | **[E]** DPA RA 10173 §3(l) defines *sensitive personal information* to include health, and government-issued identifiers "including… social security numbers, previous or current health records, licenses… and tax returns." Processing it is generally prohibited except under §13 ([Lawphil](https://lawphil.net/statutes/repacts/ra2012/ra_10173_2012.html); [NPC](https://privacy.gov.ph/data-privacy-act/)). **[I]** These are exactly the screens in our target tasks. A cloud guide becomes a processor of that data. A local guide never receives it. *(Not legal advice.)* | **Strong** |
| **PH has been burned by health-data breaches** | **[E]** The 2023 PhilHealth Medusa ransomware leak covered about 42M individuals, including medical records and senior-citizen records ([GMA, NPC](https://www.gmanetwork.com/news/topstories/nation/912661/2023-philhealth-data-breach-affected-42m-individuals-official/story/)). **[I]** "Data that never leaves can't leak" lands with a PH audience. | Strong (emotional) |
| **It contradicts the anti-scam advice people are given** | **[E]** GCash tells users to "never share your OTP, MPIN, passwords or screen" ([GCash/Mynt](https://mynt.com.ph/newsroom/gcash-cautions-the-public-against-new-scams-forcing-users-to-download-fake-mobile-apps-from-suspicious-websites)). PNP-ACG and GCash jointly warned about screen-sharing scams ([MegaBites, May 2025](https://www.megabites.com.ph/pnp-acg-gcash-alert-public-on-emerging-shoulder-surfing-video-and-screen-sharing-scams/)). **[I]** A cloud screen assistant asks seniors to make an exception to the one rule they've been taught. Gabay doesn't need that exception. | **Strong, and unique to this product** |
| **Enterprise, bank and government deployability** | **[E]** Samsung banned GenAI tools after a code leak ([Bloomberg](https://www.bloomberg.com/news/articles/2023-05-02/samsung-bans-chatgpt-and-other-generative-ai-use-by-staff-after-leak)). 27% of organizations ban GenAI ([CFO Dive/Cisco](https://www.cfodive.com/news/one-in-four-companies-ban-genai/705966/)). BSP outsourcing rules (Circ. 1137, MORB App. 78) require banks to inventory data processed through outsourcing and to manage where it is stored ([MORB App. 78](https://morb.bsp.gov.ph/appendix-78-2/); [Outsource Accelerator](https://news.outsourceaccelerator.com/bsp-amends-it-outsourcing-risk-management-rules/)). **[I]** A local model is not an outsourcing arrangement and can run air-gapped. | Strong (B2B) |
| **Offline and poor connectivity** | **[E]** 48.8% of households had home internet in 2024; Zamboanga Peninsula 21.2% and BARMM 27.7%; cost is the top barrier (63.5%) ([PSA via Insider PH](https://insiderph.com/internet-access-in-ph-expands-but-cost-still-a-barrier-psa-dict-survey); [PSA on X](https://x.com/PSAgovph/status/1951192521130037488)). Typhoon Uwan cut power to about 2.9M–4.7M households ([PNA](https://www.pna.gov.ph/articles/1262921); [BusinessMirror](https://businessmirror.com.ph/2025/11/10/power-outages-affect-4-7%E2%80%91m-households-as-uwan-disrupts-electric-supply-nationwide/)). The May 2026 red-alert rotating brownouts hit about 1.9M Meralco customers ([GMA](https://www.gmanetwork.com/news/money/economy/987493/ngcp-brownouts-alerts-luzon-grid/story/)). **[I]** During a brownout the laptop runs on battery but the router is down. Gabay still guides Mac apps then. Web tasks still need the site to load. | Medium. True for Mac apps, but most target tasks are web tasks that need internet anyway |
| **No per-use cost or caps** | **[E]** HeyClicky Free gives 25 talk messages a month. Pro is $20/mo and Max is $100/mo ([heyclicky.com](https://www.heyclicky.com/)). Copilot Vision requires a Microsoft 365 subscription ([Microsoft](https://support.microsoft.com/en-us/topic/using-copilot-vision-with-microsoft-copilot-3c67686f-fa97-40f6-8a3e-0e45265d425f)). **[I]** $20 is about ₱1,150 a month. A confused senior asks many times per task. Local marginal cost is zero, so it can be free for individuals and run on unlimited seats in a Tech4ED center. | Medium–strong |
| **Mobile-data cost** | **[E]** Prepaid data is about ₱5–8/GB ([DICT via TelecomLead](https://telecomlead.com/4g-lte/philippines-mobile-speed-jumps-73-as-dict-tracks-5g-coverage-data-costs-and-network-performance-127393)). | **Weak. Don't lead with it.** Screenshots are cheap to upload |
| **Latency** | **[E, ours]** 1.2–2.2 s per decision on the M4 for menu tasks (`ml/RESULTS.md`). We have not measured HeyClicky. | **Don't claim we're faster.** Say instead: "about as fast, and it doesn't depend on the connection." |

---

## 3. Anti-scam angle

**Evidence: scams that run on "let me help you with your screen"**
- **[E] PH, 2026:** a fake eGovPH / National ID scam.
  - Scammers call, move the victim to a Google Meet, then **guide them step by step while the victim shares their screen**, and get them to install a fake eGovPH app. That app is a banking trojan with 44 variants ([Trend Micro](https://news.trendmicro.com/2026/04/24/fake-egovph-app/); [GMA](https://www.gmanetwork.com/news/topstories/nation/975001/filipinos-warned-against-downloading-fake-egovph-app/story/); [PSA via PIA](https://pia.gov.ph/news/psa-warns-public-vs-scam-on-national-id/)).
  - **[I] This is our product's interaction, run by a criminal.** Gabay is the legitimate version: it walks you through the steps and nobody else sees the screen.
- **[E] PH scale:**
  - 52% of Filipinos have been scammed at least once, the highest rate in ASEAN ([GSMA, Nov 2025](https://www.gsma.com/newsroom/press-release/rising-scam-exposure-in-the-philippines-underscores-need-for-cross-sector-action-warns-new-gsma-report/)).
  - The CICC logged 18,633 cybercrime complaints in 2025. Consumer fraud was the top complaint among seniors ([GMA](https://www.gmanetwork.com/news/topstories/nation/977680/consumer-fraud-topped-complaints-logged-among-senior-citizens-in-2025-cicc/story/)).
  - In 2024, GCash was the platform behind ₱76.49M of reported losses ([Inquirer](https://technology.inquirer.net/140281/cicc-gets-10000-complaints-vs-online-scams-in-2024-tripling-past-years-list)).
- **[E] Global:**
  - Tech-support scams cost US victims 60+ **$982M in 2024** from 16,777 complaints. That is about two-thirds of all tech-support losses ([FBI IC3 2024](https://www.ic3.gov/AnnualReport/Reports/2024_IC3Report.pdf); [AARP](https://www.aarp.org/money/scams-fraud/fbi-report-fraud-2024/)).
  - People 60+ are about 5× more likely to lose money to them. The FTC's advice is to "never give control of your computer… to anyone who contacts you" ([FTC](https://www.ftc.gov/news-events/data-visualizations/data-spotlight/2019/03/older-adults-hardest-hit-tech-support-scams)).
  - 59% of consumers in 16 countries encountered a tech-support scam in a year ([Microsoft/YouGov 2021](https://blogs.microsoft.com/on-the-issues/2021/07/21/tech-support-scams-adapt-2021-microsoft-study/)).

**[I] How to frame it (honest):**
- Gabay doesn't *detect* scams. It removes the *reason* to let a stranger in. "If you need help, you don't need a stranger, and you don't need to share your screen."
- **Points, never clicks:** there is no remote control to hijack.
- **Nothing leaves the Mac:** there is no stream for anyone to watch.
- **Optional, only if built and tested:** a calm refusal when a goal includes "install AnyDesk/TeamViewer", "the caller told me to…", or "share my screen". For example: *"Banks and GCash never ask for this. Let's stop here and call your child."* Don't claim it in the pitch unless it's working live.

---

## 4. Positioning

**Statement:**
> For older Filipinos and the families who are their tech support, **Gabay** is a patient guide on the Mac. It rings the exact button to click next, one plain step at a time, in English or Taglish. Cloud screen assistants send your screen to someone else's computer. Gabay's AI runs on the Mac itself, so your IDs, OTPs and health records never leave it, it works without internet for Mac apps, and it never costs per question.

**Three pitch lines:**
1. *"Every bank tells Lola: never share your screen. Gabay is help that never asks her to."*
2. *"It points, she clicks. Gabay never touches the mouse, so there's nothing to hijack."*
3. *"A 0.4-billion-parameter model on a laptop, no internet, ringing the right button in apps it has never seen."*
   - Only say this if the demo shows it. Our held-out score is 26 of 35.

**Gabay vs HeyClicky**

| | **Gabay** | **HeyClicky** ([site](https://www.heyclicky.com/), [review](https://hokai.io/hub/tools/heyclicky)) |
|---|---|---|
| Interaction | Ring on the exact control plus one sentence; confirms each step; redirects on wrong turns; says "not sure, one of these two" | Voice answer, a cursor that points, walkthroughs (up to 15 steps per [The Rundown](https://www.therundown.ai/tools/clicky)) |
| Who acts | **User only. Never clicks.** | User, plus an **agent mode** that acts for you |
| Where AI runs | **On the Mac** (fine-tuned Laya, about 0.4B) | Cloud. The open-source Clicky sends a screenshot to Claude via a proxy ([repo](https://github.com/farzaa/clicky)); a review lists Anthropic/OpenAI ([hokai](https://hokai.io/hub/tools/heyclicky)) |
| What it reads | Accessibility tree / DOM (real control names) | Screenshots (pixels) |
| Screen leaves device | **No** | Yes, on hotkey. "Screenshots never stored," but text summaries are kept |
| Offline | **Yes for Mac apps** | No |
| Cost | No per-use cost | 25 msgs/mo free; $20 or $100 a month |
| Accuracy | 26/35 held-out apps, 29/45 held-out web steps (measured) | Frontier models, likely higher (not measured by us) |
| Audience | Seniors and non-technical adults; Taglish; calm language | Broad consumers and power users ("spawn agents") |

**Others, briefly:**
- **[Copilot Vision](https://support.microsoft.com/en-us/topic/using-copilot-vision-with-microsoft-copilot-3c67686f-fa97-40f6-8a3e-0e45265d425f):** highlights controls and won't click. Screen data is processed in Microsoft's cloud ([The Register](https://www.theregister.com/2025/07/23/microsoft_copilot_vision/)). Needs M365.
- **[Peek](https://usepeek.app/compare/heyclicky-alternative/):** voice runs on the Mac; it doesn't say where screen understanding runs.
- **[Guidy](https://guidy.ai/blog/guidy-vs-heyclicky/):** points and waits; "trusted AI providers."
- **GuideLayer:** uses Codex/Claude API keys.
- **ScreenDone:** Gemini cloud.
- **Metis:** Windows; claims Ollama offline, unverified.

**[I] Our defensible difference** is not "pointing" (common). It is **pointing with no cloud, built for the person scammers target.**

---

## 5. Judge Q&A: 8 hardest questions

1. **"HeyClicky (YC) already does this."**
   - Yes, and that proves people want it.
   - HeyClicky sends your screen to the cloud, caps free use at 25 messages, has an agent that clicks for you, and doesn't work offline. Ours runs on the laptop, never clicks, and is built for the person banks tell never to share a screen.
   - Same interaction, opposite trust model.
2. **"Why not just use ChatGPT / Gemini Live?"**
   - They see pixels in the cloud, and they describe instead of pointing at the exact control.
   - Using them means sharing your screen, which is what GCash and the PNP tell people not to do.
   - They need internet and a subscription.
3. **"How accurate can a 0.4B model be?"**
   - Measured on apps it never trained on: **26/35** (Preview, Finder, System Settings, Safari) and **29/45** web steps (YouTube, Wikipedia, Shopee, PhilHealth).
   - The hosted frontier reference scores 35/35, so there is a real gap, and we report it.
   - It works because macOS gives us the real control names. The model only has to *rank* real candidates, not find pixels.
   - Distilled from a frontier teacher; 74.8% full-tournament validation on unseen apps.
4. **"What if it points to the wrong thing?"**
   - The user clicks, so a wrong point costs one click, not an action.
   - Gabay checks the result after each step and redirects calmly.
   - When its confidence is low it says "I'm not sure, it's one of these two." The fine-tuned model's confidence is calibrated: validation ECE is about 0.07, down from 0.44–0.49 for the base model.
5. **"Macs are a small share in the Philippines. What about Windows and phones?"**
   - True: Mac is about 7% of PH desktop traffic ([StatCounter](https://gs.statcounter.com/os-market-share/desktop/philippines)), and Android leads overall.
   - Mac first because macOS exposes every control's name and Apple Silicon runs the model well.
   - The design ports: Windows UI Automation and Android Accessibility expose the same kind of tree. The Chrome extension already covers web pages.
   - Not built yet. Say so.
6. **"What's the business model if it's free?"**
   - Free for families, because the model runs on their device and costs us nothing per use.
   - Revenue comes from orgs that *can't* use cloud screen tools: BPO/enterprise onboarding (digital adoption is a proven category, e.g. SAP–WalkMe, $1.5B), banks and LGU/Tech4ED site licenses.
   - Our pitch to them: deploys air-gapped, and no screen data leaves the network.
7. **"Is it actually local? What needs the internet?"**
   - Choosing the next control (Laya) and dictation run on the Mac.
   - Web pages need the internet to load, but the page contents only go to the local model over 127.0.0.1.
   - We'll show Wi-Fi off on a Mac app.
   - Disclose any optional cloud relay that exists in the code (the repo has a Jev relay for development and comparison). Make clear the demo path doesn't use it.
8. **"Couldn't scammers misuse a guide, or point Lola at the wrong thing?"**
   - There's no remote side: no account, no stream, no one to connect in. It can't click.
   - The worst case is a wrong ring, which the user sees and can ignore.
   - Bonus if built: it refuses to walk anyone through installing remote-access apps.

*Reserve:*
- **"Is the problem real?"** Only 6% of older Filipinos are online, about 60% rely on their children, and the 2026 fake-eGov screen-share scam is a criminal copy of our exact interaction.
- **"Why Taglish?"** That's how people actually ask: "paano palakihin yung letters".

---

## 6. Demo task recommendations (5 minutes)

**[I] Choose goals by rehearsal, not by hope.** Run each exact goal 10× on the demo Mac first, and keep the ones that pass every time. Have a fallback goal in the same app.

| Order | Task | Why it scores | Notes and risk |
|---|---|---|---|
| **1 (Wi-Fi OFF, on screen)** | **Preview: "make this photo smaller so I can email it"**. Make one deliberate wrong click so Gabay redirects calmly. | Local AI is real (25%), it works live (20%), and the original family-support story | Turn Wi-Fi off in Control Center *on camera* and leave the menu-bar icon visible. Preview is held-out (7/10), so rehearse the exact phrasing. Optional: show Activity Monitor network at 0. |
| **2** | **Taglish System Settings goal: "paano palakihin yung letters sa screen"** (or "turn on dark mode"). Show a "not sure, one of these two" moment if it occurs naturally. | Innovation and UX for older users; honesty about uncertainty | System Settings is 6/8 held-out. Don't stage fake uncertainty. |
| **3 (Wi-Fi back on)** | **A PH portal in Chrome**, e.g. "where do I see my PhilHealth contributions" or a Meralco/eGov page. Narrate: "This page shows her PhilHealth number. It goes to the model on this Mac, not to any server." | Problem and usefulness (25%); the anti-scam and DPA story | PhilHealth is the **weakest held-out site (7/15)**. Rehearse one fixed path, or fall back to YouTube "turn on captions" (8/10). Use a demo or test account; never show real personal data on stage. |

**Suggested 5-minute flow:**

| Time | Beat |
|---|---|
| 0:00–0:40 | Problem: "Lola, the scam call, and never share your screen" |
| 0:40–2:10 | Demo 1, Wi-Fi off |
| 2:10–3:00 | Demo 2, Taglish |
| 3:00–4:10 | Demo 3, PH portal |
| 4:10–5:00 | Measured accuracy slide, Gabay vs HeyClicky in one line, and the ask |

---

## Gaps and caveats

**Not found:**
- Firsthand **PH** Reddit/X posts about teaching parents GCash or portals (the search returned nothing usable).
- An official BSP advisory naming AnyDesk.
- A 2024 urban/rural breakdown of home internet.

**Not verified:**
- HeyClicky's exact model providers. The site doesn't say; the provider list comes from a third-party review plus the open-source client.
- How Copilot Vision handles data today: launch-era reporting says it's processed in the cloud, and Microsoft's support page doesn't say.

**Legal:** DPA and BSP points are our reading of public texts, not legal advice.
