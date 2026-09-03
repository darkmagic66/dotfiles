---
name: writing-process-reports
description: Use when the user asks for a process report or wants the agent's work narrated - phrases like "process report", "how did you solve this", "what did you do", "walk me through your process", "write down what you did", "how did you narrow this down", or "/process-report". On demand only.
---

# Writing Process Reports

## Overview

Reconstruct your own problem-solving from the current session and write it as a structured markdown report the user can learn from, audit, and reuse. The user wants to see how you thought — scope decisions, tool choices, failures, recovery — not just the result.

## When to Use

- User asks for a process report, walkthrough, or "how did you solve this"
- User wants documentation of how work was done
- Not for: user only wants the result or a normal summary and said nothing about process

## Report Contract

**File:** `.opencode/process-reports/YYYY-MM-DD-<task-slug>.md` in the project where the work happened (create directories as needed). One report per task, or one combined report if the user's question spans several tasks.

**Every report contains these five sections, in this order:**

### 1. Task & Scope
- Task as given, in the user's words
- Assumptions made before acting
- Each scope decision: what was narrowed or excluded, and why (e.g. "bug fix, so smallest change that passes tests; no refactor, no adjacent cleanup")

### 2. Task Division & Tool Choice
- How the task was split into steps, and why in that order
- For each tool or command used: which one, and why it over the alternatives (Read vs bash cat, Grep vs Task agent, rtk wrapper vs raw output, batched calls vs sequential)

### 3. Execution & Failure→Recovery
- Chronological log of key actions: command or edit, intent, result
- For every failure or wrong turn: the exact error line quoted verbatim, how the next problem was defined from it, the next attempt, and what finally worked
- If nothing failed, say so explicitly — a one-line "no wrong turns, diagnosis was direct" with the reasoning that made it direct

### 4. Verification
- Evidence the result is correct: test/lint/build output quoted, with exit codes
- Only claims actually run — "verified" means output was seen, "should work" is labeled as such

### 5. Lessons
- Transferable insights the user can apply when solving similar problems themselves
- Decisions worth copying, near-mistakes, patterns that generalized

**After writing the file:** reply in chat with a 3-line summary — task, biggest decision, biggest recovery (or what made the path direct) — plus the file path.

## Reconstruction Method

Walk the session chronologically: task as given, first assumptions, each tool call and why, each decision point, each failure and what it changed, final verification. Report only what actually happened — real commands, real errors, quoted verbatim. If a detail is not recoverable from context, say so; never invent steps, deliberation, or failures that did not occur. A process report with fabricated reasoning is worse than no report.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Tool narration omitted as "noise" | Tool choice and commands are the point of the report — every key one gets its why |
| Clean-path narrative, failures erased | Wrong turns are the most valuable content; include every one |
| Generic filler ("I analyzed the code") | Name the file, the command, the exact change |
| Inventing plausible deliberation | Quote real output; mark gaps as gaps |
| Claiming verification without output | Section 4 contains quoted output only |
