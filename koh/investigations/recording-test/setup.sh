#!/bin/bash
# Sets up the test folder and creates a test file.
# Run once before any tests.

set -euo pipefail

TEST_DIR="$HOME/deleteme/koh-recording-test"
RESULTS_DIR="$TEST_DIR/results"

rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR" "$RESULTS_DIR"
cd "$TEST_DIR"

git init
echo "hello world" > test.txt
git add . && git commit -m "init"

echo ""
echo "=== Setup complete ==="
echo "Test dir: $TEST_DIR"
echo "Now run: ./run-test-a.sh"
