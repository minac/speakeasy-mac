cask "speakeasy" do
  version "1.0"
  sha256 "PLACEHOLDER"

  url "https://github.com/minac/speakeasy-mac/releases/download/v#{version}/Speakeasy-#{version}.dmg"
  name "Speakeasy"
  desc "Text-to-speech utility for macOS"
  homepage "https://github.com/minac/speakeasy-mac"

  depends_on macos: ">= :sonoma"

  app "Speakeasy.app"

  zap trash: [
    "~/Library/Preferences/com.migueldavid.speakeasy.plist",
    "~/Library/Application Support/Speakeasy",
  ]
end
