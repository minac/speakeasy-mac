# Speakeasy - Project Instructions

## Architecture

### Core Design Decisions

#### TTS Engine: AVSpeechSynthesizer (Native macOS)

- **Why**: Native Apple framework, no external dependencies, high quality
- **Benefits**: No ONNX models, automatic OS improvements, better macOS integration, native async/await
- **Thread Safety**: `@MainActor` for UI, delegate callbacks use `Task(priority: .userInitiated)`

#### Platform & Stack

- macOS 14.0+ (for SwiftUI onChange API)
- Swift 5.9+, SwiftUI, Swift Package Manager
- **SwiftSoup** (2.6.0+): HTML parsing

#### State Management

- **AppState**: Single `@MainActor ObservableObject` - central source of truth
- Swift Concurrency (async/await) instead of queues
- **Actors**: `TextExtractor` is an actor for thread-safe network operations

#### Settings Persistence

- **UserDefaults + Codable** instead of JSON files
- Type-safe serialization, automatic iCloud sync

#### Text Extraction

- **URLSession**: Native HTTP client (30s timeout)
- Content cleaning: Removes script, style, nav, footer, aside tags
- Plain text passthrough: Non-URLs returned as-is

### Project Structure

```
speakeasy-mac/
├── local-ci.sh                         # Local CI (build + test)
├── run.sh                              # Build, sign, package, release
├── Speakeasy/
│   ├── Package.swift
│   ├── Speakeasy/
│   │   ├── SpeakeasyApp.swift          # @main, MenuBarExtra
│   │   ├── Core/                       # AppState, SpeechEngine, TextExtractor
│   │   ├── Models/                     # SpeechSettings, Voice, PlaybackState
│   │   ├── Services/                   # SettingsService, VoiceDiscoveryService
│   │   ├── Utilities/                  # Logger (OSLog), Extensions
│   │   ├── Views/                      # MenuBarView, InputWindow, SettingsWindow, Components
│   │   ├── ViewModels/
│   │   └── Resources/                  # Info.plist, entitlements
│   └── Tests/                          # CoreTests, ServicesTests, ViewModelTests
└── build/                              # Output (gitignored)
```

### Key Patterns

#### Structured Logging

Uses OSLog for production-grade structured logging:

```swift
AppLogger.app.info("message")      // App lifecycle
AppLogger.speech.debug("...")      // Speech engine
AppLogger.extraction.error("...")  // URL/text extraction
AppLogger.settings.info("...")     // Settings persistence
```

#### Speech Engine

```swift
@MainActor
class SpeechEngine: NSObject, ObservableObject {
    @Published private(set) var state: PlaybackState = .idle
    func speak(text: String, voiceIdentifier: String?, rate: Float) async throws
    func pause() / resume() / stop()
}
```

#### Text Extractor

```swift
actor TextExtractor {
    func extractText(from input: String) async throws -> String
}
```

#### URL Validation

```swift
extension String {
    var isValidURL: Bool  // http://, https://, www.
    func addingHTTPSIfNeeded() -> String?
}
```

#### Speed Conversion

```swift
// UI: 0.5x - 2.0x → AVSpeechSynthesizer: 0.0 - 1.0
SpeechSettings.uiSpeedToRate(_ uiSpeed: Float) -> Float
SpeechSettings.rateToUISpeed(_ rate: Float) -> Float
```

### Build Commands

```bash
# Build executable only
swift build --package-path Speakeasy

# Build .app bundle (debug)
./run.sh build debug

# Build .app bundle (release)
./run.sh build release

# Code sign release build
./run.sh sign

# Create signed + notarized DMG
./run.sh dmg 1.0

# Create MAS .pkg
./run.sh mas 1.0

# Full release pipeline (build → sign → dmg → notarize)
./run.sh release 1.0

# Install to Applications
cp -r build/release/Speakeasy.app /Applications/

# Test
swift test --package-path Speakeasy

# Local CI (build + test)
./local-ci.sh
```

**Important:** Always use `./run.sh build` for proper `.app` bundle. Running via `swift run` (or `./run.sh` with no args) causes keyboard input issues.

### App Configuration (Info.plist)

- `CFBundleIdentifier = com.migueldavid.speakeasy`
- `LSUIElement = true` (hide from dock)
- `LSApplicationCategoryType = public.app-category.utilities`
- `LSMinimumSystemVersion = 14.0`
- `ITSAppUsesNonExemptEncryption = false`

### Playback Controls

- **Input Window**: Play/Stop toggle button for starting/stopping playback
- **Menu Bar**: Pause/Resume/Stop buttons appear in dropdown during active playback
- **Playback States**: idle, speaking, paused (enum PlaybackState)
