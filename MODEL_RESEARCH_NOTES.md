# Jev and Laya: verified identities and laptop app fit

Researched 9 October 2026 using agent-reach's Jina Reader route, official documentation, upstream code and model cards, with web search fallback. No models installed or executed. Laya upstream HEAD observed: [`1adc59f7e371deb601fcfa18a14e25db238addcc`](https://github.com/NandhaKishorM/laya/tree/1adc59f7e371deb601fcfa18a14e25db238addcc). These are the user's actual spellings; neither needed substitution with JEPA or LLaVA.

## What they are

| | Jev by TypeSafe AI | Laya by Convai Innovations / Nandha Kishor M |
|---|---|---|
| Verified identity | TypeSafe's first public “System One” model | Open-weight, non-autoregressive decision engine |
| Main interaction | Supply state and bounded questions; receive typed decisions | Supply text state and bounded questions; receive typed decisions |
| Output | Choice, ordinal score, yes probability | Choice, ordinal score, yes probability |
| Public delivery | Hosted API and client SDK | Downloadable checkpoints and local runtime |
| Offline suitability | No public offline weights or self-host option verified | Yes, after provisioning weights and dependencies |

Jev gives up freeform string generation to make bounded decisions; its launch examples use structured/text game state, explicitly not images yet. Schema guarantees mean valid output types, not necessarily correct decisions. Advertised input price is **$0.042 per million tokens**, with output free. [Official launch](https://typesafe.ai/blog/introducing-system-one-models-and-jev)

TypeSafe's quickstart requires an API key and calls `https://api.typesafe.ai/v1/systemone`. Installing its Python SDK creates a remote client, not local Jev inference. No downloadable model license was verified. Consequently Jev's documented public route fails this project's cloud-free runtime requirement. [Official quickstart](https://docs.typesafe.ai/introduction/quickstart)

Laya is Apache-2.0 and supports local Python inference or a local HTTP server, including a Jev-compatible endpoint. API compatibility does not establish equivalent intelligence. Its English checkpoint is 421M parameters/512-token context; multilingual is 322M/default 1,024 tokens. Local directories avoid Hub access at inference. CPU, CUDA, MPS and XPU paths are documented. [Pinned upstream README](https://github.com/NandhaKishorM/laya/blob/1adc59f7e371deb601fcfa18a14e25db238addcc/README.md)

The main model card identifies a text-classification model, not a vision, speech or generative model. English/multilingual weight downloads are roughly 808/647 MB; disk weight size is not total runtime RAM. No vendor inference fee is needed for local execution; packaging, compute and any specialization remain our costs. [Official model card](https://huggingface.co/convaiinnovations/laya)

## The material limitation is decision quality

The specialist checkpoint reports **76.6%** on 2,000 typed decisions, versus base English **36.2%**. Its training domains are agent observability, customer service, invoices and security; that score does not transfer automatically to our editor or physics app. Its published Jev comparison uses different third-party runs, rather than a controlled head-to-head evaluation. [Specialist model card](https://huggingface.co/convaiinnovations/laya-typed-decisions), [upstream benchmark methodology](https://github.com/NandhaKishorM/laya/blob/1adc59f7e371deb601fcfa18a14e25db238addcc/BENCHMARKS.md)

**Negation is a concrete blocker to test.** The documented cancellation reproduction selected `cancel_account` for all four negated requests on English Laya and two on multilingual, one at probability 0.9998. Semantic option names did not solve it. This narrow test does not prove all negation fails, but directly challenges commands such as “undo colors, don't touch the layout.” [Upstream issue #377](https://github.com/NandhaKishorM/laya/issues/377)

The current README also warns that English yes/no decisions can follow option labels instead of state, and `action.act_probability` is almost always 1.0. A neutral-key choice and held-out task evaluation are sensible experiments, not proven fixes. [Pinned limitations](https://github.com/NandhaKishorM/laya/blob/1adc59f7e371deb601fcfa18a14e25db238addcc/README.md#limitations)

Disregarding hardware limits is reasonable for choosing the concept. For implementation, upstream measured four-question warmed calls at 192–453 ms on its Intel Mac Pro CPU and 121–146 ms on AMD Metal; those are vendor measurements on specified hardware, not our laptop benchmark. Its first Metal call compiled for about 13 seconds. [Reproducible local setup](https://github.com/NandhaKishorM/laya/blob/1adc59f7e371deb601fcfa18a14e25db238addcc/LOCAL_SETUP.md)

## Implications for the two concepts

These are proposed architectures, not capabilities already demonstrated by the models:

1. **Selective undo in an app-owned poster editor:** user says “undo my color experiments; keep text and layout.” Laya judges history events against a small `undo/keep/review` schema. Deterministic dependency-aware replay produces a visible preview before applying. The app already owns every object and edit; it needs no imported documents or external service. This is a strong interaction fit but the hardest Laya fit because exclusions and negation are central. A task-specific evaluation and likely fine-tuning must precede commitment.
2. **Prediction-versus-physics counterexample canvas:** user draws a setup, predicts motion, and types a physical claim. Laya maps that text to a bounded misconception/test class; a deterministic simulator searches and verifies a counterexample, displayed alongside the predicted trajectory. Native canvas geometry supplies structured state. Laya neither reads arbitrary sketches nor generates a simulator. This is the cleaner bounded-classification fit, provided held-out paraphrases work; solver verification gives the result its credibility.

Recommendation: use **Laya as a candidate local decision component**, not as the product idea or an assumed general reasoning engine. Jev supplies useful interface inspiration. An animated concept video can explain either interaction, but the working product should demonstrate actual offline decisions and deterministic execution rather than imply that a mock animation measures inference performance.
