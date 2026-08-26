#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TEST_DIR/link-test.sh"
bash "$TEST_DIR/agent-skills-live-test.sh"
bash "$TEST_DIR/github-release-test.sh"
bash "$TEST_DIR/ai-test.sh"
bash "$TEST_DIR/bs-test.sh"
bash "$TEST_DIR/tmux-cheatsheet-test.sh"
