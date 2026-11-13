cask "antigravity-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "2.7.0,4507555968450560"
  sha256 arm64_linux:  "70c1938815408c3d3a2acfff303e3f627a8b16b7b85dd3d572bca7571c3a5ebb",
         x86_64_linux: "9360a86521c3e5498846254b743b1f3203768ebadf65a178bc549395936f7a5d"

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
  artifact "antigravity-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-url-handler.desktop"
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
      MimeType=text/plain;inode/directory;application/x-code-workspace;x-scheme-handler/antigravity-ide;
      Actions=new-empty-window;
      Keywords=antigravity;code;editor;ai;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec={{HOMEBREW_PREFIX}}/bin/antigravity --new-window %F
      Icon=antigravity
    EOS

    # Sign-in returns to the IDE through its `antigravity-ide://` URL scheme
    # (`urlProtocol` in product.json), which needs its own hidden launcher.
    write_file "antigravity-url-handler.desktop", <<~EOS
      [Desktop Entry]
      Name=Antigravity IDE - URL Handler
      Comment=AI Coding Agent IDE
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/antigravity --open-url %U
      Icon=antigravity
      Type=Application
      NoDisplay=true
      Terminal=false
      StartupNotify=true
      StartupWMClass=Antigravity IDE
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/antigravity-ide;
      Keywords=antigravity;code;editor;ai;
    EOS
  end

  # GIO trusts mimeinfo.cache when one exists, so refresh it or the scheme handler stays
  # invisible to browsers until something else rebuilds the cache. Steps cannot expand
  # the home directory in arguments, so reach it through a staged symlink.
  postflight_steps do
    symlink ".local/share/applications", "user-applications", source_base: :home, overwrite: true
    run "/usr/bin/update-desktop-database", args:           ["{{staged_path}}/user-applications"],
                                            must_succeed:   false,
                                            writable_paths: [".local/share/applications"], writable_base: :home
  end

  uninstall_postflight_steps do
    symlink ".local/share/applications", "user-applications", source_base: :home, overwrite: true
    run "/usr/bin/update-desktop-database", args:           ["{{staged_path}}/user-applications"],
                                            must_succeed:   false,
                                            writable_paths: [".local/share/applications"], writable_base: :home
  end

  zap trash: [
    "~/.antigravity",
    "~/.antigravity-ide",
    "~/.antigravity-ide-server",
    "~/.config/Antigravity IDE",
    "~/.config/Antigravity",
    "~/.config/antigravity-ide",
    "~/.gemini/antigravity-ide",
  ]

  caveats <<~EOS
    This cask continues to install Antigravity IDE, not the separate Antigravity agent app.
    Both `antigravity` and `antigravity-ide` launch the IDE.
    Upstream renamed its user-data directories. Existing Antigravity data is not
    migrated or removed during installation; back it up before migrating settings.
  EOS
end
