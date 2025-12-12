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
- **macOS 13.0+** (for MenuBarExtra API)
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
│   │   ├── TextExtractor.swift         # URLSession + SwiftSoup
│   │   └── ShortcutManager.swift       # Global hotkeys (Phase 6)
│   ├── Models/
│   │   ├── SpeechSettings.swift        # Codable settings
│   │   ├── Voice.swift                 # AVSpeechSynthesisVoice wrapper
│   │   └── PlaybackState.swift         # idle/speaking/paused
│   ├── Services/
│   │   ├── SettingsService.swift       # UserDefaults persistence
│   │   └── VoiceDiscoveryService.swift # System voice enumeration
│   ├── Views/                          # SwiftUI views (Phase 3+)
│   ├── ViewModels/                     # View models (Phase 4+)
│   └── Utilities/
│       └── Extensions.swift            # String URL helpers
└── Tests/
    ├── CoreTests/
    └── ServicesTests/
```

### Implementation Phases

**✅ Phase 1: Core TTS** (Complete)
- SpeechEngine with AVSpeechSynthesizer
- SettingsService with UserDefaults
- VoiceDiscoveryService
- Comprehensive test coverage

**✅ Phase 2: Text Extraction** (Complete)
- TextExtractor with URLSession + SwiftSoup
- URL validation and normalization
- HTML parsing and cleaning
- Test coverage for all extraction logic

**⏳ Phase 3: Menu Bar UI** (Next)
- MenuBarExtra implementation
- AppState central coordinator
- Menu items: Read Text, Settings, Quit

**📋 Phase 4: Input Window**
- SwiftUI window for text/URL input
- InputViewModel
- Play/Stop controls

**📋 Phase 5: Settings Window**
- Voice picker
- Speed slider
- Output directory selector

**📋 Phase 6: Global Shortcuts**
- Carbon Events API (or MASShortcut library)
- Accessibility permissions handling
- Cmd+Shift+P default for "Read Text"

**📋 Phase 7: Polish**
- Error handling UI
- Progress tracking
- Loading states
- Edge case handling

### Testing Strategy

- **Unit tests**: Fast, no UI dependencies
- **Integration tests**: Cross-component functionality
- **Network tests**: Real URL fetching (may be slow)
- **QoS handling**: All async tasks use `.userInitiated` priority to avoid inversions
- **Target**: 80%+ coverage

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
- **No Piper TTS**: Using native AVSpeechSynthesizer instead
- **Optional MASShortcut**: For easier global shortcuts (Phase 6)

### Build & Test Commands

```bash
# Build
swift build

# Test (requires full Xcode)
swift test

# In Xcode
# Build: Cmd+B
# Test: Cmd+U
# Run: Cmd+R
```

### App Configuration

**Info.plist:**
- `LSUIElement = true` (hide from dock)
- `LSApplicationCategoryType = public.app-category.utilities`
- `NSAppleEventsUsageDescription` for accessibility permissions

**No App Sandbox**: Required for global shortcuts with accessibility permissions

### Differences from Python Version

| Feature | Python | Swift |
|---------|--------|-------|
| TTS | Piper (ONNX) | AVSpeechSynthesizer |
| UI | tkinter | SwiftUI |
| HTTP | requests | URLSession |
| HTML | BeautifulSoup | SwiftSoup |
| Settings | JSON file | UserDefaults + Codable |
| Threading | Queue-based | async/await |
| Shortcuts | pynput (broken) | Carbon Events |

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
