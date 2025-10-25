cask "zen-browser-linux" do
  version "1.17.3"
  sha256 "af6769492f8179f30d681c17777de1da79a6b1a44c97a1cb6a0340d497b19eb7"

  url "https://github.com/zen-browser/desktop/releases/download/#{version}b/zen.linux-x86_64.tar.xz"
  name "Zen Browser"
  desc "Privacy-focused web browser based on Firefox"
  homepage "https://github.com/zen-browser/desktop"

  livecheck do
    url "https://github.com/zen-browser/desktop/releases"
    strategy :github_releases
  end

  binary "zen/zen"
  artifact "zen.desktop",
           target: "#{Dir.home}/.local/share/applications/zen.desktop"
  artifact "zen/browser/chrome/icons/default/default128.png",
           target: "#{Dir.home}/.local/share/icons/zen.png"

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons")

    File.write("#{staged_path}/zen.desktop", <<~EOS)
      [Desktop Entry]
      Name=Zen Browser
      Comment=Privacy-focused web browser based on Firefox
      GenericName=Web Browser
      Exec=#{HOMEBREW_PREFIX}/bin/zen %U
      Icon=zen
      Type=Application
      StartupNotify=true
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
      StartupWMClass=zen
    EOS
  end

  zap trash: [
    "#{Dir.home}/.cache/zen",
    "#{Dir.home}/.zen",
  ]
end
