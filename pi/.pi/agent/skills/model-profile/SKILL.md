---
name: model-profile
description: Generate short, source-backed profiles of AI models (specs, pricing, benchmarks) using only public web sources, with a citation for every factual claim. Use when asked to profile, look up published facts about, or report the specs/pricing/benchmarks of an AI model.
---

# Model Profile

Produce a compact, neutral, source-backed profile of a single AI model. The
skill **reports what public sources say** — it does not decide whether a model
is good, rank it, or recommend it.

## Core rules

1. **Prefer approved sources** (see [sources.md](sources.md)). If you must use
   another source, use it only when no approved source covers the fact, and
   label it clearly as `(unapproved source)` in the Sources list.
2. **Cite every factual claim** with a source link. A claim with no link does
   not go in the report.
3. **Mark gaps as `not found`.** Never fill a gap with a guess or with general
   knowledge from training data.
4. **No judgment.** Do not rank, recommend, score, or speculate. You *may*
   report a leaderboard position or benchmark number **exactly as the source
   states it** — just don't synthesize your own cross-benchmark verdict or pick
   a "winner."
5. **Record freshness.** Always include the capture date, and note a source
   page's "last updated" date when it is shown.
6. **Report conflicts, don't resolve them.** If two approved sources disagree,
   list both values with both links in Caveats.

## Workflow

1. **Identify the model** precisely (exact name + version, e.g. "Claude Sonnet
   4.5", "GPT-5"). If ambiguous, state the assumption in the report.
2. **Search approved sources.** Use `web_search` with `domainFilter` set to the
   approved domains in [sources.md](sources.md). Run a few varied queries
   (e.g. `"<model> context window pricing"`, `"<model> benchmarks"`,
   `"<model> model card"`).
3. **Read the pages.** Use `fetch_content` to load provider docs, Hugging Face
   model cards, and benchmark/aggregator pages before quoting them. Quote only
   what the page directly supports.
4. **Separate trust levels** for Pricing/Speed:
   - *Publisher-stated* (provider docs) — authoritative for pricing/specs.
   - *Third-party measured* (e.g. Artificial Analysis) — for latency/throughput.
   Label which is which.
5. **Fill the template** below. Use `not found` for anything unsupported.
6. **List every page used** in Sources.

## Report template

```markdown
# Model Profile: <model>

_Captured: <YYYY-MM-DD>_

## Summary
Brief neutral overview (1-3 sentences). Facts only.

## Specs
- Provider:
- Release / version:
- Context window:
- Modalities:
- Availability:

## Pricing / Speed
- Input price (publisher-stated):
- Output price (publisher-stated):
- Latency (third-party measured):
- Output speed (third-party measured):

## Benchmarks
Benchmark results from approved sources, reported exactly as stated. Include the
benchmark name, the number/position, and a link for each.

## Caveats / Missing Info
Not-found items, conflicting values (list both + links), stale pages, or unclear
methodology.

## Sources
- <title> — <url>
```

## Notes

- Keep it compact. This is a fact sheet, not an essay.
- If the model cannot be found in any approved source, return a profile whose
  fields are all `not found` and say so plainly in Summary — do not fall back to
  training-data knowledge.
