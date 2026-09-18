cask "antigravity-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "2.5.5,4923483625488384"
  sha256 arm64_linux:  "88c167108980c33a223a8d7f0aa6aaf4dec61f0cc3950235a2698e9ffc38a49e",
         x86_64_linux: "0c5233b297d2b3aebb61af49f8944012c2953d361a5ebb16978490636917f831"

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/Antigravity%20IDE.tar.gz"
  name "Google Antigravity IDE"
  desc "AI Coding Agent IDE"
  homepage "https://antigravity.google/product/antigravity-ide"

  livecheck do
    url "https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/api/update/linux-x64/stable/latest"
    regex(%r{/stable/([^/]+)/}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      match[1]&.tr("-", ",").to_s
    end
  end

  depends_on :linux

  binary "Antigravity/bin/antigravity-ide"
  binary "Antigravity/bin/antigravity-ide", target: "antigravity"
  bash_completion "Antigravity/resources/completions/bash/antigravity-ide"
  zsh_completion  "Antigravity/resources/completions/zsh/_antigravity-ide"
  artifact "antigravity.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity.desktop"
  artifact "antigravity.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png"

  preflight_steps do
    move "Antigravity IDE", "Antigravity"
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home

    copy "Antigravity/resources/app/resources/linux/code.png", "antigravity.png"

    write_file "antigravity.desktop", <<~EOS
      [Desktop Entry]
      Name=Antigravity IDE
      Comment=AI Coding Agent IDE
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/antigravity %F
      Icon=antigravity
      Type=Application
      StartupNotify=false
      StartupWMClass=Antigravity IDE
      Categories=TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=antigravity;code;editor;ai;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec={{HOMEBREW_PREFIX}}/bin/antigravity --new-window %F
      Icon=antigravity
    EOS
  end

  zap trash: [
    "~/.antigravity",
    "~/.antigravity-ide",
    "~/.config/Antigravity IDE",
    "~/.config/Antigravity",
  ]

  caveats <<~EOS
    This cask continues to install Antigravity IDE, not the separate Antigravity agent app.
    Both `antigravity` and `antigravity-ide` launch the IDE.
    Upstream renamed its user-data directories. Existing Antigravity data is not
    migrated or removed during installation; back it up before migrating settings.
  EOS
end
