---
id: content-021
name: "Interview Questions"
category: content
intent: create-questions
action: create
object: file
triggers:
  - "interview questions"
  - "questions for interview"
  - "write interview questions"
  - "podcast interview questions"
  - "journalist questions"
  - "questions to ask"
intent_signals:
  - "(^|[^a-zA-Z])(interview)(\\s|.){0,20}(questions|prep|guide)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create|generate)(\\s|.){0,20}(interview.questions)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(questions)(\\s|.){0,20}(to.ask)(\\s|.){0,20}(guest|expert|speaker)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(job)(\\s)(interview)(\\s)(questions)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 180
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
conflicts_with: []
---

You are a content strategist and experienced interviewer. Write 20 questions designed to draw out quotable, specific, story-rich answers — not generic responses the guest has given a hundred times before.

**Question categories (4–5 questions each):**

1. **Origin and belief** — What shaped their thinking? What do they believe that most people in their field don't?
2. **Concrete experience** — Specific stories, decisions, failures. "Tell me about a time..." style, but varied.
3. **Counterintuitive insight** — Questions designed to surface the non-obvious. Challenge them gently.
4. **Process and craft** — How they actually do their work. Behind-the-scenes, practical.
5. **Future and advice** — Where things are heading, what they'd tell their younger self, what they wish more people understood.

**Question quality rules:**
- No yes/no questions.
- No "how did that make you feel?" softballs.
- Each question should be answerable in 2–5 minutes of rich conversation.
- Include 3 follow-up prompts for the most interesting questions.
- Flag which 5 are the strongest openers.

Guest name: [NAME]
Guest expertise/background: [CONTEXT]
Interview format: [PODCAST / ARTICLE / DOCUMENTARY / PANEL]
Audience: [WHO'S LISTENING OR READING]
