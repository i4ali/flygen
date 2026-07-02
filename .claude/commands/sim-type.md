# Sim Type

Enter text into the currently focused text field in the booted iOS Simulator by placing
it on the simulator's pasteboard and pasting (⌘V). Paste is used instead of per-character
keystrokes so that multi-line text, quotes, emoji, and non-Latin characters all arrive
exactly as written, in one shot (and no per-line Return is pressed, which could otherwise
submit the composer).

This deliberately does **not** press Return or tap Send - it only fills the text. The
composer is a multi-line field, so the user taps Send themselves.

## Prerequisites

- A simulator is booted and the target text field is already focused (keyboard up).
- The simulator has a hardware keyboard connected (Simulator menu: I/O → Keyboard →
  Connect Hardware Keyboard, or ⇧⌘K) - ⌘V needs it.

## Instructions

1. The text to enter is in `$ARGUMENTS`. If it is empty, ask the user for the text instead.
2. Run this exact command. The quoted heredoc keeps apostrophes, quotes, `$`, backticks,
   etc. literal; `$(cat ...)` strips the trailing newline the heredoc adds (so no blank
   line is pasted); it copies to every booted device (handles more than one booted sim)
   and pastes with ⌘V:

```bash
cat > "$HOME/.claude/flygen-sim-type.txt" <<'FLYGEN_EOF'
$ARGUMENTS
FLYGEN_EOF
BOOTED=$(xcrun simctl list devices booted | grep -oE '[0-9A-Fa-f-]{36}')
if [ -z "$BOOTED" ]; then
  echo "ERROR: no booted simulator"
else
  for u in $BOOTED; do
    printf '%s' "$(cat "$HOME/.claude/flygen-sim-type.txt")" | xcrun simctl pbcopy "$u"
  done
  osascript \
    -e 'tell application "Simulator" to activate' \
    -e 'delay 0.5' \
    -e 'tell application "System Events" to keystroke "v" using command down'
  echo "OK: pasted into Simulator (not sent)"
fi
rm -f "$HOME/.claude/flygen-sim-type.txt"
```

3. Report that the text was pasted and remind the user to tap **Send**. Do not press
   Return or Send yourself.

## Notes

- If nothing appears, the field is not focused or the hardware keyboard is not connected -
  tell the user to fix that and retry.
- Because this pastes rather than types, multi-line briefs, emoji field labels (🗓 🕰 📍),
  and transliterated/non-Latin text all paste verbatim - including newlines.

## Arguments

$ARGUMENTS - The text (single- or multi-line) to enter into the focused simulator field.
