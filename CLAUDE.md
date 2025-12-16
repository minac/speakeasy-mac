# Speakeasy - Project Instructions

## Permissions
- All `git` commands are allowed without confirmation (checkout, add, commit, push, pull, branch, merge)
- All `gh` commands are allowed without confirmation (pr create, pr edit)
- All `swift` commands allowed without confirmation (build, test, run)
- File operations (Read, Write, Edit) allowed without confirmation

## Development Workflow
- **TDD religiously**: Write tests first, then implementation
- Work in feature branches: `cl-<description>`
- Run tests frequently: `swift test` or Cmd+U in Xcode
- Run linting at the end of each commit (if configured)
- Commit with descriptive messages following project conventions
- All tests must pass before committing

## Architecture Notes

### Core Design Decisions

#### TTS Engine: AVSpeechSynthesizer (Native macOS)
- **Why**: Native Apple framework, no external dependencies, high quality
- **Benefits**:
  - No ONNX models to manage
  - Automatic improvements with OS updates
  - Better macOS integration (permissions, sandboxing)
  - Native async/await support
  - All system voices available (Samantha, Alex, etc.)
- **API**: AVSpeechSynthesizer with delegate callbacks
- **Thread Safety**: `@MainActor` for UI thread safety, delegate callbacks use `Task(priority: .userInitiated)`

#### Target Platform
- **macOS 14.0+** (for SwiftUI onChange API)
- **Swift 5.9+**
- **SwiftUI** for all UI components
- **Swift Package Manager** for dependencies

#### State Management
- **AppState**: Single `@MainActor ObservableObject` - central source of truth
- **No queues**: Swift Concurrency (async/await) replaces Python queue-based threading
- **Actors**: `TextExtractor` is an actor for thread-safe network operations

#### Settings Persistence
- **UserDefaults + Codable** instead of JSON files
- Type-safe serialization
- Automatic iCloud sync support
- No file path management needed

#### Text Extraction
- **URLSession**: Native HTTP client (30s timeout)
- **SwiftSoup**: HTML parsing (like BeautifulSoup)
- **Content cleaning**: Removes script, style, nav, footer, aside tags
- **Plain text passthrough**: Non-URLs returned as-is

### Project Structure

```
Speakeasy/
├── Speakeasy/
│   ├── SpeakeasyApp.swift              # @main, MenuBarExtra
│   ├── Core/
│   │   ├── AppState.swift              # Central state coordinator
│   │   ├── SpeechEngine.swift          # AVSpeechSynthesizer wrapper
│   │   └── TextExtractor.swift         # URLSession + SwiftSoup
│   ├── Models/
│   │   ├── SpeechSettings.swift        # Codable settings
│   │   ├── Voice.swift                 # AVSpeechSynthesisVoice wrapper
│   │   └── PlaybackState.swift         # idle/speaking/paused
│   ├── Services/
│   │   ├── SettingsService.swift       # UserDefaults persistence
│   │   └── VoiceDiscoveryService.swift # System voice enumeration
│   ├── Views/
│   │   ├── MenuBarView.swift           # Menu bar dropdown
│   │   ├── InputWindow.swift           # Text/URL input window
│   │   ├── SettingsWindow.swift        # Settings window
│   │   └── Components/
│   │       ├── VoicePicker.swift       # Voice selection dropdown
│   │       ├── SpeedSlider.swift       # Speed adjustment slider
│   │       └── HighlightedTextView.swift # Word highlighting during playback
│   ├── ViewModels/
│   │   ├── InputViewModel.swift        # Input window logic
│   │   └── SettingsViewModel.swift     # Settings management
│   └── Utilities/
│       ├── Extensions.swift            # String URL helpers
│       └── Logger.swift                # Structured logging
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

### Testing Strategy

- **Unit tests**: Fast, no UI dependencies
- **Integration tests**: Cross-component functionality
- **Network tests**: Real URL fetching (may be slow)
- **QoS handling**: All async tasks use `.userInitiated` priority to avoid inversions
- **Target**: 80%+ coverage
- **Current**: 58 tests passing

### Key Technical Patterns

#### Speech Engine
```swift
@MainActor
class SpeechEngine: NSObject, ObservableObject {
    @Published private(set) var state: PlaybackState = .idle
    private let synthesizer = AVSpeechSynthesizer()

    func speak(text: String, voiceIdentifier: String?, rate: Float) async throws
    func pause()
    func resume()
    func stop()
}
```

#### Text Extractor
```swift
actor TextExtractor {
    func extractText(from input: String) async throws -> String
    private func parseHTML(_ data: Data) throws -> String
}
```

#### Settings Service
```swift
class SettingsService {
    func loadSettings() -> SpeechSettings
    func saveSettings(_ settings: SpeechSettings)
}
```

### Common Patterns

#### URL Validation
```swift
extension String {
    var isValidURL: Bool  // http://, https://, www.
    func addingHTTPSIfNeeded() -> String?  // Normalizes to https://
}
```

#### Speed Conversion
```swift
// UI: 0.5x - 2.0x → AVSpeechSynthesizer: 0.0 - 1.0
SpeechSettings.uiSpeedToRate(_ uiSpeed: Float) -> Float
SpeechSettings.rateToUISpeed(_ rate: Float) -> Float
```

### Dependencies

- **SwiftSoup** (2.6.0+): HTML parsing

### Build & Test Commands

```bash
# Build executable only
swift build

# Build and create .app bundle (debug)
./create-app-bundle.sh
# or
./create-app-bundle.sh debug

# Build and create .app bundle (release)
./create-app-bundle.sh release

# Install to Applications (release only)
cp -r build/release/Speakeasy.app /Applications/

# Test (requires full Xcode)
swift test

# In Xcode
# Build: Cmd+B
# Test: Cmd+U
# Run: Cmd+R (warning: runs with Xcode scheme limitations)
```

**Important:** Always use the `create-app-bundle.sh` script to create a proper `.app` bundle. Running via `swift run` or directly from Xcode will attach the app to the terminal/IDE, causing keyboard input issues.

**Note:** Debug builds create `Speakeasy-build.app` to distinguish from release builds.

### App Configuration

**Info.plist:**
- `LSUIElement = true` (hide from dock)
- `LSApplicationCategoryType = public.app-category.utilities`
- `LSMinimumSystemVersion = 14.0`

### Differences from Python Version

| Feature | Python | Swift |
|---------|--------|-------|
| TTS | Piper (ONNX) | AVSpeechSynthesizer |
| UI | tkinter | SwiftUI |
| HTTP | requests | URLSession |
| HTML | BeautifulSoup | SwiftSoup |
| Settings | JSON file | UserDefaults + Codable |
| Threading | Queue-based | async/await |

### Known Issues & Solutions

**QoS Priority Inversions:**
- Use `Task(priority: .userInitiated)` in delegate callbacks
- Avoids test warnings about thread priorities

**XCTest with async/await:**
- Use do-catch instead of `XCTAssertThrowsError` for async functions
- Pattern: `do { try await ...; XCTFail() } catch { assert... }`

**Large Files:**
- No voice models needed (using native TTS)
- `.gitignore` excludes voices/, screenshots/, build artifacts

### Future Enhancements

- WAV audio export using AVSpeechSynthesizer.write()
- Clipboard monitoring for auto-reading
- Voice customization (pitch, volume, AVSpeechUtterance properties)
- Multiple language support
- Keyboard navigation in UI
- VoiceOver accessibility support
- Global keyboard shortcuts (requires accessibility permissions)
