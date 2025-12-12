# Speakeasy

Native macOS menu bar application for reading text and URLs aloud using Apple's native text-to-speech.

## Features

### 🎙️ Native Text-to-Speech
- Powered by AVSpeechSynthesizer (built into macOS)
- Access to all system voices (Samantha, Alex, etc.)
- Speed adjustment (0.5x - 2.0x)
- Play, pause, resume, and stop controls
- Real-time progress tracking
- Completion callbacks

### 🌐 Smart Text Extraction
- URL detection with automatic HTTPS upgrade
- HTTP fetching with timeout (30s)
- HTML parsing via SwiftSoup
- Automatic content cleaning (removes scripts, styles, navigation)
- Whitespace normalization
- Plain text passthrough for non-URLs

### ⚙️ Settings Management
- Full settings window with Save/Cancel/Restore Defaults
- Voice picker with quality labels (Default/Enhanced/Premium)
- Speed slider (0.5x - 2.0x) with real-time preview
- Output directory selector with native file browser
- Unsaved changes tracking
- UserDefaults persistence with automatic save
- Global keyboard shortcuts (planned)

### 🎨 Menu Bar Integration
- Lives in menu bar (no dock icon)
- Native SwiftUI interface
- Dark mode support
- Minimal, focused design

## Architecture

### Current Implementation (Phases 1-5 Complete)

**Core Components:**
- `AppState` - Central @MainActor coordinator for all app state
- `SpeechEngine` - AVSpeechSynthesizer wrapper with delegate callbacks
- `TextExtractor` - URLSession + SwiftSoup for web content extraction
- `SettingsService` - UserDefaults persistence layer
- `VoiceDiscoveryService` - System voice enumeration

**Models:**
- `SpeechSettings` - Codable settings model with UI speed conversion
- `Voice` - Wrapper for AVSpeechSynthesisVoice
- `PlaybackState` - Enum: idle, speaking, paused

**Views:**
- `MenuBarView` - Menu bar interface with status and controls
- `InputWindow` - Text/URL input with Play/Stop/Clear buttons
- `SettingsWindow` - Comprehensive settings UI
- `VoicePicker`, `SpeedSlider`, `DirectoryPicker` - Reusable components

**ViewModels:**
- `InputViewModel` - Manages input window state and processing
- `SettingsViewModel` - Manages settings with unsaved changes tracking

**Test Coverage:**
- SpeechEngineTests - TTS functionality (8 tests)
- TextExtractorTests - URL parsing and HTML extraction (23 tests)
- SettingsServiceTests - Persistence layer (7 tests)
- InputViewModelTests - Input window logic (11 tests)
- SettingsViewModelTests - Settings management (13 tests)

### Planned Features (Phases 6-7)

**Phase 6:** Global keyboard shortcuts (Carbon Events)
**Phase 7:** Polish, error handling, progress tracking

## Requirements

- **macOS 13.0+** (for MenuBarExtra API)
- **Xcode 14.0+** (for development)
- **Swift 5.9+**

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/minac/speakeasy-mac.git
cd speakeasy-mac
```

2. Open in Xcode:
```bash
cd Speakeasy
open Package.swift
```

3. Build and run (Cmd+R) or run tests (Cmd+U)

### Swift Package Manager

Build from command line:
```bash
cd Speakeasy
swift build
swift test
```

## Development

### Project Structure

```
Speakeasy/
├── Speakeasy/
│   ├── SpeakeasyApp.swift           # App entry point
│   ├── Core/
│   │   ├── AppState.swift           # Central coordinator
│   │   ├── SpeechEngine.swift       # TTS engine
│   │   └── TextExtractor.swift      # URL/HTML parsing
│   ├── Models/
│   │   ├── SpeechSettings.swift
│   │   ├── Voice.swift
│   │   └── PlaybackState.swift
│   ├── Services/
│   │   ├── SettingsService.swift
│   │   └── VoiceDiscoveryService.swift
│   ├── Views/
│   │   ├── MenuBarView.swift
│   │   ├── InputWindow.swift
│   │   ├── SettingsWindow.swift
│   │   └── Components/
│   │       ├── VoicePicker.swift
│   │       ├── SpeedSlider.swift
│   │       └── DirectoryPicker.swift
│   ├── ViewModels/
│   │   ├── InputViewModel.swift
│   │   └── SettingsViewModel.swift
│   └── Utilities/
│       └── Extensions.swift         # String URL helpers
└── Tests/
    ├── CoreTests/
    │   ├── SpeechEngineTests.swift
    │   └── TextExtractorTests.swift
    ├── ServicesTests/
    │   └── SettingsServiceTests.swift
    └── ViewModelTests/
        ├── InputViewModelTests.swift
        └── SettingsViewModelTests.swift
```

### Running Tests

```bash
# In Xcode: Cmd+U
# Or via command line (requires full Xcode):
swift test
```

### Design Principles

- **TDD:** Tests written before implementation
- **NativeFirst:** Use Apple frameworks over external dependencies
- **Simple:** Minimal abstractions, clear interfaces
- **Production-Ready:** Error handling, logging, proper concurrency

## Dependencies

- [SwiftSoup](https://github.com/scinfu/SwiftSoup) - HTML parsing (like BeautifulSoup for Swift)

## Technical Details

### Why Native TTS?

The original Python version used Piper TTS with ONNX models. The Swift rewrite uses AVSpeechSynthesizer because:

- **No external dependencies** - Built into macOS
- **High quality voices** - Apple's neural TTS
- **Better integration** - Native Swift async/await
- **Simpler deployment** - No model files to distribute
- **Maintained by Apple** - Automatic improvements with OS updates

### Thread Safety

- `SpeechEngine` uses `@MainActor` for UI thread safety
- `TextExtractor` is an `actor` for thread-safe network operations
- All delegate callbacks use `Task(priority: .userInitiated)` to avoid QoS inversions

### Settings Persistence

Settings use `Codable` + `UserDefaults` instead of JSON files:
- Type-safe serialization
- Automatic iCloud sync support
- No file path management
- Atomic writes

## License

MIT

## Contributing

This project follows TDD. Before submitting PRs:

1. Write tests first
2. Implement feature
3. Ensure all tests pass (`swift test`)
4. Follow existing code style
5. Update documentation

## Roadmap

- [x] Phase 1: Core TTS with AVSpeechSynthesizer
- [x] Phase 2: Text extraction from URLs
- [x] Phase 3: Menu bar UI with AppState coordination
- [x] Phase 4: Input window with text/URL entry
- [x] Phase 5: Settings window with voice/speed/directory pickers
- [ ] Phase 6: Global keyboard shortcuts (Carbon Events)
- [ ] Phase 7: Polish and error handling
- [ ] Future: Audio export to WAV
- [ ] Future: Clipboard monitoring
- [ ] Future: Voice customization (pitch, volume)
