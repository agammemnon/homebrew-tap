cask "zen-browser-linux" do
  version "1.22"
  sha256 "41e725c82a2bee91a351c5fe8f8771f8e2748c7f323ebbb0138dbeaae84afbb8"

  url "https://github.com/zen-browser/desktop/releases/download/#{version}b/zen.linux-x86_64.tar.xz"
  name "Zen Browser"
  desc "Privacy-focused web browser based on Firefox"
  homepage "https://github.com/zen-browser/desktop"

  livecheck do
    url "https://github.com/zen-browser/desktop/releases"
    strategy :github_releases
  end

  binary "zen/zen"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
  end

  postflight_steps do
    write_file ".local/share/applications/zen.desktop", <<~EOS, base: :home
      [Desktop Entry]
      Name=Zen Browser
      Comment=Privacy-focused web browser based on Firefox
      GenericName=Web Browser
      Exec={{HOMEBREW_PREFIX}}/bin/zen %U
      Icon=zen
      Type=Application
      StartupNotify=true
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
      StartupWMClass=zen
    EOS
    copy "zen/browser/chrome/icons/default/default128.png", ".local/share/icons/zen.png", target_base: :home
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/zen.desktop", base: :home
    remove ".local/share/icons/zen.png", base: :home
  end

  zap trash: [
    "#{Dir.home}/.cache/zen",
    "#{Dir.home}/.zen",
  ]
end
