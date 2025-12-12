# Speakeasy - Project Instructions

## Permissions
- All `git` commands are allowed without confirmation (checkout, add, commit, push, pull, branch, merge)
- All `gh` commands are allowed without confirmation (pr create, pr edit)
- File operations (Read, Write, Edit) allowed without confirmation

## Development Workflow
- Follow TDD: write tests first, then implementation
- Work in feature branches: `cl-<description>`
- Run tests frequently
- Run linting at the end of each commit
- Commit with descriptive messages following project conventions

## Architecture Notes

### Core Design Decisions
- **TTS Engine**: Piper TTS for offline, privacy-friendly text-to-speech
  - Why: No API keys, works offline, lightweight, multiple voices
  - Voice models are `.onnx` files + `.json` configs stored in `voices/`
  - Synthesis returns numpy arrays (int16, 22050 Hz sample rate)

- **Target Platform**: macOS only
