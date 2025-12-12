# Speakeasy

A macOS menu bar app for text-to-speech, supporting both plain text and URL content extraction.

## Features

- 🎤 Native macOS text-to-speech using AVSpeechSynthesizer
- 📱 Menu bar interface with SwiftUI
- 🌐 URL content extraction with HTML parsing
- ⚙️ Customizable voice and playback speed
- 📊 Real-time playback progress tracking
- ⏯️ Play, pause, resume, and stop controls

## Requirements

- macOS 13.0+
- Xcode 15.0+ (for development)
- Swift 5.9+

## Installation

### Option 1: Download Release Build

1. Download the latest release from the Releases page
2. Drag `Speakeasy.app` to your Applications folder
3. Launch from Applications or Spotlight

### Option 2: Build from Source

```bash
# Clone the repository
git clone <your-repo-url>
cd speakeasy-mac/Speakeasy

# Build and create app bundle
./create-app-bundle.sh release

# Install to Applications
cp -r build/Speakeasy.app /Applications/
```

## Development

### Building

```bash
# Debug build (for development)
./create-app-bundle.sh debug
open .build/debug/Speakeasy.app

# Release build (optimized)
./create-app-bundle.sh release
```

### Running Tests

```bash
swift test
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
│   │   └── PlaybackState.swift         # Playback states
│   ├── Services/
│   │   ├── SettingsService.swift       # UserDefaults persistence
│   │   └── VoiceDiscoveryService.swift # System voice enumeration
│   ├── Views/
│   │   ├── MenuBarView.swift           # Menu bar interface
│   │   ├── InputWindow.swift           # Text input window
│   │   └── SettingsWindow.swift        # Settings interface
│   ├── ViewModels/
│   │   ├── InputViewModel.swift
│   │   └── SettingsViewModel.swift
│   └── Resources/
│       └── Info.plist                  # App bundle configuration
└── Tests/
```

## Usage

### Basic Usage

1. Click the speaker icon in the menu bar
2. Select "Read Text..."
3. Enter text or paste a URL
4. Click "Play" or press **Cmd+Return**

### Keyboard Shortcuts

- **Cmd+R** - Open Read Text window
- **Cmd+,** - Open Settings
- **Cmd+Return** - Play text
- **Cmd+K** - Clear input
- **Cmd+.** - Stop playback
- **Cmd+Q** - Quit app

### Settings

- **Voice**: Choose from available macOS system voices
- **Speed**: Adjust playback speed (0.5x - 2.0x)
- **Output Directory**: Set default save location for audio exports (future feature)

### Getting Better Voices

For more natural-sounding voices:

1. Open **System Settings → Accessibility → Spoken Content**
2. Click **System Voice → Manage Voices...**
3. Download **Enhanced** or **Premium** versions

Recommended voices:
- **Samantha (Enhanced)** - US English, female
- **Alex (Enhanced)** - US English, male
- **Tom** - US English, male
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

The project uses Swift Package Manager with a custom build script to create proper macOS `.app` bundles.

**Why the custom script?**

Swift Package Manager executables don't generate proper `.app` bundles with `Info.plist` by default. The `create-app-bundle.sh` script:

1. Builds the executable with `swift build`
2. Creates proper `.app` bundle structure
3. Copies `Info.plist` with bundle identifier
4. Sets correct permissions

## Known Issues

- Global shortcuts require Accessibility permissions (not yet implemented)
- Audio export feature planned but not implemented

## Troubleshooting

### "Accessibility permissions not granted"

This warning is expected. Global shortcuts are planned for a future update.

### Text input not working

Make sure you're running the app as a proper `.app` bundle (not via `swift run`), as terminal-launched apps capture keyboard input.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`swift test`)
5. Commit your changes
6. Push to the branch
7. Open a Pull Request

## License

[Add your license here]

## Acknowledgments

- Built with Swift and SwiftUI
- Uses AVSpeechSynthesizer for TTS
- HTML parsing by SwiftSoup
