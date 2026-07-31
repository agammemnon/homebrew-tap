cask "peekcal" do
  version "1.3"
  sha256 "d4885bfa46f1c6fb00415d70f6902203851c279c2cd9c87511082c7f4cc35523"

  url "https://peekcal.nodegroup.ca/PeekCal-#{version}.zip"
  name "PeekCal"
  desc "Menu bar view of a shared Google Calendar work week"
  homepage "https://peekcal.nodegroup.ca/"

  livecheck do
    url "https://peekcal.nodegroup.ca/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :ventura
  depends_on arch: :arm64

  app "PeekCal.app"

  uninstall quit: "ca.nodegroup.peekcal"

  zap trash: [
    "~/Library/Caches/ca.nodegroup.peekcal",
    "~/Library/HTTPStorages/ca.nodegroup.peekcal",
    "~/Library/HTTPStorages/ca.nodegroup.peekcal.binarycookies",
    "~/Library/Preferences/ca.nodegroup.peekcal.plist",
    "~/Library/WebKit/ca.nodegroup.peekcal",
  ]
end
