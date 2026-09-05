cask "helium-browser-linux" do
  version "0.16.2.1"
  sha256 "800838069272870a6f4fc9eadf017c0819f7d89abf607117080b079d4bf7c017"

  url "https://github.com/imputnet/helium-linux/releases/download/#{version}/helium-#{version}-x86_64_linux.tar.xz"
  name "Helium Browser"
  desc "Open-source browser based on ungoogled-chromium"
  homepage "https://github.com/imputnet/helium-linux"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "helium-#{version}-x86_64_linux/helium", target: "helium"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
  end

  postflight_steps do
    write_file ".local/share/applications/helium.desktop", <<~EOS, base: :home
      [Desktop Entry]
      Name=Helium Browser
      Comment=Open-source browser based on ungoogled-chromium
      GenericName=Web Browser
      Exec={{HOMEBREW_PREFIX}}/bin/helium %U
      Icon=helium
      Type=Application
      StartupNotify=true
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;video/webm;application/x-xpinstall;
      StartupWMClass=helium
      Actions=new-private-window;

      [Desktop Action new-private-window]
      Name=New Private Window
      Exec={{HOMEBREW_PREFIX}}/bin/helium --incognito
    EOS
    copy "helium-{{version}}-x86_64_linux/product_logo_256.png", ".local/share/icons/helium.png", target_base: :home
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/helium.desktop", base: :home
    remove ".local/share/icons/helium.png", base: :home
  end

  zap trash: [
    "#{Dir.home}/.cache/helium",
    "#{Dir.home}/.config/helium",
  ]
end
