cask "zed-linux" do
  version "0.233.9"
  sha256 "5448862b808f7c94dec0bfdd284a69635fa8dbe1e9a6717f58cca54681a75b40"

  url "https://github.com/zed-industries/zed/releases/download/v#{version}/zed-linux-x86_64.tar.gz"
  name "Zed"
  desc "High-performance, multiplayer code editor"
  homepage "https://zed.dev/"

  livecheck do
    url "https://github.com/zed-industries/zed/releases"
    strategy :github_releases
  end

  binary "zed.app/bin/zed"

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons")
  end

  postflight do
    # Read and modify the existing desktop file to point to Homebrew binary
    desktop_content = File.read("#{staged_path}/zed.app/share/applications/dev.zed.Zed.desktop")
    desktop_content.gsub!(/^TryExec=.*/, "TryExec=#{HOMEBREW_PREFIX}/bin/zed")
    desktop_content.gsub!(/^Exec=zed/, "Exec=#{HOMEBREW_PREFIX}/bin/zed")
    desktop_content.gsub!(/^Icon=.*/, "Icon=zed")
    File.write("#{Dir.home}/.local/share/applications/dev.zed.Zed.desktop", desktop_content)

    FileUtils.cp("#{staged_path}/zed.app/share/icons/hicolor/512x512/apps/zed.png",
                 "#{Dir.home}/.local/share/icons/zed.png")
  end

  uninstall_postflight do
    FileUtils.rm("#{Dir.home}/.local/share/applications/dev.zed.Zed.desktop")
    FileUtils.rm("#{Dir.home}/.local/share/icons/zed.png")
  end

  zap trash: [
    "#{Dir.home}/.cache/zed",
    "#{Dir.home}/.config/zed",
    "#{Dir.home}/.local/share/zed",
  ]
end
