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

**Every repo, day one:**

- `README.md` with setup and usage
- `LICENSE`
- Lockfile and pinned toolchain
- `justfile` exposing `setup`, `test`, `check`
- CI that runs `dots check`
- `tests/`

**Add when the trigger appears:**

| Trigger | Add |
|---|---|
| A design choice gets argued about | `docs/adr/` |
| Second contributor or an agent works on it | `CONTRIBUTING.md`, `AGENTS.md`, branch protection |
| Work outlives what you can hold in your head | Issues, milestones, a board |
| First external user | `SECURITY.md`, versioning policy, changelog |
| It deploys somewhere | `infra/`, `.env.example`, observability |
| It is an AI/agent system | Behavioral evals and a regression suite |
| A milestone exceeds ~20 issues | Epics |

## Project Documentation

**Placement rule:** the repo root holds only files that tooling reads by path (GitHub, package managers, agent harnesses). Everything else lives in `docs/`.

| Artifact | Purpose |
|---|---|
| `README.md` | Overview, quick start, usage. **Canonical home for setup instructions.** Links to `docs/` |
| `LICENSE` | Project licensing |
| `CONTRIBUTING.md` | Workflow and conventions; links to README for setup, never duplicates it. May live in `.github/` |
| `SECURITY.md` | Security policy and vulnerability reporting. May live in `.github/` |
| `AGENTS.md` | Context for coding agents. Loaded every session: keep under ~100 lines, link out for detail |
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

Keep distant work coarse and refine it as implementation approaches. Add Epics between Milestones and Issues only when a milestone grows past ~20 issues.

## Issue Tracking

Issues capture:

- Problem / objective
- Why it matters
- Acceptance criteria
- Relevant context
- Dependencies

Keep the label taxonomy to two axes. Change type is already encoded in the commit prefix and branch name; don't duplicate it as a label.

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

Trunk-based development:

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

**Protect `main`:** require CI green and one review before merge. CI that isn't required is a suggestion.

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

- Libraries and CLIs: semver. A breaking change is anything that alters documented behavior, flags, or output format.
- Applications nobody depends on programmatically: calver.
- Tag → release is automated. Never hand-write a release.

## Definition of Done

- Implementation complete
- Acceptance criteria satisfied
- Tests added or updated
- Formatting, linting, and type checks pass
- Documentation updated
- Security implications considered
- CI passes
- Review complete

## Testing

```text
Unit → Integration → End-to-End
                     +
              Evals / Regression
```

Many fast unit tests, fewer integration tests, a small number of high-value E2E tests.

For AI/agent systems, keep behavioral evals in the repo alongside conventional tests: a versioned set of inputs, expected behaviors, and a scorer that runs in CI. Every fixed regression becomes a case.

## CI/CD

CI pipeline:

```text
Format → Lint → Typecheck → Tests → Build → Security Checks
```

Delivery pipeline:

```text
Commit → CI → Artifact → Dev → Staging → Production
```

Build once; promote the same artifact through environments. Rebuilding per environment is a bug.

Automate releases, changelogs, versioning, and artifact publishing.

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

Expose one project interface via `just` (or `make`):

```bash
just setup
just dev
just test
dots check
just build
just run
just release
```

Developers and agents should not need to know the underlying tool commands.

## Infrastructure & Configuration

Infrastructure is code. Click-ops is undocumented state.

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

Never commit secrets. Provide `.env.example`; real credentials live in a secrets manager.

## Security

```text
Developer → Pre-commit → CI → Deployment → Runtime Monitoring
```

Automate:

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

`AGENTS.md` is loaded every session. Keep it short and link out; long files get skimmed or ignored.

## Repository Layout

Day one:

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

Fully grown:

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

Root contains only what tooling reads by path; everything else is under `docs/`.

## Target State

**Automated · Reproducible · Observable · Documented · Secure · Trackable · Agent-Friendly**
