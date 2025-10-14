cask "ghostty-linux" do
  version "1.2.0+1"
  sha256 "fa125399dd12fe7674e3e39c89aa3a1b2108a03853bb947c31e65aad7d10e8fb"

  url "https://github.com/pkgforge-dev/ghostty-appimage/releases/download/v#{version}/Ghostty-#{version.split('+').first}-x86_64.AppImage"
  name "Ghostty"
  desc "Fast, feature-rich, and native terminal emulator"
  homepage "https://ghostty.org/"

  auto_updates true
  depends_on formula: "squashfs"

  binary "squashfs-root/AppRun", target: "ghostty"
  artifact "squashfs-root/com.mitchellh.ghostty.png",
           target: "#{Dir.home}/.local/share/icons/ghostty.png"
  artifact "squashfs-root/com.mitchellh.ghostty.desktop",
           target: "#{Dir.home}/.local/share/applications/ghostty.desktop"
  artifact "squashfs-root/share/dbus-1/services/com.mitchellh.ghostty.service",
           target: "#{Dir.home}/.local/share/systemd/user/com.mitchellh.ghostty.service"

  preflight do
    # Extract AppImage contents
    appimage_path = "#{staged_path}/Ghostty-#{version.split('+').first}-x86_64.AppImage"
    system "chmod", "+x", appimage_path
    system appimage_path, "--appimage-extract", chdir: staged_path

    # Remove the original AppImage to save space
    FileUtils.rm appimage_path

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    # Fix the desktop file - update both TryExec and Exec to point to Homebrew binary
    desktop_content = File.read("#{staged_path}/squashfs-root/com.mitchellh.ghostty.desktop")
    desktop_content.gsub!(/^TryExec=.*/, "TryExec=#{HOMEBREW_PREFIX}/bin/ghostty")
    desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/ghostty")
    File.write("#{staged_path}/squashfs-root/com.mitchellh.ghostty.desktop", desktop_content)
  end

  zap trash: "~/.config/ghostty"
end