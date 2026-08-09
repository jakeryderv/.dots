---
name: suggest-optimization
description: >
  Analyze the current project for friction, repeated patterns, and optimization
  opportunities. Proposes project-specific skills, hooks, agents, commands, or
  CLAUDE.md updates. Also recommends leveraging existing installed tools
  (plugins, MCP servers, built-in agents) when they could improve the workflow.
  Use after completing tasks, when you notice friction, on a new project, or
  when the user asks to optimize their setup.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Edit
  - Bash
  - LS
---

# Suggest Optimization

Analyze this project and recent work to propose Claude Code optimizations.
Everything you create goes in the **project's** `.claude/` directory.

## Available Toolkit

Before proposing new things, consider what's already installed globally.
Recommend using these when they fit the project:

### Plugins (enabled globally)
- **superpowers** — general-purpose enhanced capabilities
- **pyright-lsp** — Python type checking (suggest if project has .py files)
- **github** — PR creation, issue management, repo operations
- **commit-commands** — commit workflows and message generation
- **context7** — up-to-date library docs (suggest "use context7" for unfamiliar libraries)
- **playwright** — browser automation and E2E testing (suggest for frontend projects)
- **comprehensive-review** — multi-perspective code review (suggest after features/PRs)
- **agent-teams** — multi-agent parallel orchestration

### Disabled plugins (recommend re-enabling per-project when relevant)
- **python-development** — Python/Django/FastAPI agents and skills
- **debugging-toolkit** — interactive debugging workflows
- **deployment-strategies** — deployment automation
- **feature-dev** — feature development lifecycle
- **frontend-design** — UI/UX design patterns
- **hookify** — hook creation helper
- **skill-creator** — skill authoring helper

### Marketplace plugins available (recommend installing per-project)
- **claude-code-workflows** (wshobson/agents) — 72 domain-specific plugins
- **buildwithclaude** (davepoon) — 52 plugins
- **awesome-claude-plugins** (ComposioHQ) — 24 plugins

### MCP servers
- **jcodemunch** — AST-indexed symbol retrieval (suggest `index_folder` on large codebases)

### Built-in capabilities (no install needed)
- **Auto memory** — corrections and preferences persist automatically
- **Explore agent** — codebase research in isolated context
- **Plan agent** — structured planning in isolated context
- **/simplify** — 3-agent parallel code review on recent changes
- **/batch** — parallel codebase-wide changes via worktrees
- **Task()** — ad-hoc subagent spawning for parallel work

## Step 1: Gather Context

- Examine the codebase: package.json, Cargo.toml, pyproject.toml, CI configs, test setup, linters, directory structure
- Read `CLAUDE.md` and evaluate: is it lean, accurate, and current?
- Audit `.claude/` if it exists: review existing skills, hooks, agents, and settings for redundancy, outdated instructions, missing descriptions, overly broad matchers, or conflicts with globally installed tools
- Read `.claude/learnings/` if it exists for past friction patterns
- Consider the current conversation — corrections, repeated steps, errors
- Check project size (file count, languages) to gauge complexity

## Step 2: Identify Opportunities

### Leverage existing tools
- Is this a Python project without pyright catching errors? Note it's already available.
- Are there libraries being used with outdated patterns? Suggest "use context7" in prompts.
- Is the codebase large (100+ files)? Suggest running `index_folder` with jcodemunch.
- Could recent work have benefited from `/simplify` or parallel agents?
- Is there frontend code that could use playwright for E2E tests?
- Would a comprehensive-review help before merging?
- Could agent-teams parallelize a complex upcoming task?
- Is there a domain-specific plugin in the marketplace worth installing?

### Audit existing project config
- **CLAUDE.md** — is it under 200 lines? Is anything stale, redundant, or vague? Should details move to skills?
- **Skills** — do descriptions have specific trigger words? Are any overlapping or never activating?
- **Hooks** — are matchers too broad or too narrow? Any redundant with globally installed plugins?
- **Agents** — are instructions concise (<500 lines)? Could any be replaced by a built-in or marketplace plugin?
- **Settings** — any permissions or tool restrictions that are outdated?
- **Conflicts** — does anything in the project's `.claude/` duplicate what's handled globally?

### Create new project-specific things

**Skill candidates** — repeatable workflows, domain patterns, framework conventions,
things you had to figure out that future sessions should just know.

**Hook candidates** — safety rules that must be enforced 100% of the time:
- Branch protection (block edits on main/production)
- Auto-format after file edits (if project has prettier, eslint, ruff, black, etc.)
- Auto-run tests before commits
- Block dangerous commands (drop database, force push, rm -rf)

**Agent candidates** — tasks benefiting from separate context:
- Project-specific code reviewer with domain checklist
- Documentation updater tuned to project's doc structure
- Test writer following project's testing conventions

**Command candidates** — multi-step workflows triggered manually:
- Project deploy sequence
- PR creation with project template
- Database migration/seed/reset
- Release workflow

**CLAUDE.md updates** — things every session should know:
- Build/test/lint commands
- Architecture decisions and key directories
- Naming conventions and patterns
- What NOT to do (common pitfalls)

## Step 3: Present Proposals

For each suggestion:

```
## [type] — [name]

**Why:** What friction or pattern you observed
**What:** Brief description
**Priority:** do-now / nice-to-have

### Implementation
[Complete file content or command to run]

### Location
[Exact path or command]
```

Limit to 3-5 suggestions per run. Prioritize by impact.
Separate "use existing tool" suggestions from "create new thing" suggestions.

## Step 4: Implement What's Approved

- Create skill/agent/command files in the project's `.claude/`
- Merge hooks into the project's `.claude/settings.json`
- Update the project's `CLAUDE.md`
- For plugin recommendations, provide the exact install command

## Guidelines

- **Use before create** — always check if an existing tool handles it first
- Everything new goes in the project, never in `~/.claude/`
- Prefer skills over CLAUDE.md bloat — CLAUDE.md should be a lean index
- Prefer hooks over skills for safety rules — deterministic > probabilistic
- Prefer CLI wrappers over new MCP servers — saves context tokens
- Keep skills focused — one domain, one clear purpose
- Skill descriptions need specific trigger words, not vague language
- If the project is already well-covered, say so — don't suggest for the sake of it
- For large suggestions, offer to use a subagent to implement them in isolation
