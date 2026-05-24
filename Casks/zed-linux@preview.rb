cask "zed-linux@preview" do
  version "1.4.1-pre"
  sha256 "153f3c8596de004a8774f491ea5c2bb282ef7d3390cf308444b5650a550cb9b4"

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
