#!/bin/bash
# Test A2: Start with -p, then continue interactively.
# Tests whether you can cross modes within the same session.
#
# MANUAL STEPS REQUIRED:
# 1. This script runs the -p part automatically
# 2. Then launches interactive claude --continue
# 3. You type: change 'hello' to 'goodbye' in test.txt
# 4. Wait for it to finish, then /exit
# 5. The script will then collect the session log

set -euo pipefail

TEST_DIR="$HOME/deleteme/koh-recording-test"
RESULTS_DIR="$TEST_DIR/results"
PIPE_OUTPUT="$RESULTS_DIR/test-a2-pipe.jsonl"

cd "$TEST_DIR"
git checkout -- test.txt 2>/dev/null || true

echo "=== Test A2: -p then interactive continue ==="
echo ""
echo "Step 1: Running claude -p..."
echo ""

claude -p "read test.txt and tell me what's in it" \
  --output-format stream-json --verbose \
  | tee "$PIPE_OUTPUT"

echo ""
echo ""
echo "Step 2: Now launching interactive --continue"
echo ">>> Type: change 'hello' to 'goodbye' in test.txt"
echo ">>> Then /exit when done"
echo ""

claude --continue

# After interactive session ends, grab the session log
echo ""
echo "=== Collecting session log ==="

PROJECT_DIR="$HOME/.claude/projects/-Users-francesco-deleteme-koh-recording-test"
if [ -d "$PROJECT_DIR" ]; then
  LATEST=$(ls -t "$PROJECT_DIR"/*.jsonl 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    cp "$LATEST" "$RESULTS_DIR/test-a2-session-log.jsonl"
    echo "Session log: $RESULTS_DIR/test-a2-session-log.jsonl"
  else
    echo "WARNING: No session log found in $PROJECT_DIR"
  fi
else
  echo "WARNING: Project dir not found: $PROJECT_DIR"
fi

echo ""
echo "=== Test A2 complete ==="
echo "Pipe output: $PIPE_OUTPUT"
echo "Now run: ./run-test-b.sh"
