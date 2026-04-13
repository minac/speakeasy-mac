# Speakeasy

Native macOS menu bar application for reading text and URLs aloud, with built-in system TTS and optional Google Cloud TTS for premium voice quality.

![Speakeasy reading text with word highlighting](docs/screenshots/read-window-while-reading.png)

## Features

- **Dual TTS engines**: Free system voices (AVSpeechSynthesizer) or premium Google Cloud TTS
- Menu bar interface with SwiftUI
- URL content extraction with HTML parsing
- Customizable voice and playback speed (0.5x - 2.0x)
- Real-time playback progress with text highlighting
- Playback controls: play/stop (input window), pause/resume/stop (menu bar)
- API key stored securely in macOS Keychain
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
3. Launch from Applications or Spotlight

### Option 3: Build from Source

```bash
git clone https://github.com/minac/speakeasy-mac.git
cd speakeasy-mac
./run.sh build release
cp -r build/release/Speakeasy.app /Applications/
```

## Usage

1. Click the speaker icon in the menu bar
2. Select "Read Text..."

![Menu bar dropdown](docs/screenshots/tray-menu.png)

3. Enter text or paste a URL
4. Click "Play" to start playback (button changes to "Stop")

![Text input window](docs/screenshots/read-window-with-text.png)

### Playback Controls

- **Input Window**: Play/Stop toggle button
- **Menu Bar**: Pause, Resume, and Stop buttons appear during playback with progress indicator

### Settings

- **Engine**: Switch between System (free) and Google Cloud TTS
- **Voice**: Choose from system voices or Google Cloud voices
- **Speed**: Adjust playback speed (0.5x - 2.0x)

![Settings window](docs/screenshots/settings.png)

### Getting Better Voices (Free)

For more natural-sounding free voices on macOS:

1. Open **System Settings > Accessibility > Spoken Content**
2. Click **System Voice > Manage Voices...**
3. Download **Enhanced** or **Premium** versions

## Google Cloud TTS Setup

Google Cloud TTS provides dramatically better voice quality than system voices. The free tier includes **1 million characters per month** for standard voices and **1 million for WaveNet/Neural2** — most users will pay nothing.

### 1. Create a Google Cloud Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account (or create one)
3. If this is your first time, you'll get **$300 in free credits** for 90 days

### 2. Create a Project

1. Click the project dropdown at the top of the console
2. Click **New Project**
3. Name it (e.g. "Speakeasy TTS") and click **Create**
4. Make sure the new project is selected in the dropdown

### 3. Enable the Text-to-Speech API

1. Go to [APIs & Services > Library](https://console.cloud.google.com/apis/library)
2. Search for **"Cloud Text-to-Speech API"**
3. Click it, then click **Enable**

### 4. Create an API Key

1. Go to [APIs & Services > Credentials](https://console.cloud.google.com/apis/credentials)
2. Click **+ Create Credentials > API Key**
3. Copy the API key

**Recommended**: Restrict the key to only the Text-to-Speech API:
1. Click on the newly created key
2. Under **API restrictions**, select **Restrict key**
3. Choose **Cloud Text-to-Speech API** from the dropdown
4. Click **Save**

### 5. Configure in Speakeasy

1. Open Speakeasy Settings
2. Switch the engine to **Google Cloud**
3. Paste your API key — voices load automatically
4. Pick a voice (Neural2 and Studio voices sound the most natural)
5. Click **Save**

### Voice Recommendations

| Voice | Type | Description |
|-------|------|-------------|
| en-US-Neural2-D | Neural2 | Male, natural conversational tone |
| en-US-Neural2-F | Neural2 | Female, clear and natural |
| en-US-Studio-O | Studio | Male, broadcast quality |
| en-US-Studio-Q | Studio | Female, broadcast quality |
| en-GB-Neural2-B | Neural2 | British male |

### Pricing

| Tier | Free Monthly Quota | Price After |
|------|-------------------|-------------|
| Standard | 4M characters | $4/1M chars |
| WaveNet | 1M characters | $16/1M chars |
| Neural2 | 1M characters | $16/1M chars |
| Studio | 0.1M characters | $160/1M chars |

A typical article is ~5,000-10,000 characters. With Neural2 voices, the free tier covers **100-200 articles per month**.

Full pricing: [Google Cloud TTS Pricing](https://cloud.google.com/text-to-speech/pricing)

## Development

### Building

```bash
# Debug build (for development)
./run.sh build debug
open build/debug/Speakeasy-build.app
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
│   │   ├── SpeechEngine.swift          # TTS engine (system + audio playback)
│   │   └── TextExtractor.swift         # URL/HTML processing
│   ├── Models/
│   │   ├── SpeechSettings.swift        # Settings model
│   │   ├── TTSEngine.swift             # Engine enum (system/googleCloud)
│   │   ├── Voice.swift                 # Voice wrapper (system + Google)
│   │   └── PlaybackState.swift         # Playback states
│   ├── Services/
│   │   ├── SettingsService.swift       # UserDefaults persistence
│   │   ├── KeychainService.swift       # Secure API key storage
│   │   ├── GoogleCloudTTSService.swift # Google Cloud TTS API client
│   │   └── VoiceDiscoveryService.swift # System voice enumeration
│   ├── Utilities/
│   │   ├── Logger.swift                # OSLog structured logging
│   │   └── Extensions.swift            # String extensions
│   ├── Views/
│   │   ├── MenuBarView.swift           # Menu bar interface
│   │   ├── InputWindow.swift           # Text input window
│   │   ├── SettingsWindow.swift        # Settings interface
│   │   └── Components/
│   │       ├── VoicePicker.swift
│   │       ├── SpeedSlider.swift
│   │       └── HighlightedTextView.swift
│   ├── ViewModels/
│   │   ├── InputViewModel.swift
│   │   └── SettingsViewModel.swift
│   └── Resources/
│       ├── Info.plist
│       ├── Speakeasy.entitlements
│       └── Speakeasy-MAS.entitlements
└── Tests/
    ├── CoreTests/
    ├── ServicesTests/
    └── ViewModelTests/
```

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

Releases are automated via GitHub Actions — pushing a `v*` tag builds, signs, notarizes, and publishes a DMG to GitHub Releases.

## Troubleshooting

### Text input not working

Make sure you're running the app as a proper `.app` bundle (not via `swift run`), as terminal-launched apps capture keyboard input.

### Google Cloud TTS not working

1. Verify your API key is correct in Settings
2. Ensure the **Cloud Text-to-Speech API** is enabled in your Google Cloud project
3. Check that the API key is not restricted to other APIs
4. If you see "API key is invalid", regenerate the key in Google Cloud Console

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

- Built with Claude Code
