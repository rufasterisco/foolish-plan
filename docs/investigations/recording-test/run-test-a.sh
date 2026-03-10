#!/bin/bash
# Test A: Pipe mode (-p with --output-format stream-json)
# Captures structured JSON output from a non-interactive session.

set -euo pipefail

TEST_DIR="$HOME/deleteme/koh-recording-test"
RESULTS_DIR="$TEST_DIR/results"
OUTPUT="$RESULTS_DIR/test-a-output.jsonl"

cd "$TEST_DIR"
git checkout -- test.txt 2>/dev/null || true

echo "=== Test A: Pipe mode ==="
echo "Running claude -p with stream-json..."
echo ""

claude -p "read test.txt, then change 'hello' to 'goodbye', then read it again to confirm the change worked" \
  --output-format stream-json --verbose \
  | tee "$OUTPUT"

echo ""
echo ""
echo "=== Test A complete ==="
echo "Output: $OUTPUT"
echo "Lines: $(wc -l < "$OUTPUT")"
echo "Now run: ./run-test-a2.sh"
