cask "zed-linux@preview" do
  version "1.19.0-pre"
  sha256 "3328b58b655222cb00cea5e426d3537361f88d381206ce4d103a3b144b03b906"

  url "https://github.com/zed-industries/zed/releases/download/v#{version}/zed-linux-x86_64.tar.gz"
  name "Zed Preview"
  desc "High-performance, multiplayer code editor (preview build)"
  homepage "https://zed.dev/"

  livecheck do
    url "https://zed.dev/api/releases/preview/latest/zed-linux-x86_64.tar.gz"
    strategy :header_match do |all_headers|
      all_headers.filter_map { |h| h["location"]&.match(%r{/download/v([^/]+-pre)/})&.[](1) }.first
    end
  end

  binary "zed-preview.app/bin/zed", target: "zed-preview"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
  end

  postflight_steps do
    copy "zed-preview.app/share/applications/dev.zed.Zed-Preview.desktop",
         ".local/share/applications/dev.zed.Zed-Preview.desktop", target_base: :home
    inreplace ".local/share/applications/dev.zed.Zed-Preview.desktop", /^TryExec=.*/,
              "TryExec={{HOMEBREW_PREFIX}}/bin/zed-preview", base: :home, audit_result: false
    inreplace ".local/share/applications/dev.zed.Zed-Preview.desktop", /^Exec=zed/,
              "Exec={{HOMEBREW_PREFIX}}/bin/zed-preview", base: :home, audit_result: false
    inreplace ".local/share/applications/dev.zed.Zed-Preview.desktop", /^Icon=.*/, "Icon=zed-preview",
              base: :home, audit_result: false
    copy "zed-preview.app/share/icons/hicolor/512x512/apps/zed.png",
         ".local/share/icons/zed-preview.png", target_base: :home
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/dev.zed.Zed-Preview.desktop", base: :home
    remove ".local/share/icons/zed-preview.png", base: :home
  end

  zap trash: [
    "#{Dir.home}/.cache/zed",
    "#{Dir.home}/.config/zed",
    "#{Dir.home}/.local/share/zed",
  ]
end
