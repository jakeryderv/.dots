# Software Engineering Project Practices

A reference for planning, tracking, organizing, developing, operating, and automating software projects. It is a menu, not a mandate: start with the day-one set and add the rest when a trigger appears.

## Core Principles

- **Automate what machines can reliably check or perform.**
- **Keep work reproducible** across developers, CI, agents, and environments.
- **Keep project state visible** through issues, milestones, boards, and documentation.
- **Treat documentation and infrastructure as code.**
- **Prefer small, composable systems and workflows.**
- **Optimize repositories for both humans and coding agents.**
- **Every artifact must be true or deleted.** Stale docs, boards, and configs are worse than none.

## Adopt Incrementally

**Baseline capabilities to assess from day one:**

| Capability | Evidence / applicability |
|---|---|
| Onboarding and usage | README provides an entry point and setup/usage instructions or links to their canonical home. |
| Licensing / permitted use | Explicit terms appropriate to distribution; normally `LICENSE` for shared code. Confirm owner intent for private/proprietary projects; never choose an open-source license implicitly. |
| Reproducible development | Dependency resolution and toolchain versions are controlled as appropriate to the ecosystem. Lockfiles, constraints, immutable inputs, or equivalent mechanisms can qualify; a dependency-free repo need not invent a lockfile. Distinguish developer tooling from a library's supported consumer dependency ranges. |
| Discoverable task interface | Documented setup and validation commands via existing package scripts, `just`, `make`, or ecosystem-native tooling. No additional wrapper is required. |
| Automated validation | Meaningful tests for executable behavior; relevant schema, link, configuration, or other checks for non-code repositories. Colocated tests, package-local suites, and external test directories all qualify. |
| Continuous validation | Where a CI host is used, CI runs the documented validation checks. Separate configured workflows from observed passing runs; offline or unhosted repos may use a documented local check instead. |

Assess outcomes rather than file presence. Record **present, partial, missing,
unknown, or not applicable**, with evidence and reasons. A workflow or test file
alone does not prove checks execute successfully. Uninspected remote state is
unknown, not missing. Evaluate package-specific capabilities at the appropriate
scope in monorepos; do not require duplicate root-level artifacts.

**Add when evidence establishes a need:**

| Trigger | Consider adding |
|---|---|
| A consequential design tradeoff needs durable rationale | A decision record, conventionally `docs/adr/`; disagreement is not required. |
| Multiple active contributors need shared workflow guidance | Contributor guidance in the existing docs or `CONTRIBUTING.md`. Historical author count alone is insufficient. |
| Coding agents need repository-specific commands or constraints | Concise harness-supported instructions such as `AGENTS.md`; no separate contributor guide is required solely because an agent is used. |
| Hosted shared/released code needs enforced merge controls | Required CI checks and appropriate branch/ruleset protection. Require independent review only when an eligible reviewer is available or policy requires it; surface staffing conflicts rather than weakening policy. |
| Work exceeds lightweight tracking | Issues first; milestones or a board only when grouping/status coordination adds value. |
| External users need support, compatibility, or upgrade guarantees | Appropriate security-reporting guidance, a versioning policy, and release/change notes; reuse existing organization policies when applicable. |
| Software is deployed and has operational configuration/state | Reproducible deployment configuration wherever the platform expects it; document required inputs (e.g. `.env.example` only if environment variables are used) and add proportionate observability. |
| The project implements AI/agent behavior | Behavioral evals and regression coverage for that behavior, not merely because an agent helps write code. |
| A milestone becomes difficult to navigate (roughly 20+ issues is a cue) | Epics or other grouping, if they improve navigation. |

Unknown triggers call for verification, not automatic additions. The remaining
sections offer patterns for established needs, not extra mandatory audit gates.

## Project Documentation

**Documentation placement rule:** keep conventional entry points and files that
tooling discovers (`README.md`, `LICENSE`, contributor/security/agent guidance)
in supported locations. Prefer `docs/` for additional standalone documentation,
unless the project already uses another discoverable convention or colocated
docs. This rule does not relocate source, tests, scripts, or configuration.

