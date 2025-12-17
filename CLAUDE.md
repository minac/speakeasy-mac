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
├── create-app-bundle.sh                # Build script (run from root)
├── Speakeasy/
│   ├── Package.swift
│   ├── Speakeasy/
│   │   ├── SpeakeasyApp.swift          # @main, MenuBarExtra
│   │   ├── Core/                       # AppState, SpeechEngine, TextExtractor
│   │   ├── Models/                     # SpeechSettings, Voice, PlaybackState
│   │   ├── Services/                   # SettingsService, VoiceDiscoveryService
│   │   ├── Views/                      # MenuBarView, InputWindow, SettingsWindow
│   │   ├── ViewModels/
│   │   └── Resources/Info.plist
│   └── Tests/
└── build/                              # Output (gitignored)
```

### Key Patterns

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
./create-app-bundle.sh

# Build .app bundle (release)
./create-app-bundle.sh release

# Install to Applications
cp -r build/release/Speakeasy.app /Applications/

# Test
swift test --package-path Speakeasy
```

**Important:** Always use `create-app-bundle.sh` for proper `.app` bundle. Running via `swift run` causes keyboard input issues.

### App Configuration (Info.plist)
- `LSUIElement = true` (hide from dock)
- `LSApplicationCategoryType = public.app-category.utilities`
- `LSMinimumSystemVersion = 14.0`
