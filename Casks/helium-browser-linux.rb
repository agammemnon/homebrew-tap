cask "helium-browser-linux" do
  version "0.13.6.1"
  sha256 "d066dfe1d2a4f3db0a2aa71a315fc4a072832868f65686ae0662d4a0ad8769e6"

  url "https://github.com/imputnet/helium-linux/releases/download/#{version}/helium-#{version}-x86_64_linux.tar.xz"
  name "Helium Browser"
  desc "Open-source browser based on ungoogled-chromium"
  homepage "https://github.com/imputnet/helium-linux"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "helium-#{version}-x86_64_linux/helium", target: "helium"

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons")
  end

  postflight do
    File.write("#{Dir.home}/.local/share/applications/helium.desktop", <<~EOS)
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
      Actions=new-private-window;

      [Desktop Action new-private-window]
      Name=New Private Window
      Exec=#{HOMEBREW_PREFIX}/bin/helium --incognito
    EOS
    FileUtils.cp("#{staged_path}/helium-#{version}-x86_64_linux/product_logo_256.png",
                 "#{Dir.home}/.local/share/icons/helium.png")
  end

  uninstall_postflight do
    FileUtils.rm("#{Dir.home}/.local/share/applications/helium.desktop")
    FileUtils.rm("#{Dir.home}/.local/share/icons/helium.png")
  end

  zap trash: [
    "#{Dir.home}/.cache/helium",
    "#{Dir.home}/.config/helium",
  ]
end
