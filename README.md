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
- UserDefaults persistence
- Voice selection from available system voices
- Adjustable speech rate
- Configurable output directory
- Global keyboard shortcuts (planned)

### 🎨 Menu Bar Integration
- Lives in menu bar (no dock icon)
- Native SwiftUI interface
- Dark mode support
- Minimal, focused design

## Architecture

### Current Implementation (Phases 1-2 Complete)

**Core Components:**
- `SpeechEngine` - AVSpeechSynthesizer wrapper with delegate callbacks
- `TextExtractor` - URLSession + SwiftSoup for web content extraction
- `SettingsService` - UserDefaults persistence layer
- `VoiceDiscoveryService` - System voice enumeration

**Models:**
- `SpeechSettings` - Codable settings model
- `Voice` - Wrapper for AVSpeechSynthesisVoice
- `PlaybackState` - Enum: idle, speaking, paused

**Test Coverage:**
- SpeechEngineTests - TTS functionality
- TextExtractorTests - URL parsing and HTML extraction
- SettingsServiceTests - Persistence layer

### Planned Features (Phases 3-7)

**Phase 3:** Menu bar UI with MenuBarExtra
**Phase 4:** Input window for text/URL entry
**Phase 5:** Settings window for configuration
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
│   │   ├── SpeechEngine.swift       # TTS engine
│   │   └── TextExtractor.swift      # URL/HTML parsing
│   ├── Models/
│   │   ├── SpeechSettings.swift
│   │   ├── Voice.swift
│   │   └── PlaybackState.swift
│   ├── Services/
│   │   ├── SettingsService.swift
│   │   └── VoiceDiscoveryService.swift
│   └── Utilities/
│       └── Extensions.swift         # String URL helpers
└── Tests/
    ├── CoreTests/
    │   ├── SpeechEngineTests.swift
    │   └── TextExtractorTests.swift
    └── ServicesTests/
        └── SettingsServiceTests.swift
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
- [ ] Phase 3: Menu bar UI
- [ ] Phase 4: Input window
- [ ] Phase 5: Settings window
- [ ] Phase 6: Global keyboard shortcuts
- [ ] Phase 7: Polish and error handling
- [ ] Future: Audio export to WAV
- [ ] Future: Clipboard monitoring
- [ ] Future: Voice customization (pitch, volume)
