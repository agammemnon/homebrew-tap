cask "zed-linux" do
  os linux: "linux"

  version "1.23.2"
  sha256 "cabddd5af2b26a19633ea39f5dde070e2aad204bb815bfa74cb65073ffd5ff39"

  url "https://github.com/zed-industries/zed/releases/download/v#{version}/zed-linux-x86_64.tar.gz"
  name "Zed"
  desc "High-performance, multiplayer code editor"
  homepage "https://zed.dev/"

  livecheck do
    url "https://github.com/zed-industries/zed/releases"
    strategy :github_releases
  end

  depends_on arch: :x86_64
  depends_on :linux

  binary "zed.app/bin/zed"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
  end

  postflight_steps do
    # Prepare the launcher in staging to avoid in-place edits in the sandboxed home directory.
    run "/bin/sed", args:        ["-e", "s|^TryExec=.*|TryExec={{HOMEBREW_PREFIX}}/bin/zed|",
                                  "-e", "s|^Exec=zed|Exec={{HOMEBREW_PREFIX}}/bin/zed|",
                                  "-e", "s|^Icon=.*|Icon=zed|",
                                  "{{staged_path}}/zed.app/share/applications/dev.zed.Zed.desktop"],
                    stdout_path: "dev.zed.Zed.desktop"
    copy "dev.zed.Zed.desktop", ".local/share/applications/dev.zed.Zed.desktop", target_base: :home
    copy "zed.app/share/icons/hicolor/512x512/apps/zed.png", ".local/share/icons/zed.png", target_base: :home
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/dev.zed.Zed.desktop", base: :home
    remove ".local/share/icons/zed.png", base: :home
  end

  zap trash: [
    "#{Dir.home}/.cache/zed",
    "#{Dir.home}/.config/zed",
    "#{Dir.home}/.local/share/zed",
  ]
end
