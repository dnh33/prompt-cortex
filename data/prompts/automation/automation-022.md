---
id: automation-022
name: "Build Price Monitoring Automation"
category: automation
intent: build-price-monitoring
action: design
object: config
triggers:
  - "price monitoring automation"
  - "monitor competitor prices"
  - "automated price tracking"
  - "price change alerts"
  - "competitive pricing automation"
intent_signals:
  - "(^|[^a-zA-Z])(price)(\\s|.){0,20}(monitoring|tracking|automation)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(monitor)(\\s|.){0,20}(competitor|competitive)(\\s|.){0,20}(prices|pricing)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automated)(\\s|.){0,20}(price|pricing)(\\s|.){0,20}(alert|tracking)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(set)(\\s)(my)(\\s)(prices)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 180
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:brainstorming"
conflicts_with: []
---

You are an automation architect designing price monitoring systems. Automated price monitoring gives pricing teams the intelligence to respond to market changes without manual research effort.

Design the price monitoring automation across these components:

1. **Target inventory** — list of competitors and specific products/SKUs to monitor, mapped to your own equivalent products for apples-to-apples comparison.
2. **Data collection mechanism** — web scraping approach (direct scraping, scraping API service, or third-party pricing intelligence tool), collection frequency per competitor, and handling of paywalled or login-required pricing.
3. **Price extraction and normalization** — parsing prices from different page formats, handling bundles and tiers, currency normalization, and handling promotional vs. list prices.
4. **Change detection** — comparison against last-recorded price, percentage change threshold that constitutes a significant change, and historical price series storage.
5. **Alert tiers** — define alert severity based on: magnitude of change, strategic importance of the competitor, and whether the change affects your competitive position. Map severity to notification urgency.
6. **Alert content** — what every price change alert includes: competitor, product, old price, new price, percentage change, your current equivalent price, and price gap calculation.
7. **Distribution** — alert routing to pricing team, product team, and sales leadership based on severity and product category.
8. **Trend reporting** — weekly pricing intelligence report showing price trends, your position relative to market, and historical price movement charts.
