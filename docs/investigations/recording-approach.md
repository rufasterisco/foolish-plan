# Recording approach investigation

We need to pick between two ways to capture a coding session transcript.

## Approaches

### A: Pipe mode

Run Claude Code with `--output-format stream-json` and tee to a file.

```sh
claude -p "do the thing" --output-format stream-json | tee session.jsonl
```

**Key constraint:** `--output-format` only works with `-p` (print/non-interactive mode).

`-p` runs Claude in single-shot mode: one prompt in, one response out, then exit. There is no interactive prompt, no multi-turn conversation, no autonomous tool-call loops beyond the initial request.

You can fake multi-turn with `--continue`:

```sh
claude -p "first thing" --output-format stream-json | tee session.jsonl
claude -p "second thing" --continue --output-format stream-json | tee -a session.jsonl
```

But this is scripted turn-by-turn — the agent can't ask questions or run autonomously across turns the way it does in interactive mode. Each invocation is a separate process.

There is **no way** to get structured JSON output from an interactive Claude Code session. Interactive mode owns the terminal UI and doesn't expose parseable output.

### B: Pull from session logs

After the session ends, copy the JSONL file from `~/.claude/projects/<project-dir>/<session-id>.jsonl`.

---

## Test plan

Run a short Claude Code session in a test folder. The session should include:
- At least one user message
- At least one file read (tool call)
- At least one file edit (tool call)
- At least one text response

Then capture the output with both approaches and answer the questions below.

### Setup

```sh
mkdir -p ~/deleteme/koh-recording-test
cd ~/deleteme/koh-recording-test
git init
echo "hello world" > test.txt
git add . && git commit -m "init"
```

### Test A: Pipe mode

```sh
claude -p "read test.txt, then change 'hello' to 'goodbye', then confirm the change" \
  --output-format stream-json \
  | tee ~/deleteme/koh-recording-test/test-a-output.jsonl
```

### Test A2: -p then interactive continue

Start with `-p`, then resume interactively:

```sh
claude -p "read test.txt and tell me what's in it" \
  --output-format stream-json \
  | tee ~/deleteme/koh-recording-test/test-a2-pipe.jsonl

claude --continue
# now type: "change 'hello' to 'goodbye' in test.txt"
```

Things to check:
- Does `--continue` actually pick up the -p session?
- Does the interactive session show the previous context?
- Does the session log (approach B) contain both the -p turn and the interactive turn?

> Reset test.txt after: `git checkout -- test.txt`

### Test B: Session log

Run a normal interactive session:

```sh
claude
```

Then type the same instruction: "read test.txt, then change 'hello' to 'goodbye', then confirm the change"

After the session ends, find the log:

```sh
ls -lt ~/.claude/projects/-Users-francesco-deleteme-koh-recording-test/
# copy the most recent .jsonl file
cp ~/.claude/projects/-Users-francesco-deleteme-koh-recording-test/<session-id>.jsonl \
   ~/deleteme/koh-recording-test/test-b-output.jsonl
```

> **Important:** reset test.txt between tests: `git checkout -- test.txt`

---

## Questions to answer

Paste raw samples and notes for each question.

### Q1: What do we get?

**A (pipe):**

<!-- paste first ~10 lines of test-a-output.jsonl here -->

**B (session log):**

<!-- paste first ~10 lines of test-b-output.jsonl here -->

---

### Q2: Do we get user vs AI split?

Can we tell which messages are from the user and which are from the AI?

**A (pipe):**

<!-- note what field/structure separates user vs assistant -->

**B (session log):**

Each line has a `"type"` field: `"user"` or `"assistant"`. User messages have `message.role: "user"`, assistant messages have `message.role: "assistant"`. Already confirmed from existing logs.

---

### Q3: Can we recombine in the correct order?

If user and AI messages are separate, can we reconstruct the conversation in order?

Things to look for:
- Timestamps on each entry?
- Parent UUIDs / threading?
- Sequential ordering in the file?

**A (pipe):**

<!-- notes -->

**B (session log):**

Each line has `uuid`, `parentUuid`, and `timestamp`. The file appears to be written in chronological order. `parentUuid` chains responses to their parent message, so we can reconstruct the tree even if order is lost.

---

### Q4: Do we get tool calls? What do they look like?

**A (pipe):**

<!-- paste a tool call example -->

**B (session log):**

Already confirmed from existing logs. Tool calls appear as assistant messages with `message.content` containing `{"type": "tool_use", "name": "ToolName", "input": {...}}`. Tool results appear as separate entries (look for `type: "tool_result"` or similar).

Paste a full tool call + result pair here:

<!-- paste example -->

---

## Comparison matrix

Fill in after running tests.

| Criterion | A (pipe) | B (session log) |
|---|---|---|
| User/AI split | | yes |
| Correct ordering | | yes (uuid chain + timestamps) |
| Tool calls visible | | yes |
| Tool results visible | | ? |
| Works in interactive mode | no (requires -p) | yes |
| Works in non-interactive mode | yes | ? |
| File available during session | yes (streaming) | ? |
| Post-processing needed | ? | minimal |

---

## Notes

**Big finding:** Approach A can't capture interactive sessions. `-p` mode is single-shot — it processes one prompt and exits. Our sessions are interactive (agent in tmux, potentially long-running with many turns). This means Approach A can only work if we restructure sessions to be non-interactive, which defeats the purpose.

Approach A might still be useful for a different use case (scripted, one-shot tasks), but for the core koh workflow — interactive coding sessions — only Approach B works.

**Still worth testing both** to understand what the pipe output looks like, in case we want to support `-p` mode sessions in the future.
