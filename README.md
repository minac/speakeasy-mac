# Speakeasy

macOS menu bar application for reading text and URLs aloud using Piper TTS.

## Features

- 🎙️ Offline text-to-speech using Piper TTS
  - Voice discovery from local `.onnx` files
  - Speed adjustment (0.5x - 2.0x)
  - WAV audio synthesis
- ⚡ Audio playback controls
  - Play, stop
  - Position and duration tracking
  - Playback state management
  - Completion callbacks
- 🌐 Text extraction from URLs
  - URL detection with protocol validation
  - HTTP fetching with proper headers
  - HTML parsing and content cleaning
  - Whitespace normalization
  - Plain text passthrough
- ⚙️ Settings management
  - JSON persistence with defaults
  - Nested settings with dot notation
  - Voice, speed, output directory, shortcuts
- ⌨️ Global keyboard shortcuts
  - System-wide hotkey registration
  - Configurable key bindings
  - Parse "ctrl+shift+p" format
  - Runtime hotkey updates
- 🎨 Menu bar UI with system tray icon
  - Simple menu with Read Text, Settings, and Quit
  - SVG icon with macOS template support (auto-inverts on dark menu bar)
- 🪟 UI Windows
  - Input window for text/URL entry
  - Settings window for configuration

## Requirements

- **macOS**
- **Swift**
- **Piper voice models**

### Download Piper Voice Models

Download voice models from [Piper Huggingface](https://huggingface.co/rhasspy/piper-voices/tree/main)) and place them in the `voices/` directory:

```bash
# Create voices directory
mkdir -p voices

# Example: Download a voice model
cd voices
curl -L -o en_US-lessac-high.onnx https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/lessac/high/en_US-lessac-high.onnx
curl -L -o en_US-lessac-high.onnx.json https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/lessac/high/en_US-lessac-high.onnx.json
cd ..
```
