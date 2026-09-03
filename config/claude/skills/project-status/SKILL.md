---
name: project-status
description: >
  Show a clean summary of everything configured in the current project's
  .claude/ directory — skills, hooks, agents, commands, CLAUDE.md, learnings,
  and MCP servers. Use to get a quick overview of the project setup, or
  before running /suggest-optimization.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - LS
---

# Project Status

Output a concise, formatted summary of this project's Claude Code configuration.

## What to Check

### CLAUDE.md
- Does it exist at project root?
- How many lines? (flag if over 200)
- List the top-level headings

### Skills (.claude/skills/)
- List each skill: name, description (from frontmatter), and whether it's user-invoked or auto-invoked (check `disable-model-invocation`)

### Hooks (.claude/settings.json → hooks)
- List each hook: event → matcher → brief description of what it does

### Agents (.claude/agents/)
- List each agent: name, description, model if specified

### Commands (.claude/commands/)
- List each command: name, brief description

### MCP Servers (.mcp.json)
- List each server: name, transport type

### Learnings (.claude/learnings/)
- How many files, total lines, most recent entry date

### Project Permissions (.claude/settings.json → permissions)
- Any project-specific allow/deny rules beyond global defaults

## Output Format

```
# Project: [directory name]

## CLAUDE.md — [X lines]
  Sections: [heading1], [heading2], ...

## Skills ([count])
  /skill-name — description (user-invoked|auto)
  /skill-name — description (user-invoked|auto)

## Hooks ([count])
  PostToolUse:Edit — auto-format with ruff
  PreToolUse:Write — block edits to lock/weight files

## Agents ([count])
  agent-name — description

## Commands ([count])
  /command-name — description

## MCP Servers ([count])
  server-name — transport type

## Learnings — [X files, Y total lines, latest: DATE]

## Project Permissions
  Allow: [count] rules
  Deny: [count] rules
```

## Rules

- If a section has nothing configured, show it as `## Section — none`
- Keep descriptions to one line each
- Read frontmatter for skill/agent descriptions, don't summarize the full content
- For hooks, describe what the command does in plain English, don't dump the raw command
- Output the summary directly in conversation, don't create a file
