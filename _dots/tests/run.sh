#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TEST_DIR/link-test.sh"
bash "$TEST_DIR/ai-test.sh"
bash "$TEST_DIR/bs-test.sh"
