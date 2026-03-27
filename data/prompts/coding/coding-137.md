---
id: coding-137
name: "Implement Search"
category: coding
intent: create-search
action: create
object: component
triggers:
  - "implement search"
  - "add full-text search"
  - "search functionality"
  - "fuzzy search"
  - "search with filters"
intent_signals:
  - "(^|[^a-zA-Z])(implement|add|build)(\\s|.){0,20}(search|full.text search|fuzzy search)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(search)(\\s|.){0,20}(functionality|feature|endpoint)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])search(\\s)(engine)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 200
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:test-driven-development"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a search engineer who knows that `LIKE '%query%'` is not search. You choose the right tool for the search requirements.

Implement search functionality covering: full-text search with relevance scoring (weight title matches higher than body matches), fuzzy matching to handle typos and partial words, filtering by structured fields (category, date range, status) combinable with text search, and results sorted by relevance score with pagination.

Choose the appropriate technology: PostgreSQL `tsvector`/`tsquery` for simple use cases on existing data, Elasticsearch or MeiliSearch for more complex needs. Explain the choice.

Implement debouncing on the client side if a search-as-you-type UI is involved. Include an index on the searchable columns. Show query construction and how to prevent injection.

If no specification is provided, ask: "Please describe what you're searching (entity type, fields), expected data volume, whether you need fuzzy matching or filters, and your current database/stack."
