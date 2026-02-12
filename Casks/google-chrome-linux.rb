cask "google-chrome-linux" do
  version "145.0.7632.67"
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

  preflight do
    # Extract RPM contents
    rpm_file = "#{staged_path}/google-chrome-stable_current_x86_64.rpm"

    # Create extraction directory
    extract_dir = "#{staged_path}/chrome-extracted"
    FileUtils.mkdir_p extract_dir

    # Extract RPM using rpm2cpio and cpio
    system "cd '#{extract_dir}' && rpm2cpio '#{rpm_file}' | cpio -idmv"

    # Remove the original RPM to save space
    FileUtils.rm rpm_file

    # Set up desktop integration
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"

    # Check if bundled desktop file exists
    bundled_desktop = "#{extract_dir}/usr/share/applications/google-chrome.desktop"
    if File.exist?(bundled_desktop)
      # Use bundled desktop file and modify Exec path
      desktop_content = File.read(bundled_desktop)
      desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/google-chrome %U")
      File.write("#{Dir.home}/.local/share/applications/google-chrome.desktop", desktop_content)
    else
      # Fallback to custom desktop file
      File.write("#{Dir.home}/.local/share/applications/google-chrome.desktop", <<~EOS)
        [Desktop Entry]
        Name=Google Chrome
        Comment=Access the Internet
        GenericName=Web Browser
        Exec=#{HOMEBREW_PREFIX}/bin/google-chrome %U
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

  uninstall_postflight do
    FileUtils.rm("#{Dir.home}/.local/share/applications/google-chrome.desktop")
  end

  zap trash: [
    "~/.cache/google-chrome",
    "~/.config/google-chrome",
    "~/.local/share/applications/google-chrome.desktop",
  ]
end
