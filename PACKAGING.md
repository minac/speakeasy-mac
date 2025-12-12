# Speakeasy Packaging Guide

## Quick Start (Build Script Method)

```bash
cd Speakeasy
./build_app.sh
cp -r Speakeasy.app /Applications/
```

Launch via Spotlight (Cmd+Space → "Speakeasy") or from /Applications/

**First launch**: Right-click → Open (to bypass Gatekeeper warning for unsigned apps)

---

## Build Script vs Xcode Project

### Build Script (Current Method)

**What it does**:
1. Compiles release binary: `swift build -c release`
2. Creates `.app` bundle structure: `Contents/MacOS` and `Contents/Resources`
3. Copies executable into bundle
4. Generates `Info.plist` with app metadata

**Pros**:
- ✅ Simple, automated, scriptable
- ✅ No Xcode required (works with Swift CLI)
- ✅ No Apple Developer account needed
- ✅ No code signing complexity
- ✅ Works indefinitely (no expiration)
- ✅ Perfect for personal use

**Cons**:
- ❌ Not code-signed (Gatekeeper warning on first launch)
- ❌ Can't notarize for public distribution
- ❌ No app icon (shows generic icon)
- ❌ Can't submit to App Store
- ❌ Manual resource management
- ❌ No entitlements file (may affect permissions on newer macOS)

**Security**:
```
⚠️  First launch: "Speakeasy cannot be opened because it is from an unidentified developer"
Workaround: Right-click → Open (one time only)
```

**Use when**:
- Personal use only
- Not distributing to others
- Quick prototyping/development
- You're comfortable with security warnings

---

### Xcode Project Method

**What it does**:
- Full macOS app project with Xcode build system
- Code signing with Developer ID certificate
- Asset catalog management (icons, resources)
- Entitlements and provisioning profiles
- Notarization for distribution

**Pros**:
- ✅ Properly code-signed (no Gatekeeper warnings)
- ✅ Can notarize for public distribution
- ✅ App Store submission ready
- ✅ Professional app icon support
- ✅ Full debugging and profiling tools
- ✅ Proper entitlements for sensitive permissions
- ✅ Team collaboration features
- ✅ Automatic updates via Sparkle framework

**Cons**:
- ❌ Requires Xcode (11+ GB download)
- ❌ More complex setup
- ❌ Code signing requires Apple Developer ID ($99/year for full features)
- ❌ More moving parts to maintain

**Security**:
```
✅  Signed apps launch without warnings
✅  Notarized apps trusted by Gatekeeper
✅  Proper entitlements for Accessibility permissions
```

**Use when**:
- Distributing to others
- App Store submission
- Professional/commercial distribution
- Need Accessibility permissions without warnings (Phase 6)
- Team development

---

## Apple Developer ID Options

### Option 1: No Developer Account (Free)
**Method**: Build script (unsigned)
- **Cost**: Free
- **Works on**: Your Mac only
- **Duration**: Indefinite
- **Workaround**: Right-click → Open on first launch
- **Limitations**: Security warning, can't distribute

### Option 2: Free Apple ID (Limited)
**Method**: Xcode with "Personal Team"
- **Cost**: Free
- **Works on**: Your Mac only
- **Duration**: Apps expire after **7 days** (must rebuild)
- **Limitations**:
  - Can't notarize
  - Can't distribute to others
  - Limited to 3 apps
  - Must rebuild weekly
  - Restricted entitlements

**How to use**:
```
1. Open Xcode project
2. Signing & Capabilities → Team → Select "Your Name (Personal Team)"
3. Build and run
4. Rebuild every 7 days when app expires
```

### Option 3: Apple Developer Program (Full)
**Method**: Xcode with Developer ID certificate
- **Cost**: **$99 USD/year**
- **Works on**: Any Mac
- **Duration**: Indefinite
- **Features**:
  - ✅ Code signing (no expiration)
  - ✅ Notarization for public distribution
  - ✅ App Store submission
  - ✅ TestFlight beta testing
  - ✅ Full entitlements access
  - ✅ Developer support and forums