| Artifact | Purpose |
|---|---|
| `README.md` | Overview, quick start, usage. **Entry point to the single canonical setup guide**, inline or linked. |
| `LICENSE` | Project licensing |
| `CONTRIBUTING.md` | Workflow and conventions; links to canonical setup instructions, never duplicates them. May live in `.github/` |
| `SECURITY.md` | Security policy and vulnerability reporting. May live in `.github/` |
| `AGENTS.md` | Context for coding agents where supported by the harness and trust settings; aim for ~100 lines, link out for detail |
| `docs/roadmap.md` | Why the project exists, then Now / Next / Later |
| `docs/architecture.md` | Components, boundaries, dependencies, data flow |
| `docs/adr/` | Architecture Decision Records. Append-only |

**Rule of thumb:** Plans describe where you are going; issues describe work; code describes reality; ADRs describe why reality looks that way.

## Work Hierarchy

```text
Milestones
└── Issues
    └── Tasks
```

Keep distant work coarse and refine it as implementation approaches. Use only
the hierarchy levels that help; around 20 issues is a cue to consider grouping,
not a mandatory threshold.

## Issue Tracking

Issues capture:

- Problem / objective
- Why it matters
- Acceptance criteria
- Relevant context
- Dependencies

Keep labels small and useful. Area and priority are a starting point; add type
labels if they help triage before branches or commits exist. Avoid redundant
labels that do not serve filtering or automation.

```text
area: runtime | cli | api | infra | plugins
priority: critical | high | normal | low
```

Use milestones for releases or major objectives.

## Project Board

```text
Backlog → Ready → In Progress → In Review → Done
                         ↘ Blocked
```

The board answers: what is planned, active, blocked, under review, and complete. If it can't answer that at a glance, it has too many columns.

## Git & Pull Requests

A useful default when PRs fit the collaboration model is trunk-based development:

```text
short-lived branch → PR → main
```

Branch names carry the change type:

```text
feat/plugin-loader
fix/context-overflow
refactor/tool-registry
docs/plugin-api
```

Small, focused PRs linked to issues.

**Merge controls:** for shared or released code, consider requiring CI on the
actual default branch (not necessarily `main`). Require independent review when
an eligible reviewer is available or policy mandates it. Do not impose an
impossible self-approval requirement on a solo maintainer using an agent. Verify
hosted rules directly before claiming checks or reviews are enforced.

### Conventional Commits

```text
feat: add plugin discovery
fix: prevent duplicate registration
refactor: separate runtime from provider layer
docs: document plugin lifecycle
test: add runtime integration tests
chore: update dependencies
```

### Versioning

- Libraries and CLIs: prefer semver where users rely on a compatibility contract.
  Breaking changes invalidate previously supported usage (APIs, flags, behavior,
  or machine-consumed output); not every documented addition is breaking.
- Applications: choose semver, calver, or another documented scheme based on
  consumer expectations and existing conventions.
- Automate repeatable release steps and publishing when useful; retain human
  review and authored notes for compatibility, migration, and security context.

## Definition of Done

- Implementation complete
- Acceptance criteria satisfied
- Relevant tests/checks added or updated
- Applicable formatting, linting, type checks, and tests pass
- Documentation updated where behavior or workflow changed
- Security implications considered
- Applicable CI passes; unverified execution remains an open verification item
- Review complete according to the project's policy

## Testing

```text
Unit → Integration → End-to-End
                     +
              Evals / Regression
```

Many fast unit tests, fewer integration tests, a small number of high-value E2E tests.

For AI/agent systems, version behavioral inputs, expected behaviors, and scoring
alongside conventional tests, wherever the project keeps them. Use deterministic
checks in routine CI where possible; schedule or gate live-model evals according
to cost, credentials, privacy, and nondeterminism. Capture fixed regressions as
cases when feasible. Using an agent to develop ordinary software does not itself
create an eval requirement.

## CI/CD

CI pipeline:

```text
Format → Lint → Typecheck → Tests → Build → Security Checks
```

Delivery pipeline:

```text
Commit → CI → Artifact → Dev → Staging → Production
```

These are example pipelines: include stages and environments only where relevant.
Prefer building once and promoting immutable artifacts to reduce drift. If a
platform requires environment-specific builds, document why, control the inputs,
and validate the actual artifact deployed to each environment.

Automate repeatable release and publishing steps when releases are needed.

## Reproducible Development

Target:

```text
git clone → just setup → ready to develop
```

Tools that get you there:

- Nix / flakes
- Dev Containers
- Docker / Compose
- Lockfiles
- `.tool-versions`

Reuse one discoverable project interface: package scripts, native ecosystem
commands, `just`, or `make`. For example, expose only applicable recipes:

