cask "zen-browser-linux" do
  os linux: "linux"

  version "1.24"
  sha256 "323f2682e73e38247a51fbcc75e5628ed2bb9b404db00cf9cf16af329a916fae"

  url "https://github.com/zen-browser/desktop/releases/download/#{version}b/zen.linux-x86_64.tar.xz"
  name "Zen Browser"
  desc "Privacy-focused web browser based on Firefox"
  homepage "https://github.com/zen-browser/desktop"

  livecheck do
    url "https://github.com/zen-browser/desktop/releases"
    strategy :github_releases
  end

  depends_on arch: :x86_64
  depends_on :linux

  binary "zen-wrapper", target: "zen"

  preflight_steps do
    # Caskroom paths change on upgrades; use one default profile across installs.
    write_file "zen-wrapper", <<~SH
      #!/bin/sh
      export MOZ_LEGACY_PROFILES=1
      exec "{{staged_path}}/zen/zen" "$@"
    SH
    set_permissions "zen-wrapper", "0755"

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

    # 1Password verifies browser ownership; reapply it to each upgraded payload.
    set_ownership "zen", user: "root", group: "root", recursive: true
  end

  uninstall_preflight_steps do
    # Restore ownership so Homebrew can remove the payload during upgrades too.
    # An empty group makes chown select the current user's login group.
    set_ownership "zen", group: "", recursive: true
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/zen.desktop", base: :home
    remove ".local/share/icons/zen.png", base: :home
  end

  zap trash: [
    "#{Dir.home}/.cache/zen",
    "#{Dir.home}/.zen",
  ]

  caveats <<~EOS
    Zen's application files are root-owned for 1Password browser verification.
    Installation, upgrades and removal may require sudo. Update Zen with Homebrew,
    not its built-in updater. Your browser profile remains user-owned.
    To enable 1Password integration, add zen to /etc/1password/custom_allowed_browsers
    and fully restart both apps. This cask does not change 1Password's allowlist.

    Zen uses a shared default profile so Caskroom version changes do not select a new profile.
    Existing users may need to select their previous profile once:
      Quit Zen completely, run `zen -P`, select your previous profile, and enable
      "Use the selected profile without asking at startup" before starting Zen.
    Installing this launcher does not modify or remove existing profiles.
  EOS
end
