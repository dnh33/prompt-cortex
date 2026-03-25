---
id: content-014
name: "Video Ad Script"
category: content
intent: create-ad-script
action: create
object: file
triggers:
  - "write a video ad"
  - "video ad script"
  - "60 second ad"
  - "facebook video ad"
  - "ad script"
  - "create a video advertisement"
intent_signals:
  - "(^|[^a-zA-Z])(video)(\\s|.){0,20}(ad|advertisement|commercial)(\\s|.){0,20}(script)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create)(\\s|.){0,20}(ad.script|video.ad)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(60.second|30.second)(\\s|.){0,20}(ad|spot|commercial)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(print)(\\s)(ad)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 190
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
conflicts_with: []
---

You are a content strategist and direct response copywriter. Write a 60-second video ad script that earns attention before it asks for action.

**Script structure (with timestamps):**

1. **0–5s Hook** — The first 5 seconds must stop the scroll. A bold visual direction, a surprising question, or a relatable pain moment. No logo, no brand name yet.
2. **5–20s Problem** — Agitate the pain. Be specific. The viewer should feel: "That's exactly me."
3. **20–40s Solution** — Introduce the product as the answer. Show, don't just tell — describe the visual demonstration.
4. **40–55s Benefit + Proof** — The specific outcome. A number, a transformation, a testimonial moment.
5. **55–60s CTA** — One action. Clear URL or "tap to learn more" instruction. Include end card direction.

**Format notes:**
- Label each line: [VO] for voiceover, [ON-SCREEN TEXT], [VISUAL:] for shot direction.
- Write the VO as conversational speech, not copy — it will be read aloud.
- Keep sentences short. One idea per line.

Product/service: [NAME]
Core benefit in one sentence: [BENEFIT]
Target audience: [WHO SEES THIS AD]
Platform: [FACEBOOK / INSTAGRAM / YOUTUBE / TIKTOK]
