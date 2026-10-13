cask "godot-linux" do
  arch arm: "arm64", intel: "x86_64"
  os linux: "linux"

  version "4.7.2"
  sha256 arm64_linux:  "5dd0d86405cf7e8adf79fb6377b38ba682a2846cb378ffe5364f38c01ad29b9d",
         x86_64_linux: "cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4"

  url "https://github.com/godotengine/godot/releases/download/#{version}-stable/Godot_v#{version}-stable_linux.#{arch}.zip"
  name "Godot Engine"
  desc "Multi-platform 2D and 3D game engine with a feature-rich editor"
  homepage "https://godotengine.org/"

  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)+)[._-]stable$/i)
    strategy :github_latest
  end

  depends_on :linux

  binary "Godot_v#{version}-stable_linux.#{arch}", target: "godot"
  artifact "org.godotengine.Godot.desktop",
           target: "#{Dir.home}/.local/share/applications/org.godotengine.Godot.desktop"
  # Install straight into ~/.local/share/icons for the same reason as delta-linux:
  # GTK finds names there without reading hicolor's possibly stale icon-theme.cache.
  artifact "godot.svg",
           target: "#{Dir.home}/.local/share/icons/godot.svg"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    # The release zip only contains the editor binary, so write the launcher and icon
    # in staging. Both come from upstream's misc/dist/linux/org.godotengine.Godot.desktop
    # and misc/logo/icon.svg. The MimeType line is left out because registering
    # application/x-godot-project needs upstream's MIME XML and `update-mime-database`.
    write_file "org.godotengine.Godot.desktop", <<~EOS
      [Desktop Entry]
      Name=Godot Engine
      GenericName=Libre game engine
      Comment=Multi-platform 2D and 3D game engine with a feature-rich editor
      Keywords=game development;development;IDE;game engine;
      Exec={{HOMEBREW_PREFIX}}/bin/godot %f
      Icon=godot
      Terminal=false
      Type=Application
      Categories=Development;IDE;
      StartupWMClass=Godot
    EOS
    write_file "godot.svg", <<~EOS
      <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024"><g fill="#fff"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 814 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H446l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c0 34 58 34 58 0v-86c0-34-58-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></svg>
    EOS
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/org.godotengine.Godot.desktop", base: :home
    remove ".local/share/icons/godot.svg", base: :home
  end

  zap trash: [
    "~/.cache/godot",
    "~/.config/godot",
    "~/.local/share/godot",
  ]
end
