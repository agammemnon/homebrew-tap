cask "zen-browser-linux" do
  version "1.15.5b"
  sha256 "10976d3935327a3262157407e40e6bad9ae1db6fe7a80d2e97e70742e1047f68"

  url "https://github.com/zen-browser/desktop/releases/download/#{version}/zen.linux-x86_64.tar.xz"
  name "Zen Browser"
  desc "Privacy-focused web browser based on Firefox"
  homepage "https://github.com/zen-browser/desktop"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+b?)$/i)
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