```bash
just setup
just dev
just test
just check
just build
just run
just release
```

Document the supported commands so developers, agents, and CI use the same
checks. Existing native commands are sufficient; a wrapper is not mandatory.

## Infrastructure & Configuration

Prefer versioned, reproducible deployment configuration over undocumented manual
state. Follow platform conventions; `infra/` is one possible layout, not a
requirement:

```text
infra/
├── terraform-or-opentofu/
├── nix/
├── docker/
└── environments/
```

Keep these separate:

```text
code | configuration | secrets
```

Never commit secrets. Document required configuration inputs; provide a
secret-free `.env.example` when environment variables are part of the interface.
Use a secrets manager, workload identity, or another approved credential mechanism
appropriate to the environment.

## Security

```text
Developer → Pre-commit → CI → Deployment → Runtime Monitoring
```

Select applicable checks based on assets and risks; container and infrastructure
scanning, for example, need those assets to exist. Automate where useful:

- Secret scanning
- Dependency vulnerability scanning
- Static analysis
- Container scanning
- Infrastructure scanning
- Dependency/license checks

Agentic systems additionally need: tool permissions, sandboxing, filesystem/network boundaries, credential isolation, prompt-injection defenses, plugin trust, audit trails, and approval gates for destructive actions.

## Observability

```text
Logs + Metrics + Traces
```

For agent systems, track per run:

- Run / session
- Agent / subagent
- Model
- Tokens and cost
- Latency
- Context size
- Tool calls and failures
- Retries
- Eval results

Correlate with request/run/trace IDs.

## Dependencies

Automate detection of:

- Outdated dependencies
- Vulnerabilities
- Breaking updates
- Unused dependencies
- License issues

Lockfiles for reproducibility; automated update tooling to stay current.

## Documentation as Code

```text
docs/
├── roadmap.md
├── architecture.md
├── guides/
├── reference/
└── adr/
```

Diagrams live next to what they describe, as Mermaid, D2, or PlantUML source.

CI checks documentation builds, links, examples, and generated references.

ADRs are append-only. Every other document must be true or deleted.

## Architecture Decision Records (ADRs)

```text
Context
Decision
Alternatives
Consequences
```

```text
docs/adr/
├── 0001-runtime-language.md
├── 0002-plugin-architecture.md
└── 0003-development-environment.md
```

## Project Automation

Automate state transitions:

```text
Issue created → Backlog
Work begins → In Progress
PR opened → In Review
PR merged → Issue closed → Done
Tag created → Release generated/published
```

Also automate:

- Issue/PR labeling
- Dependency updates
- Formatting
- Changelogs
- Release notes
- Stale issue handling
- Documentation generation
- Security scanning

## Agent-Friendly Repositories

Make project knowledge explicit and machine-readable:

```text
AGENTS.md
docs/architecture.md
CONTRIBUTING.md
ADRs
structured issues
schemas
CI workflows
tests
justfile
reproducible environment
```

An agent should be able to answer quickly:

1. How do I set up the project?
2. How do I build, run, and test it?
3. Where does each component live?
4. What architectural constraints exist?
5. What work remains?
6. What counts as done?

Instruction discovery depends on the agent harness, path, and trust settings.
Verify the supported mechanism; keep automatically loaded guidance short and
link to detailed material rather than duplicating it.

## Repository Layout

Illustrative layouts, not audit requirements. Accept flat scripts, colocated
tests, workspace packages, alternative CI hosts, and ecosystem-specific docs or
deployment locations. Do not create directories solely to match these trees.

Small conventional code repository:

```text
project/
├── README.md
├── LICENSE
├── justfile
├── src/
├── tests/
├── .github/workflows/
└── lockfile + toolchain files
```

Possible expanded layout (only applicable, triggered additions):

```text
project/
├── README.md
├── LICENSE
├── CONTRIBUTING.md        # or .github/
├── SECURITY.md            # or .github/
├── AGENTS.md
├── docs/
│   ├── roadmap.md
│   ├── architecture.md
│   ├── guides/
│   ├── reference/
│   └── adr/
├── src/
├── tests/
├── scripts/
├── infra/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
├── .env.example
├── justfile
└── lockfile + toolchain files
```

Apply the documentation placement rule to documentation only. Source, tests,
scripts, and configuration retain their existing or ecosystem-required locations.

## Target State

**Automated · Reproducible · Observable · Documented · Secure · Trackable · Agent-Friendly**
