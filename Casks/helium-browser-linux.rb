cask "helium-browser-linux" do
  version "0.7.3.1"
  sha256 "24e53cec6cef2b9a0ae23687b1af1a2d17c872139a5fdc924cf504eaf0ea46fc"

  url "https://github.com/imputnet/helium-linux/releases/download/#{version}/helium-#{version}-x86_64_linux.tar.xz"
  name "Helium Browser"
  desc "Open-source browser based on ungoogled-chromium"
  homepage "https://github.com/imputnet/helium-linux"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "helium-#{version}-x86_64_linux/chrome-wrapper", target: "helium"
  artifact "helium.desktop",
           target: "#{Dir.home}/.local/share/applications/helium.desktop"
  artifact "helium-#{version}-x86_64_linux/product_logo_256.png",
           target: "#{Dir.home}/.local/share/icons/helium.png"

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons")

    File.write("#{staged_path}/helium.desktop", <<~EOS)
      [Desktop Entry]
      Name=Helium Browser
      Comment=Open-source browser based on ungoogled-chromium
      GenericName=Web Browser
      Exec=#{HOMEBREW_PREFIX}/bin/helium %U
      Icon=helium
      Type=Application
      StartupNotify=true
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;video/webm;application/x-xpinstall;
      StartupWMClass=helium
    EOS
  end

  zap trash: [
    "#{Dir.home}/.cache/helium",
    "#{Dir.home}/.config/helium",
  ]
end
