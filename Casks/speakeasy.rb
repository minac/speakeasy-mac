cask "speakeasy" do
  version "1.3.0"
  sha256 "614ec3c6f94ac5d20886c4554950bae0f321aa1fe10452613d16e4cc90a7d6e9"

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
