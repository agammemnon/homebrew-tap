cask "zed-linux@preview" do
  version "0.208.4"
  sha256 "0b64bf7e2e00fbf889fcb8cf9e47098f29bf55b24b756f94cfa49d48e4c3007b"

  url "https://zed.dev/api/releases/preview/#{version}/zed-linux-x86_64.tar.gz"
  name "Zed Preview"
  desc "High-performance, multiplayer code editor (preview build)"
  homepage "https://zed.dev/"

  livecheck do
    url "https://zed.dev/api/releases/latest?asset=zed-linux-x86_64.tar.gz&preview=1&os=linux&arch=x86_64"
    strategy :json do |json|
      json["version"]
    end
  end

  binary "zed-preview.app/bin/zed", target: "zed-preview"
  artifact "zed-preview.desktop",
           target: "#{Dir.home}/.local/share/applications/zed-preview.desktop"
  artifact "zed-preview.app/share/icons/hicolor/512x512/apps/zed.png",
           target: "#{Dir.home}/.local/share/icons/zed-preview.png"

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons")

    # Read and modify the existing desktop file to point to Homebrew binary
    desktop_content = File.read("#{staged_path}/zed-preview.app/share/applications/zed-preview.desktop")
    desktop_content.gsub!(/^TryExec=.*/, "TryExec=#{HOMEBREW_PREFIX}/bin/zed-preview")
    desktop_content.gsub!(/^Exec=zed-preview/, "Exec=#{HOMEBREW_PREFIX}/bin/zed-preview")
    desktop_content.gsub!(/^Icon=.*/, "Icon=#{Dir.home}/.local/share/icons/zed-preview.png")
    File.write("#{staged_path}/zed-preview.desktop", desktop_content)
  end

  zap trash: [
    "#{Dir.home}/.cache/zed",
    "#{Dir.home}/.config/zed",
    "#{Dir.home}/.local/share/zed",
  ]
end
