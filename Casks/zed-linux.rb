cask "zed-linux" do
  os linux: "linux"

  version "1.20.2"
  sha256 "647dc85e09fcd99cd175365a89b7b70ccf96469c4844eb8ae6eb83dfa82f7600"

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
    copy "zed.app/share/applications/dev.zed.Zed.desktop",
         ".local/share/applications/dev.zed.Zed.desktop", target_base: :home
    inreplace ".local/share/applications/dev.zed.Zed.desktop", /^TryExec=.*/,
              "TryExec={{HOMEBREW_PREFIX}}/bin/zed", base: :home, audit_result: false
    inreplace ".local/share/applications/dev.zed.Zed.desktop", /^Exec=zed/,
              "Exec={{HOMEBREW_PREFIX}}/bin/zed", base: :home, audit_result: false
    inreplace ".local/share/applications/dev.zed.Zed.desktop", /^Icon=.*/, "Icon=zed",
              base: :home, audit_result: false
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
