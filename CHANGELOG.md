# Changelog

## v2.0

- **Custom Dictionary** — Add custom vocabulary replacements in Settings > Dictionary. Define "heard as" → "replace with" pairs (e.g., "one on one" → "1:1") that are applied deterministically after transcription.
- **Permission detection fix** — After delete/reinstall, mic and accessibility permissions are now detected correctly even when macOS returns stale status. Settings window rechecks permissions automatically.

## v1.1

- Remote model config — model can be updated without rebuilding the app
- Auto-recovery from corrupted model cache (no manual intervention needed)
- Whisper hallucination filtering (strips [BLANK_AUDIO], [SILENCE], etc.)
- Pipeline timing logs for transcription and LLM processing
- Updated LLM model to Claude Sonnet 4.6
- Improved permission settings with direct links to System Settings

## v1.0

- Initial release — macOS menu bar dictation app
- Hold-to-talk hotkey with Whisper speech-to-text
- Claude AI post-processing for grammar and filler word cleanup
- Text injection into any focused app via accessibility
- Launch at login support
