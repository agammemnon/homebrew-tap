cask "cursor-linux" do
  arch arm: "arm64", intel: "x64"
  file_arch = on_arch_conditional arm: "aarch64", intel: "x86_64"
  os linux: "linux"

  version "3.23.12,2d29876d567da1607532b23bbf2cd5ddbca496fe"
  sha256 arm64_linux:  "00f5bad45d084afa7ceefe0eedd4da7c40b846c9551236cfb72e747550c61189",
         x86_64_linux: "7d000e0852bd7d1cc0168afa0f0c0a1a582f044585e08ba8994e6e1631ad26dc"

  url "https://downloads.cursor.com/production/#{version.csv.second}/linux/#{arch}/Cursor-#{version.csv.first}-#{file_arch}.AppImage"
  name "Cursor"
  desc "Write, edit, and chat about your code with AI"
  homepage "https://www.cursor.com/"

  livecheck do
    url "https://api2.cursor.sh/updates/api/update/linux-x64/cursor/0.0.0/stable"
    regex(%r{/production/(\h+)/linux/x64/Cursor[._-]([0-9.]+)[._-]x86_64\.AppImage}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      "#{json["version"]},#{match[1]}"
    end
  end

  depends_on :linux

  binary "Cursor.AppImage", target: "cursor"
  bash_completion "#{staged_path}/squashfs-root/usr/share/cursor/resources/completions/bash/cursor"
  zsh_completion  "#{staged_path}/squashfs-root/usr/share/cursor/resources/completions/zsh/_cursor"
  artifact "cursor.desktop",
           target: "#{Dir.home}/.local/share/applications/cursor.desktop"
  artifact "cursor.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/cursor.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home

    # Normalise the architecture- and version-specific filename before extraction.
    move "Cursor-*.AppImage", "Cursor.AppImage", source_glob: true
    set_permissions "Cursor.AppImage", "+x"
    run "Cursor.AppImage", args: ["--appimage-extract"], base: :staged_path, chdir: "."

    if_path_exists "squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png" do
      copy "squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png", "cursor.png"
    end

    write_file "cursor.desktop", <<~EOS
      [Desktop Entry]
      Name=Cursor
      Comment=AI-first coding environment
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/cursor %F
      Icon=cursor
      Type=Application
      StartupNotify=false
      StartupWMClass=Cursor
      Categories=TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=cursor;code;editor;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec={{HOMEBREW_PREFIX}}/bin/cursor --new-window %F
      Icon=cursor
    EOS

    # Keep a placeholder when the extracted image has no icon.
    unless_path_exists "cursor.png" do
      touch "cursor.png"
    end
  end

  zap trash: [
    "~/.config/Cursor",
    "~/.cursor",
  ]
end
