#!/bin/bash
# Generates a report from all test outputs.
# Run after all tests are complete.

set -euo pipefail

TEST_DIR="$HOME/deleteme/koh-recording-test"
RESULTS_DIR="$TEST_DIR/results"
REPORT="$RESULTS_DIR/report.md"

cat > "$REPORT" << 'HEADER'
# Recording approach test results

Auto-generated report. Bring this back to the koh project for analysis.

---

HEADER

# --- Helper functions ---

# Print the distinct top-level "type" values in a JSONL file
types_summary() {
  local file="$1"
  jq -r '.type // "NO_TYPE"' "$file" 2>/dev/null | sort | uniq -c | sort -rn
}

# Print distinct message roles
roles_summary() {
  local file="$1"
  jq -r '.message.role // .role // "NO_ROLE"' "$file" 2>/dev/null | sort | uniq -c | sort -rn
}

# Check for user/assistant split
has_user_assistant() {
  local file="$1"
  local has_user has_assistant
  has_user=$(jq -r 'select(.type == "user" or .message.role == "user") | "yes"' "$file" 2>/dev/null | head -1)
  has_assistant=$(jq -r 'select(.type == "assistant" or .message.role == "assistant") | "yes"' "$file" 2>/dev/null | head -1)
  if [ "$has_user" = "yes" ] && [ "$has_assistant" = "yes" ]; then
    echo "YES"
  else
    echo "NO (user=$has_user, assistant=$has_assistant)"
  fi
}

# Check for ordering fields
has_ordering() {
  local file="$1"
  local has_ts has_uuid has_parent
  has_ts=$(jq -r 'select(.timestamp != null) | "yes"' "$file" 2>/dev/null | head -1)
  has_uuid=$(jq -r 'select(.uuid != null) | "yes"' "$file" 2>/dev/null | head -1)
  has_parent=$(jq -r 'select(.parentUuid != null) | "yes"' "$file" 2>/dev/null | head -1)
  echo "timestamp=$has_ts uuid=$has_uuid parentUuid=$has_parent"
}

# Extract tool calls
tool_calls_summary() {
  local file="$1"
  # Look for tool_use in message.content array
  jq -r '
    .message.content[]? |
    select(.type == "tool_use") |
    .name
  ' "$file" 2>/dev/null | sort | uniq -c | sort -rn
  # Also look for tool_use at top level or in content
  jq -r '
    select(.type == "tool_use") |
    .name // "unknown"
  ' "$file" 2>/dev/null | sort | uniq -c | sort -rn
}

# Extract tool results
tool_results_summary() {
  local file="$1"
  jq -r 'select(.type == "tool_result") | .name // .tool_use_id // "found"' "$file" 2>/dev/null | head -5
  jq -r '.message.content[]? | select(.type == "tool_result") | .tool_use_id // "found"' "$file" 2>/dev/null | head -5
}

# --- Report generation ---

analyze_file() {
  local label="$1"
  local file="$2"

  echo "## $label"
  echo ""

  if [ ! -f "$file" ]; then
    echo "**File not found:** \`$file\`"
    echo ""
    return
  fi

  local lines
  lines=$(wc -l < "$file" | tr -d ' ')
  local size
  size=$(du -h "$file" | cut -f1)
  echo "**File:** \`$(basename "$file")\` — $lines lines, $size"
  echo ""

  echo "### Top-level types"
  echo "\`\`\`"
  types_summary "$file"
  echo "\`\`\`"
  echo ""

  echo "### Message roles"
  echo "\`\`\`"
  roles_summary "$file"
  echo "\`\`\`"
  echo ""

  echo "### User/assistant split?"
  echo ""
  echo "$(has_user_assistant "$file")"
  echo ""

  echo "### Ordering fields"
  echo ""
  echo "$(has_ordering "$file")"
  echo ""

  echo "### Tool calls"
  echo "\`\`\`"
  tool_calls_summary "$file"
  echo "\`\`\`"
  echo ""

  echo "### Tool results"
  echo "\`\`\`"
  tool_results_summary "$file"
  echo "\`\`\`"
  echo ""

  echo "### First 5 entries (keys only)"
  echo "\`\`\`"
  head -5 "$file" | jq -r 'keys | join(", ")' 2>/dev/null || echo "(failed to parse)"
  echo "\`\`\`"
  echo ""

  echo "### First user message"
  echo "\`\`\`json"
  jq -c 'select(.type == "user" or .message.role == "user")' "$file" 2>/dev/null | head -1 | jq . 2>/dev/null || echo "(not found)"
  echo "\`\`\`"
  echo ""

  echo "### First assistant message (truncated)"
  echo "\`\`\`json"
  jq -c 'select(.type == "assistant" or .message.role == "assistant")' "$file" 2>/dev/null | head -1 | jq '{type, message: {role: .message.role, content_types: [.message.content[]?.type], stop_reason: .message.stop_reason}}' 2>/dev/null || echo "(not found)"
  echo "\`\`\`"
  echo ""

  echo "### First tool_use entry (full)"
  echo "\`\`\`json"
  jq -c 'select(.message.content[]?.type == "tool_use")' "$file" 2>/dev/null | head -1 | jq . 2>/dev/null || echo "(not found)"
  echo "\`\`\`"
  echo ""

  echo "### First tool_result entry (full)"
  echo "\`\`\`json"
  jq -c 'select(.type == "tool_result" or (.message.content[]?.type == "tool_result"))' "$file" 2>/dev/null | head -1 | jq . 2>/dev/null || echo "(not found)"
  echo "\`\`\`"
  echo ""

  echo "---"
  echo ""
}

{
  analyze_file "Test A: Pipe mode" "$RESULTS_DIR/test-a-output.jsonl"
  analyze_file "Test A2: Pipe output" "$RESULTS_DIR/test-a2-pipe.jsonl"
  analyze_file "Test A2: Session log (covers both -p and interactive)" "$RESULTS_DIR/test-a2-session-log.jsonl"
  analyze_file "Test B: Session log (interactive only)" "$RESULTS_DIR/test-b-output.jsonl"
} >> "$REPORT"

echo "=== Report generated ==="
echo "$REPORT"
echo ""
echo "You can now bring this file back to the koh project for analysis."
