# Speakeasy

A macOS menu bar app for text-to-speech, supporting both plain text and URL content extraction.

## Features

- Native macOS text-to-speech using AVSpeechSynthesizer
- Menu bar interface with SwiftUI
- URL content extraction with HTML parsing
- Customizable voice and playback speed
- Real-time playback progress with word highlighting
- Playback controls: play/stop (input window), pause/resume/stop (menu bar)
- Structured logging using OSLog

## Requirements

- macOS 14.0+
- Xcode 15.0+ (for development)
- Swift 5.9+

## Installation

### Option 1: Homebrew (recommended)

```bash
brew tap minac/speakeasy-mac
brew install --cask speakeasy
```

### Option 2: Direct Download

1. Download the latest `.dmg` from [Releases](https://github.com/minac/speakeasy-mac/releases)
2. Open the DMG and drag `Speakeasy.app` to Applications

### Option 3: Build from Source

```bash
git clone https://github.com/minac/speakeasy-mac.git
cd speakeasy-mac
./run.sh build release
cp -r build/release/Speakeasy.app /Applications/
```

## Development

### Building

```bash
# Debug build (for development)
./run.sh build debug
open build/debug/Speakeasy-build.app

# Release build (optimized)
./run.sh build release
open build/release/Speakeasy.app
```

### Running Tests

```bash
swift test --package-path Speakeasy
```

Or in Xcode: **Cmd+U**

### Project Structure

```
Speakeasy/
├── Speakeasy/
│   ├── SpeakeasyApp.swift              # App entry point
│   ├── Core/
│   │   ├── AppState.swift              # Central state management
│   │   ├── SpeechEngine.swift          # TTS engine wrapper
│   │   └── TextExtractor.swift         # URL/HTML processing
│   ├── Models/
│   │   ├── SpeechSettings.swift        # Settings model
│   │   ├── Voice.swift                 # Voice wrapper
│   │   └── PlaybackState.swift         # Playback states
│   ├── Services/
│   │   ├── SettingsService.swift       # UserDefaults persistence
│   │   └── VoiceDiscoveryService.swift # System voice enumeration
│   ├── Utilities/
│   │   ├── Logger.swift                # OSLog structured logging
│   │   └── Extensions.swift            # String extensions
│   ├── Views/
│   │   ├── MenuBarView.swift           # Menu bar interface
│   │   ├── InputWindow.swift           # Text input window
│   │   ├── SettingsWindow.swift        # Settings interface
│   │   └── Components/
│   ├── ViewModels/
│   │   ├── InputViewModel.swift
│   │   └── SettingsViewModel.swift
│   └── Resources/
│       ├── Info.plist                  # App bundle configuration
│       ├── Speakeasy.entitlements      # Homebrew/direct entitlements
│       └── Speakeasy-MAS.entitlements  # Mac App Store entitlements
└── Tests/
    ├── CoreTests/
    ├── ServicesTests/
    └── ViewModelTests/
```

## Usage

### Basic Usage

1. Click the speaker icon in the menu bar
2. Select "Read Text..."
3. Enter text or paste a URL
4. Click "Play" to start playback

### Playback Controls

- **Input Window**: Play/Stop toggle button
- **Menu Bar**: During playback, pause/resume/stop buttons with progress indicator appear in the menu bar dropdown

### Settings

- **Voice**: Choose from available macOS system voices
- **Speed**: Adjust playback speed (0.5x - 2.0x)

### Getting Better Voices

For more natural-sounding voices:

1. Open **System Settings > Accessibility > Spoken Content**
2. Click **System Voice > Manage Voices...**
3. Download **Enhanced** or **Premium** versions

Recommended voices:

- **Samantha (Enhanced)** - US English, female
- **Alex (Enhanced)** - US English, male
- **Daniel (Enhanced)** - UK English, male

## Architecture

### TTS Engine

Uses Apple's native `AVSpeechSynthesizer` for high-quality text-to-speech without external dependencies.

### Text Extraction

- **URLSession** for HTTP requests (30s timeout)
- **SwiftSoup** for HTML parsing
- Automatic content cleaning (removes scripts, styles, navigation)

### State Management

- **AppState**: Central `@MainActor ObservableObject` for app-wide state
- **Swift Concurrency**: async/await throughout
- **UserDefaults**: Settings persistence with Codable

## Dependencies

- [SwiftSoup](https://github.com/scinfu/SwiftSoup) - HTML parsing

## Build System

The project uses Swift Package Manager with `run.sh` to build, sign, and package the app.

```bash
./run.sh                    # Build and run (swift run)
./run.sh build [debug|release]  # Build .app bundle
./run.sh sign               # Code sign release build
./run.sh dmg <version>      # Create signed + notarized DMG
./run.sh mas <version>      # Create Mac App Store .pkg
./run.sh release <version>  # Full pipeline: build → sign → dmg
```

Debug builds create `Speakeasy-build.app` to avoid conflicts with release builds.

## Troubleshooting

### Text input not working

Make sure you're running the app as a proper `.app` bundle (not via `swift run`), as terminal-launched apps capture keyboard input.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests first (TDD)
4. Implement feature
5. Run tests (`swift test`)
6. Commit your changes
7. Push to the branch
8. Open a Pull Request

## License

MIT

## Acknowledgments

- Built with Swift and SwiftUI
- Uses AVSpeechSynthesizer for TTS
- HTML parsing by SwiftSoup
