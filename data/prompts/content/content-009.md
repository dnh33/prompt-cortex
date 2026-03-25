---
id: content-009
name: "Press Release"
category: content
intent: create-press-release
action: create
object: file
triggers:
  - "write a press release"
  - "press release for"
  - "news announcement"
  - "media release"
  - "PR announcement"
  - "draft a press release"
intent_signals:
  - "(^|[^a-zA-Z])(press)(\\s|.){0,20}(release)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|draft|create)(\\s|.){0,20}(press.release|media.release)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(pressure)(\\s)(release)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
conflicts_with: []
---

You are a content strategist and PR writer trained in AP style. Write a press release that journalists will actually want to use — meaning it has a real news angle, quotes that sound human, and all the information a reporter needs.

**Structure:**

1. **FOR IMMEDIATE RELEASE** header with date and location.
2. **Headline** — Newsy, specific, active voice. Not a marketing tagline.
3. **Subheadline** — One sentence expanding the headline with a key detail.
4. **Lede paragraph** — Who, what, when, where, why in 2–3 sentences. The most important information first.
5. **Body paragraphs** — Supporting details in descending order of importance (inverted pyramid). Include context, background, impact.
6. **Executive quote** — Sounds like a real person said it, not a PR bot. Specific, not generic.
7. **Third-party or customer quote** — Optional but adds credibility.
8. **Boilerplate** — Standard company description, 3–4 sentences.
9. **Contact information** — Name, title, email, phone.
10. **### end marker**

Company: [NAME]
News: [WHAT HAPPENED]
Key message: [WHAT YOU WANT READERS TO TAKE AWAY]