**Sign up**: https://developer.apple.com/programs/enroll/

---

## Detailed Comparison Matrix

| Feature | Build Script | Free Signing | Paid Developer |
|---------|-------------|--------------|----------------|
| **Cost** | Free | Free | $99/year |
| **Gatekeeper Warning** | Yes (bypass once) | Yes | No |
| **App Expiration** | Never | 7 days | Never |
| **Public Distribution** | No | No | Yes (notarized) |
| **App Store** | No | No | Yes |
| **App Icon** | Generic | Yes | Yes |
| **Debugging** | CLI only | Full Xcode | Full Xcode |
| **Profiling Tools** | No | Yes | Yes |
| **Entitlements** | Limited | Limited | Full |
| **Team Collaboration** | Manual | Basic | Full |
| **Automatic Updates** | No | No | Yes (Sparkle) |
| **Xcode Required** | No | Yes | Yes |

---

## Step-by-Step: Build Script Method (Current)

### 1. Build the App
```bash
cd Speakeasy
./build_app.sh
```

**What happens**:
- Compiles release binary (optimized, stripped)
- Creates `Speakeasy.app/Contents/MacOS/Speakeasy`
- Generates `Speakeasy.app/Contents/Info.plist`

### 2. Install to Applications
```bash
cp -r Speakeasy.app /Applications/
```

### 3. First Launch
**Via Spotlight**:
```
Cmd+Space → type "Speakeasy" → Enter
```

**Via Finder**:
```
Open /Applications/Speakeasy.app
```

**Expected behavior**:
1. Gatekeeper warning: "Speakeasy cannot be opened..."
2. Click "OK"
3. Right-click Speakeasy.app → Open
4. Click "Open" in the new dialog
5. App launches (icon appears in menu bar)
6. Future launches work normally (no warning)

### 4. Grant Permissions (Phase 6)
When global shortcuts are implemented:
```
System Settings → Privacy & Security → Accessibility
→ Enable "Speakeasy"
```

### 5. Rebuild After Code Changes
```bash
cd Speakeasy
./build_app.sh
cp -r Speakeasy.app /Applications/
```

**Note**: Kill running instance first:
```bash
killall Speakeasy
```

---

## Step-by-Step: Xcode Project Method (Alternative)

### 1. Generate Xcode Project
```bash
cd Speakeasy
swift package generate-xcodeproj
open Speakeasy.xcodeproj
```

**Warning**: `generate-xcodeproj` is deprecated. Better to use:
```bash
open Package.swift  # Opens in Xcode directly
```

### 2. Configure Signing (Free)
In Xcode:
1. Select project "Speakeasy" in left sidebar
2. Select target "Speakeasy"
3. Go to "Signing & Capabilities" tab
4. Check "Automatically manage signing"
5. Team → Select "Your Apple ID (Personal Team)"
6. Bundle Identifier → Change to unique ID (e.g., `com.yourname.speakeasy`)

### 3. Configure Signing (Paid Developer)
1. Same as above, but select your paid team
2. Select a provisioning profile
3. Configure entitlements as needed

### 4. Build and Archive
```
Product → Archive
```

When archive completes:
1. Organizer window opens
2. Select archive
3. "Distribute App"
4. "Copy App" → Choose location
5. Copy to /Applications/

### 5. Notarization (Paid Developer Only)
```bash
# After archiving and exporting
xcrun notarytool submit Speakeasy.app.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "YOUR_TEAM_ID" \
  --wait

# Staple the notarization ticket
xcrun stapler staple Speakeasy.app
```

---

## Build Script Details

### Script Location
```
Speakeasy/build_app.sh
```

### Script Breakdown
```bash
# 1. Build release binary
swift build -c release

# 2. Create bundle structure
mkdir -p Speakeasy.app/Contents/MacOS
mkdir -p Speakeasy.app/Contents/Resources

# 3. Copy executable
cp .build/release/Speakeasy Speakeasy.app/Contents/MacOS/

# 4. Generate Info.plist
cat > Speakeasy.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
...
EOF
```

