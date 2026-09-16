---
name: project-practices
description: >
  Audit or scaffold a repository against a tiered project-practices reference:
  a context-appropriate baseline (onboarding, licensing, reproducibility,
  validation, CI) plus additions only when supported by evidence (decision
  records, contributor/agent guidance, tracking, security, releases,
  infrastructure, evals). Use when starting a new project, when asked whether
  a repo is set up well, or when adding CI, docs, ADRs, a task runner, or
  release tooling to an existing one.
---

# Project Practices

`reference.md` beside this file is the source of truth. Read it before
an audit or scaffold. Its "Adopt Incrementally" section defines the baseline
capabilities and trigger table. Paths and tools are examples, not requirements;
follow existing project conventions and explain material conflicts.

## Modes

**Audit** (default). Report, don't change.

1. Establish scope: repository purpose, language/ecosystem, maintained packages,
   distribution/deployment model, intended users, current collaborators, and
   whether it implements an AI/agent system (not merely uses an agent to code).
   Inspect instructions and existing conventions first. Record assumptions;
   ask only when an unresolved fact materially changes a recommendation.
2. Inventory capabilities, not directory names. Inspect manifests, task scripts,
   toolchain/dependency controls, CI configuration, docs, and tests wherever
   they live, including colocated tests and monorepo packages. README is the
   onboarding entry point; follow its links to canonical instructions.
   `git shortlog -sn HEAD` can suggest historical contributors, but does not
   prove current collaboration, reviewer availability, or external adoption.
   Handle empty/shallow repositories and unavailable history explicitly.
3. Assess each baseline capability and each additional trigger from evidence.
   Trigger states: **yes / no / unknown / not applicable**. Baseline rows use
   **baseline** instead. Capability states: **present / partial / missing /
   unknown / not applicable**. "Missing" requires a relevant, sufficiently
   scoped search; "not applicable" requires a reason. File existence alone
   proves neither usable content nor working behavior.
4. Separate configuration from execution evidence. Cite paths and line numbers,
   command results, or remote settings. Inspect check commands before running
   them; run appropriate safe checks when feasible and report what was not run.
   A configured CI workflow is not proof of passing CI or required status checks.
   Branch protection, boards, releases, and other hosted settings require
   read-only remote evidence or explicit user confirmation. If access is
   unavailable or outside scope, report **unknown**, not **missing**. Do not
   change credentials, permissions, settings, or install tools just to audit.
5. Check documentation discoverability and duplication. Keep a single canonical
   source for setup instructions, linked from README and contributor/agent
   guidance. Apply the placement rule only to documentation, not source,
   tests, scripts, or configuration. Existing ecosystem conventions take priority.
6. Report a concise table:

   | Capability | Trigger / applicability | Status | Evidence / limits | Recommended action |
   |---|---|---|---|---|

   Prioritize actionable gaps in applicable baseline capabilities and additions
   whose triggers are established. For unknowns, recommend verification rather
   than creating artifacts or claiming defects. Distinguish defects from optional
   preferences. Summarize untriggered and inapplicable additions in one line,
   with reasons; state audit scope, checks run, and remaining uncertainty.

**Scaffold**. Only when explicitly asked to create or fix things.

- Audit first; address confirmed, applicable baseline gaps before additions.
- Add only confirmed triggered practices within the user-approved scope. Ask
  before choosing a license, setting release policy, changing hosted protections,
  or making other consequential decisions not already authorized.
- Preserve working layouts and tooling. Never move an existing file the user
  did not ask to move; propose it instead.
- Reuse the project's task interface (`just`, `make`, package scripts, or an
  ecosystem-native equivalent). Provide documented setup and validation commands,
  including tests where applicable; CI should run the same checks. For a new
  `justfile`, prefer `setup`, `test`, and `check` when those actions apply.
- Validate changes using relevant checks. Report results and unverified behavior;
  never present configured-but-unrun checks as passing.

## Rules

- The reference is a menu, not a compliance standard. Do not add process solely
  because a path, tool, or example differs.
- Keep setup instructions in one canonical location; link rather than duplicate.
- Keep `AGENTS.md` short (aim for ~100 lines), with links for detail.
- Do not create empty directories, placeholder docs, or artificial tests merely
  to satisfy the checklist. A document with nothing true to say is not created.
- Agent use alone does not imply a multi-person team, independent reviewers,
  a deployed service, or a need for model behavioral evals.
