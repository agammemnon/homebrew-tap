cask "ghostty-linux" do
  version "1.3.1"
  sha256 "fde48d2b716afd1978766879bbf1aae30dd305e8ad86a1037a2614a14d82dc28"

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

  preflight_steps do
    # Avoid version splitting inside the serialised steps.
    move "Ghostty-*-x86_64.AppImage", "Ghostty.AppImage", source_glob: true
    set_permissions "Ghostty.AppImage", "+x"
    run "Ghostty.AppImage", args: ["--appimage-extract"], base: :staged_path, chdir: "."
    remove "Ghostty.AppImage"

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
    mkdir_p ".local/share/systemd/user", base: :home

    # AppRun uses its own directory to find resources, so keep the wrapper.
    write_file "ghostty-wrapper", <<~SH
      #!/bin/sh
      exec "{{staged_path}}/squashfs-root/AppRun" "$@"
    SH
    set_permissions "ghostty-wrapper", "0755"
  end

  postflight_steps do
    copy "squashfs-root/com.mitchellh.ghostty.desktop", ".local/share/applications/ghostty.desktop",
         target_base: :home
    inreplace ".local/share/applications/ghostty.desktop", /^TryExec=.*/,
              "TryExec={{HOMEBREW_PREFIX}}/bin/ghostty", base: :home, audit_result: false
    inreplace ".local/share/applications/ghostty.desktop", /^Exec=.*/,
              "Exec={{HOMEBREW_PREFIX}}/bin/ghostty", base: :home, audit_result: false
    copy "squashfs-root/com.mitchellh.ghostty.png", ".local/share/icons/ghostty.png", target_base: :home
    copy "squashfs-root/share/dbus-1/services/com.mitchellh.ghostty.service",
         ".local/share/systemd/user/com.mitchellh.ghostty.service", target_base: :home
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/ghostty.desktop", base: :home
    remove ".local/share/icons/ghostty.png", base: :home
    remove ".local/share/systemd/user/com.mitchellh.ghostty.service", base: :home
  end

  zap trash: "~/.config/ghostty"
end
