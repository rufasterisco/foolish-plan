#!/bin/bash
# Test B: Interactive session, then pull session log.
#
# MANUAL STEPS REQUIRED:
# 1. This script launches interactive claude
# 2. You type: read test.txt, then change 'hello' to 'goodbye', then read it again to confirm
# 3. Wait for it to finish, then /exit
# 4. The script collects the session log automatically

set -euo pipefail

TEST_DIR="$HOME/deleteme/koh-recording-test"
RESULTS_DIR="$TEST_DIR/results"

cd "$TEST_DIR"
git checkout -- test.txt 2>/dev/null || true

echo "=== Test B: Interactive session ==="
echo ""
echo ">>> Type: read test.txt, then change 'hello' to 'goodbye', then read it again to confirm"
echo ">>> Then /exit when done"
echo ""

claude

# After interactive session ends, grab the session log
echo ""
echo "=== Collecting session log ==="

PROJECT_DIR="$HOME/.claude/projects/-Users-francesco-deleteme-koh-recording-test"
if [ -d "$PROJECT_DIR" ]; then
  LATEST=$(ls -t "$PROJECT_DIR"/*.jsonl 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    cp "$LATEST" "$RESULTS_DIR/test-b-output.jsonl"
    echo "Session log: $RESULTS_DIR/test-b-output.jsonl"
  else
    echo "WARNING: No session log found in $PROJECT_DIR"
  fi
else
  echo "WARNING: Project dir not found: $PROJECT_DIR"
fi

echo ""
echo "=== Test B complete ==="
echo "Now run: ./generate-report.sh"
