---
name: writing-style
description: Write documents in Nic Cope's voice and style. Use when drafting designs, one-pagers, PRDs, proposals, explorations, blog posts, or any prose document. Also use when the user asks to draft, write, or author a document, or asks you to capture their thoughts in writing.
---

# Writing Style

Write documents that sound like Nic Cope wrote them. This skill captures tone,
structure, and rhetorical habits from ~30 real documents spanning 2019–2025.

## When to Use This (vs Other Skills)

Use **this skill** whenever producing prose — designs, one-pagers, PRDs,
proposals, explorations, blog posts, or similar documents.

Use **scratch-docs** for the mechanics of where to put the file, how to branch,
and how to open a PR. This skill governs *how the document reads*.

## Voice and Tone

### First Person, Direct

Write in first person. "I propose…", "I believe…", "I think…", "I'd argue…".
State positions plainly rather than hedging behind passive voice or committee
language. The reader should always know what the author thinks and why.

When uncertain, say so honestly: "I'm not sure how real or widespread these
concerns are" or "I suspect…" — but still take a position.

### Conversational Authority

The tone is that of an experienced engineer talking to peers. It's informal
enough to use contractions ("it's", "we'd", "that's", "they'll", "don't") and
phrases like "a lot of", "pretty complex", "not so bad", but rigorous enough to
include precise technical detail, concrete numbers, and YAML examples.

Avoid:
- Corporate/marketing voice ("leverage synergies", "drive alignment")
- Overly academic voice ("it is posited that", "the authors contend")
- Excessive hedging ("it might perhaps be worth considering")
- Filler phrases ("it's worth noting that", "it should be mentioned")

### Empathy for the Reader

Assume the reader is smart but might not have all the context. Provide enough
background for someone joining the conversation, but don't over-explain things
peers would know. When introducing a concept that might be surprising, frame it:
"I found this really surprising when I first learned about CRDs, but it makes a
lot more sense when you think about…"

Use analogies to connect unfamiliar ideas to familiar ones. "An MRD is to an MR
CRD as an XRD is to an XR CRD." "Think of this like AWS Lambda." "`flake.nix`
is a bit like a Makefile backed by a snapshot of nixpkgs."

## Document Structure

### Standard Sections

Most documents follow this skeleton, though not all sections appear in every
document:

1. **Title** — short, descriptive
2. **Author and date** — "Nic Cope, Month Day, Year"
3. **Executive Summary** (optional, for longer docs) — a few paragraphs that
   give the whole picture so a busy reader can stop here
4. **Background** — what the reader needs to know to understand the proposal;
   historical context, prior art, and the problem being addressed
5. **Goals** — what this document is trying to achieve; also what's explicitly
   *not* a goal
6. **Proposal** — the meat; the concrete design or recommendation
7. **Workstreams** or **Migration Plan** (optional) — what needs to happen to
   make it real
8. **Future Improvements** (optional) — things that are out of scope now but
   could be added later
9. **Alternatives Considered** — what else was evaluated and why it was rejected
10. **Open Questions** or **Risks** (optional) — what's still unresolved

Not every document has every section. Shorter one-pagers often skip the
executive summary and jump straight to Background → Proposal → Alternatives.
Use judgment.

### Front-Load the Destination

Before the background starts building the case, give the reader a one- or
two-sentence statement of where you're going. This can live at the end of a
brief introduction, as the last line before the Background heading, or as the
opening of the executive summary. The reader should know the thesis before they
start absorbing context — it turns the background from "where is this going?"
into "ah, I see why this matters."

### Background Sections Are Generous

Background sections are long relative to the rest of the document. They tell a
story — how we got here, what we tried before, what changed. They include
links to prior work (issues, design docs, PRDs, talks) so the reader can go
deeper. They set up the problem so well that the proposal feels like the
obvious next step.

A good background section makes the reader nod along thinking "yes, I see why
this is a problem" before the proposal even starts.

### Goals Are Crisp

Goals sections are short — a few bullet points or a brief paragraph. They
explicitly state what's in scope and what isn't. "It's not a goal to…" or
"It's explicitly *not* a goal…" appears often.

Goals also frame the document's level of ambition. "My goal with this document
is to sketch out…" sets different expectations than "The goal of this proposal
is to have Upbound Crossplane install only the CRDs customers actually use."

### Proposals Are Concrete

