cask "antigravity-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.23.2,4781536860569600"

  on_macos do
    sha256 :no_check
  end
  on_linux do
    sha256 arm64_linux:  "64d11085f17edc691adbe8952d59887f257d58448705dc2a19dfa23890d36df1",
           x86_64_linux: "5232a4048ff4fa15685d9a981ba4fba573e297f3efc9b76f638e794baf775725"
  end

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/Antigravity.tar.gz"
  name "Google Antigravity"
  desc "AI Coding Agent IDE"
  homepage "https://antigravity.google/"

  livecheck do
    url "https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update/linux-x64/stable/latest"
    regex(%r{/stable/([^/]+)/}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      match[1]&.tr("-", ",").to_s
    end
  end

  binary "#{staged_path}/Antigravity/bin/antigravity"
  bash_completion "#{staged_path}/Antigravity/resources/completions/bash/antigravity"
  zsh_completion  "#{staged_path}/Antigravity/resources/completions/zsh/_antigravity"
  artifact "antigravity.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity.desktop"
  artifact "antigravity.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home

    if_path_exists "Antigravity/resources/app/out/vs/workbench/contrib/antigravityCustomAppIcon/" \
                   "browser/media/antigravity/antigravity.png" do
      copy "Antigravity/resources/app/out/vs/workbench/contrib/antigravityCustomAppIcon/" \
           "browser/media/antigravity/antigravity.png",
           "antigravity.png"
    end

    write_file "antigravity.desktop", <<~EOS
      [Desktop Entry]
      Name=Antigravity
      Comment=AI Coding Agent IDE
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/antigravity %F
      Icon=antigravity
      Type=Application
      StartupNotify=false
      StartupWMClass=Antigravity
      Categories=TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=antigravity;code;editor;ai;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec={{HOMEBREW_PREFIX}}/bin/antigravity --new-window %F
      Icon=antigravity
    EOS

    # Keep a placeholder when the archive has no icon.
    unless_path_exists "antigravity.png" do
      touch "antigravity.png"
    end
  end

  zap trash: [
    "~/.antigravity",
    "~/.config/Antigravity",
  ]
end
