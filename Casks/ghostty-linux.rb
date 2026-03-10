cask "ghostty-linux" do
  version "1.3.0"
  sha256 "f9249820636690dd4747bcd7eb2b082d41a1c1e63a6956a7a130c401e95d22bf"

  url "https://github.com/pkgforge-dev/ghostty-appimage/releases/download/v#{version}/Ghostty-#{version.split("+").first}-x86_64.AppImage"
  name "Ghostty"
  desc "Fast, feature-rich, and native terminal emulator"
  homepage "https://ghostty.org/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on formula: "squashfs"

  binary "ghostty-wrapper", target: "ghostty"

  preflight do
    # Extract AppImage contents
    appimage_path = "#{staged_path}/Ghostty-#{version.split("+").first}-x86_64.AppImage"
    system "chmod", "+x", appimage_path
    system appimage_path, "--appimage-extract", chdir: staged_path

    # Remove the original AppImage to save space
    FileUtils.rm appimage_path

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/systemd/user"

    # Create wrapper script to execute AppRun from the correct directory
    # (upstream switched from binary AppRun to shell script in v1.2.3 which
    # breaks symlinks since it uses $0's directory to find resources)
    wrapper_content = <<~SH
      #!/bin/sh
      exec "#{staged_path}/squashfs-root/AppRun" "$@"
    SH
    File.write("#{staged_path}/ghostty-wrapper", wrapper_content)
    FileUtils.chmod(0755, "#{staged_path}/ghostty-wrapper")
  end

  postflight do
    # Fix the desktop file - update both TryExec and Exec to point to Homebrew binary
    desktop_content = File.read("#{staged_path}/squashfs-root/com.mitchellh.ghostty.desktop")
    desktop_content.gsub!(/^TryExec=.*/, "TryExec=#{HOMEBREW_PREFIX}/bin/ghostty")
    desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/ghostty")
    File.write("#{Dir.home}/.local/share/applications/ghostty.desktop", desktop_content)

    FileUtils.cp("#{staged_path}/squashfs-root/com.mitchellh.ghostty.png",
                 "#{Dir.home}/.local/share/icons/ghostty.png")
    FileUtils.cp("#{staged_path}/squashfs-root/share/dbus-1/services/com.mitchellh.ghostty.service",
                 "#{Dir.home}/.local/share/systemd/user/com.mitchellh.ghostty.service")
  end

  uninstall_postflight do
    FileUtils.rm("#{Dir.home}/.local/share/applications/ghostty.desktop")
    FileUtils.rm("#{Dir.home}/.local/share/icons/ghostty.png")
    FileUtils.rm("#{Dir.home}/.local/share/systemd/user/com.mitchellh.ghostty.service")
  end

  zap trash: "~/.config/ghostty"
end
