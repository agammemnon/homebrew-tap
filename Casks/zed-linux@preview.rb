cask "zed-linux@preview" do
  version "0.216.0"
  sha256 "3970f55f1220361e53eb5a3b737137bafdc066d7f16ab4017fa0f1f2e7322395"

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
    desktop_content.gsub!(/^Icon=.*/, "Icon=zed-preview")
    File.write("#{staged_path}/zed-preview.desktop", desktop_content)
  end

  zap trash: [
    "#{Dir.home}/.cache/zed",
    "#{Dir.home}/.config/zed",
    "#{Dir.home}/.local/share/zed",
  ]
end
