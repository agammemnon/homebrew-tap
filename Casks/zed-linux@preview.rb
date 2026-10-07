cask "zed-linux@preview" do
  os linux: "linux"

  version "1.24.1-pre"
  sha256 "f551231e810ab55dccc9fd17f2e5bcccb9669910b6889416051c40583949727a"

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

  depends_on arch: :x86_64
  depends_on :linux

  binary "zed-preview.app/bin/zed", target: "zed-preview"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
  end

  postflight_steps do
    # Prepare the launcher in staging to avoid in-place edits in the sandboxed home directory.
    run "/bin/sed", args:        ["-e", "s|^TryExec=.*|TryExec={{HOMEBREW_PREFIX}}/bin/zed-preview|",
                                  "-e", "s|^Exec=zed|Exec={{HOMEBREW_PREFIX}}/bin/zed-preview|",
                                  "-e", "s|^Icon=.*|Icon=zed-preview|",
                                  "{{staged_path}}/zed-preview.app/share/applications/dev.zed.Zed-Preview.desktop"],
                    stdout_path: "dev.zed.Zed-Preview.desktop"
    copy "dev.zed.Zed-Preview.desktop", ".local/share/applications/dev.zed.Zed-Preview.desktop", target_base: :home
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
