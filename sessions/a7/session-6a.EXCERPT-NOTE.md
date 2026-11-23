# session-6a: labelled excerpt

The full `claude -p` transcript of session 6a (the edge tests, `prompts/a7/prompt-6a.txt`) is 1,234,107
bytes. The assignment asks for transcripts under about 1 MB, or a labelled excerpt, so the tree now holds
an excerpt and no longer holds the full file.

| | |
|---|---|
| Full transcript | `session-6a.jsonl`, 1,234,107 bytes, SHA-256 `e22a1a2ac670f79599f6ec5520e4d1b308b88823630bfe1b3fd079b01e9fbf98` |
| Where it is | committed unedited in `d34dccc` (still in git history), and kept outside git at `F:\7270\a7-transcripts\session-6a.jsonl` |
| Excerpt | `session-6a.excerpt.jsonl`, 577,803 bytes, made by Claude on 2026-11-22 |
| Final result | `session-6a.md` (the session's final message, unedited) |

How the excerpt was made:
- Every one of the 652 events is kept, in order. That includes every prompt, assistant message, tool call
  and command, every permission denial, and the final `result` event.
- Each tool output longer than 3,000 characters is cut to its first 3,000. A marker in the text says how
  many characters were removed. In total, 44,033 characters were removed.
- Each `tool_use_result` field repeats the `tool_result` text it accompanies. In the excerpt it is replaced
  by a marker.
- Nothing else is changed. `scripts/check-session.sh sessions/a7/session-6a.excerpt.jsonl` reads the same
  final result: success, 43 turns, 3 denials.
