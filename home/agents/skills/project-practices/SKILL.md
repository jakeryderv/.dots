---
name: project-practices
description: >
  Audit or scaffold a repository against a tiered project-practices reference:
  a day-one set (README, LICENSE, lockfile, justfile, CI, tests) plus additions
  that are added only when a trigger fires (ADRs, CONTRIBUTING/AGENTS, issues
  and boards, SECURITY/versioning, infra, evals). Use when starting a new
  project, when asked whether a repo is set up well, or when adding CI, docs,
  ADRs, a justfile, or release tooling to an existing one.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
  - Edit
---

# Project Practices

`reference.md` beside this file is the source of truth. Read it before
auditing; its "Adopt Incrementally" section defines the day-one set and the
trigger table, and its "Project Documentation" section defines the placement
rule (repo root holds only files tooling reads by path; everything else lives
in `docs/`).

## Modes

**Audit** (default). Report, don't change.

1. Inventory the repo: root files, `justfile`/`Makefile` recipes, CI workflows,
   `tests/`, `docs/`, lockfiles, `.github/`, contributor count
   (`git shortlog -sn`), whether anything deploys, whether it is an AI/agent
   system.
2. Classify against the day-one set: present / missing.
3. For each row of the trigger table, decide whether the trigger has fired
   from the evidence above, and whether the addition exists.
4. Check the placement rule and the duplication rule (setup instructions live
   only in README; `CONTRIBUTING.md`/`AGENTS.md` link to it).
5. Report as a table:

   | Item | Trigger fired? | Present? | Action |
   |---|---|---|---|

   Recommend only items whose trigger has fired. List untriggered items in one
   line at the end so the user knows they were considered.

**Scaffold**. Only when explicitly asked to create or fix things.

- Create the missing day-one items first.
- Then only the triggered additions from the audit, in the order the user
  confirms.
- Follow the placement rule. Never move an existing file the user did not
  ask to move; propose it instead.
- A `justfile` exposes `setup`, `test`, `check` at minimum; `check` is what CI
  runs.
- Follow existing project conventions over the reference where they conflict;
  note the conflict.

## Rules

- Propose, don't impose, anything beyond the day-one set.
- Never duplicate content across README, `CONTRIBUTING.md`, and `AGENTS.md`.
- Keep `AGENTS.md` under ~100 lines.
- Do not create empty directories or placeholder docs. A doc that has nothing
  true to say is not created.
