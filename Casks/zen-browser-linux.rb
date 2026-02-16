cask "zen-browser-linux" do
  version "1.18.8"
  sha256 "9aff58e8ac0b9b135d574d011547ef322133248e131583e4de0dead1649ba55c"

  url "https://github.com/zen-browser/desktop/releases/download/#{version}b/zen.linux-x86_64.tar.xz"
  name "Zen Browser"
  desc "Privacy-focused web browser based on Firefox"
  homepage "https://github.com/zen-browser/desktop"

  livecheck do
    url "https://github.com/zen-browser/desktop/releases"
    strategy :github_releases
  end

  binary "zen/zen"

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons")
  end

  postflight do
    File.write("#{Dir.home}/.local/share/applications/zen.desktop", <<~EOS)
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
    FileUtils.cp("#{staged_path}/zen/browser/chrome/icons/default/default128.png",
                 "#{Dir.home}/.local/share/icons/zen.png")
  end

  uninstall_postflight do
    FileUtils.rm("#{Dir.home}/.local/share/applications/zen.desktop")
    FileUtils.rm("#{Dir.home}/.local/share/icons/zen.png")
  end

  zap trash: [
    "#{Dir.home}/.cache/zen",
    "#{Dir.home}/.zen",
  ]
end