### Info.plist Configuration
```xml
<key>LSUIElement</key>
<true/>  <!-- Hide from Dock, menu bar app only -->

<key>LSApplicationCategoryType</key>
<string>public.app-category.utilities</string>

<key>NSAppleEventsUsageDescription</key>
<string>Speakeasy needs accessibility permissions for global keyboard shortcuts.</string>
```

### Customization
Edit `build_app.sh` to change:
- Bundle identifier: `com.yourdomain.speakeasy`
- Version numbers
- Usage descriptions
- Minimum macOS version

---

## Troubleshooting

### "Cannot be opened because it is from an unidentified developer"
**Solution**: Right-click → Open (one time only)

### App doesn't appear in Applications folder
```bash
# Verify it was copied
ls -la /Applications/Speakeasy.app

# If missing, copy again
cd Speakeasy
cp -r Speakeasy.app /Applications/
```

### App crashes on launch
```bash
# Check crash logs
log show --predicate 'process == "Speakeasy"' --last 1m

# Run from command line to see errors
/Applications/Speakeasy.app/Contents/MacOS/Speakeasy
```

### Changes not reflected after rebuild
```bash
# Kill running instance
killall Speakeasy

# Clear LaunchServices cache (if needed)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -kill -r -domain local -domain system -domain user

# Rebuild and reinstall
cd Speakeasy
./build_app.sh
cp -r Speakeasy.app /Applications/
```

### Accessibility permissions not working
1. System Settings → Privacy & Security → Accessibility
2. Remove Speakeasy if present
3. Quit and relaunch app
4. Grant permission when prompted

For persistent issues with unsigned app:
- May need Xcode project with proper entitlements
- Consider paid Developer ID for Phase 6 (global shortcuts)

---

## Recommendations by Use Case

### Personal Use Only
✅ **Use build script** (no signing)
- Simplest approach
- No cost
- One-time Gatekeeper bypass

### Share with 1-5 Friends
⚠️ **Build script + instructions**
- Share .app bundle
- Include instructions for right-click → Open
- Acceptable for tech-savvy users

### Public Distribution (10+ users)
✅ **Xcode + paid Developer ID**
- Code sign + notarize
- Professional experience
- No security warnings
- Worth the $99/year

### App Store
✅ **Xcode + paid Developer ID**
- Required for submission
- Full review process
- Automatic updates

### Open Source Project
✅ **Both approaches**
- Provide build script for developers
- Provide notarized .dmg for end users
- Document both in README

---

## Future Enhancements

### Adding App Icon
**Build script**: Add icon to `Contents/Resources/`
```bash
# Create icon.icns from PNG
# Add to build_app.sh:
cp icon.icns "$CONTENTS/Resources/"
# Update Info.plist:
<key>CFBundleIconFile</key>
<string>icon</string>
```

**Xcode**: Use Asset Catalog (.xcassets)

### Code Signing Script
For automation with Developer ID:
```bash
codesign --deep --force --sign "Developer ID Application: Your Name" Speakeasy.app
```

### Creating .dmg for Distribution
```bash
# Create distributable disk image
hdiutil create -volname Speakeasy \
  -srcfolder Speakeasy.app \
  -ov -format UDZO \
  Speakeasy.dmg
```

### Sparkle for Auto-Updates
Requires Xcode project + framework integration
- Check for updates on launch
- Download and install automatically
- Requires code signing

---

## Resources

**Apple Documentation**:
- Distributing Apps: https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases
- Notarizing: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- Code Signing: https://developer.apple.com/support/code-signing/

**Tools**:
- Xcode: https://developer.apple.com/xcode/
- Developer Program: https://developer.apple.com/programs/
- App Icon Generator: https://github.com/Create-Xcode-App-Icon

**Community**:
- Swift Forums: https://forums.swift.org/
- Stack Overflow: [macos] [code-signing] tags
