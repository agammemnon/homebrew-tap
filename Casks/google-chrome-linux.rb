cask "google-chrome-linux" do
  version "152.0.7977.64"
  sha256 :no_check

  url "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
  name "Google Chrome"
  desc "Web browser"
  homepage "https://www.google.com/chrome/"

  livecheck do
    url "https://versionhistory.googleapis.com/v1/chrome/platforms/linux/channels/stable/versions"
    strategy :json do |json|
      json["versions"]&.first&.dig("version")
    end
  end

  binary "#{staged_path}/chrome-extracted/opt/google/chrome/google-chrome", target: "google-chrome"

  preflight_steps do
    mkdir_p "chrome-extracted"
    run "rpm2cpio", args:        ["{{staged_path}}/google-chrome-stable_current_x86_64.rpm"],
                    stdout_path: "google-chrome.cpio"
    run "cpio", args: ["-idmv"],
                stdin_path: "google-chrome.cpio", chdir: "chrome-extracted"
    remove ["google-chrome-stable_current_x86_64.rpm", "google-chrome.cpio"]

    mkdir_p ".local/share/applications", base: :home

    if_path_exists "chrome-extracted/usr/share/applications/google-chrome.desktop" do
      copy "chrome-extracted/usr/share/applications/google-chrome.desktop",
           ".local/share/applications/google-chrome.desktop", target_base: :home
      inreplace ".local/share/applications/google-chrome.desktop", /^Exec=.*/,
                "Exec={{HOMEBREW_PREFIX}}/bin/google-chrome %U", base: :home, audit_result: false
    end
    unless_path_exists "chrome-extracted/usr/share/applications/google-chrome.desktop" do
      write_file ".local/share/applications/google-chrome.desktop", <<~EOS, base: :home
        [Desktop Entry]
        Name=Google Chrome
        Comment=Access the Internet
        GenericName=Web Browser
        Exec={{HOMEBREW_PREFIX}}/bin/google-chrome %U
        Icon=google-chrome
        Type=Application
        StartupNotify=true
        StartupWMClass=Google-chrome
        Categories=Network;WebBrowser;
        Keywords=web;browser;internet;
        MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
      EOS
    end
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/google-chrome.desktop", base: :home
  end

  zap trash: [
    "~/.cache/google-chrome",
    "~/.config/google-chrome",
    "~/.local/share/applications/google-chrome.desktop",
  ]
end
