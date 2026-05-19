cask "zed-linux@preview" do
  version "1.3.4-pre"
  sha256 "b52a5a88d24d58622726fbff8503744660c307105cd4e65d8477f0827d9a0f28"

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

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons")
  end

  postflight do
    # Read and modify the existing desktop file to point to Homebrew binary
    desktop_content = File.read("#{staged_path}/zed-preview.app/share/applications/dev.zed.Zed-Preview.desktop")
    desktop_content.gsub!(/^TryExec=.*/, "TryExec=#{HOMEBREW_PREFIX}/bin/zed-preview")
    desktop_content.gsub!(/^Exec=zed/, "Exec=#{HOMEBREW_PREFIX}/bin/zed-preview")
    desktop_content.gsub!(/^Icon=.*/, "Icon=zed-preview")
    File.write("#{Dir.home}/.local/share/applications/dev.zed.Zed-Preview.desktop", desktop_content)

    FileUtils.cp("#{staged_path}/zed-preview.app/share/icons/hicolor/512x512/apps/zed.png",
                 "#{Dir.home}/.local/share/icons/zed-preview.png")
  end

  uninstall_postflight do
    FileUtils.rm("#{Dir.home}/.local/share/applications/dev.zed.Zed-Preview.desktop")
    FileUtils.rm("#{Dir.home}/.local/share/icons/zed-preview.png")
  end

  zap trash: [
    "#{Dir.home}/.cache/zed",
    "#{Dir.home}/.config/zed",
    "#{Dir.home}/.local/share/zed",
  ]
end
