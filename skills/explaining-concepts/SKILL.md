---
name: explaining-concepts
description: Use when the user asks what a tool, design pattern, library, language feature, or technical concept is for, when to use it, how it differs from another, or which one to pick — e.g. "what is the strategy pattern for", "makefile vs shell script", "should I use X or Y", "explain X".
license: MIT
---

# Explaining Concepts

Explanations answer a decision, not survey features. The reader wants to know: what problem the thing solves, when to reach for it, and when to reach for something else.

## Prose style — overrides the `caveman` skill while explaining

When this skill is active, it temporarily overrides the `caveman` skill (or any telegraphic/compressed output mode):

1. Before writing the explanation, switch to full prose: complete sentences, normal paragraphs, side-by-side tables where they clarify. No article-dropping, fragments, or compression.
2. Engage with the reader's own reasoning — concede what they got right, build from their observation, then correct what remains.
3. When the explanation is delivered, restore the previous compression mode and resume it in all following responses.

This affects chat output only.

## Output contract

Every explained thing — tool, pattern, feature, concept — gets all five sections, in order:

1. **Purpose** — one sentence: the problem it exists to solve.
2. **Best practices** — how experienced users apply it (3-5 bullets).
3. **Anti-patterns** — common misuses and why they hurt (3-5 bullets).
4. **Minimal example** — smallest real snippet or sketch showing it in use.
5. **Alternatives** — other things solving the same problem, one line each on how they differ.

For comparisons ("X vs Y"), also end with a **Verdict**: "Choose X when [condition]. Choose Y when [condition]." Concrete conditions, both sides stated. Never "both are great" or a bare "it depends".

## Rules

- Alternatives are mandatory, including things the user did not name — the best answer may be one they have never heard of. For patterns, this includes "you may not need the pattern at all".
- "It depends" only with the exact dependencies spelled out as pickable conditions.
- Facts age. If a claim is version-sensitive or uncertain, web-search before asserting it.
- No hype words (powerful, robust, seamless). Concrete problems and tradeoffs only.
- Answer for the user's actual stack, language, and OS, not a generic one.
- Match depth to the question. A quick-pick question gets a quick pick, not an essay.
- Boundary: teaching a topic over multiple sessions is the `teach` skill's job; this skill is for explanations and decisions.

## Worked example

User: "what is the strategy pattern for?"

**Strategy pattern**
- Purpose: swap algorithms behind one interface so behavior can vary without growing conditionals.
- Best practices: reach for it when variants multiply and change independently; keep strategies stateless where possible; inject the strategy, never hard-construct it.
- Anti-patterns: a single-strategy strategy (speculation); forcing strategies with different inputs into one interface; strategy classes where a function would do.
- Example:
  ```ts
  interface Sort { run<T>(xs: T[]): T[] }
  const insSort: Sort = { run: xs => /* ... */ xs }
  const mergeSort: Sort = { run: xs => /* ... */ xs }
  const search = (sort: Sort, xs: number[]) => sort.run([...xs])
  ```
- Alternatives: first-class functions in languages with closures — usually simpler; a lookup table mapping keys to handlers; template method when variants share most of their steps.

No comparison asked, so no verdict — but the alternatives line already tells the reader when to skip the pattern entirely.