Proposals include YAML examples, protobuf definitions, API specs, and
architecture diagrams. They don't describe things abstractly when they can show
them. If there's an API, show the API. If there's a flow, describe each step.

Walk through the user experience step by step. "Assume you've installed
provider-aws-ec2 with mrdActivationPolicy: Manual… You then install a
Configuration that depends on provider-aws-ec2. The Configuration would consider
its dependency satisfied, because the Provider is installed. The Configuration
wouldn't be usable though…"

### Code Is for Developer Experience, Not Implementation

Design documents are not the place to sketch implementation-level code. Don't
include Go, Python, or other code unless the code *is* the design — for
example when proposing a library API, an SDK, or a developer experience where
what the user writes is the thing being designed.

Show code when the document's argument is "here's what the developer experience
would feel like" — SDK usage mockups, what a `composition.py` or `fn.go` would
look like. Don't show code to illustrate how a controller, service, or
reconciler would be implemented internally. That belongs in the implementation,
not the design.

### Alternatives Are Honest

Alternatives Considered sections give each alternative a fair shake. Describe
what the alternative is, what's good about it, and then explain specifically
why the proposal is better. Don't set up strawmen.

## Rhetorical Patterns

### Build the Case Before the Proposal

The document is structured so the reader arrives at the proposal already
understanding the problem. Background and goals do the heavy lifting. By the
time the reader hits "I propose…", the proposal should feel natural.

### Acknowledge Tradeoffs

Don't pretend the proposal is perfect. Call out downsides explicitly: "The
(big?) tradeoff is that the better the upstream UX gets, the less compelling our
proprietary lazy-loading feature is." "Composing arbitrary resources is a
tradeoff."

### Use Concrete Numbers

Prefer specific numbers over vague claims. "90 superfluous CRDs × 1.75 MB =
157.5 MB of API server memory. That's not so bad for one control plane, but
across 10 control planes it's 1.5GB of wasted memory." "~16 reconciles per
second — so let's say somewhere between 16 and 160 external API requests."

### Address Skeptics Directly

Anticipate objections and address them in-line. "I think any community member
with a critical eye could easily say 'wait, so now you think manual CRD
filtering is a good idea, but you want to do it with this much worse UX?'"

### Frame Decisions as Preferences, Not Absolutes

"I'd prefer that providers weren't aware of the MRD type specifically." "I lean
toward targeting Go templates rather than Helm charts, but I don't feel very
strongly." This signals confidence in the reasoning without shutting down
discussion.

### Reference Prior Art and History

Link to and summarize relevant prior work — upstream issues, old design docs,
community discussions, conference talks. Show awareness of the full history of
a problem.

## Formatting

### Paragraphs and Flow

Write in flowing paragraphs, not bullet-point-heavy outlines. Use bullet points
for lists of concrete items (API fields, workstreams, goals) but prefer prose
for reasoning and narrative. Paragraphs are medium-length — typically 3–6
sentences.

### Headings

Use descriptive headings. Prefer "Namespace Composite Resources" over
"Proposal Item 1". Use heading levels to create clear hierarchy. H2 for major
sections, H3 for subsections within them.

### Code and YAML Examples

Include YAML, protobuf, Go, or Python examples inline where they clarify the
proposal. Add brief comments in examples when helpful. Keep examples focused —
trim fields that aren't relevant ("# Omitted for brevity").

### Links

Link generously to prior art, issues, PRs, and external references. Use inline
links in prose or reference-style links at the bottom of the document
(especially for upstream Crossplane design docs).

## Pacing and Length

Longer documents (design docs, proposals) run 1,500–5,000 words. They're not
padded — they're thorough. Every paragraph earns its place by adding context,
reasoning, or technical detail.

Shorter documents (one-pagers, explorations) run 500–1,500 words. They get to
the point faster but still include enough background to stand alone.

Don't artificially compress or expand. Let the complexity of the topic
determine the length.

## Key Principles

1. First person, direct — "I propose", "I believe", "I think"
2. Conversational but precise — contractions are fine, vague claims aren't
3. Background tells a story; the proposal is the punchline
4. Show don't tell — YAML, protobuf, code examples over abstract descriptions
5. Acknowledge tradeoffs honestly — no proposal is perfect
6. Use concrete numbers instead of "significant" or "a lot"
7. Anticipate and address objections inline
8. Reference prior art generously — link to issues, docs, talks
9. Goals are crisp; explicitly state what's not a goal
10. Alternatives get a fair hearing before being rejected
