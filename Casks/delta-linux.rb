cask "delta-linux" do
  arch arm: "aarch64", intel: "x86_64"
  os linux: "linux"

  version "0.19.0"
  sha256 arm64_linux:  "7b3c76f73336b9b7b1eb5aa9239ed2cf9b68ef91491e0911560c17a53f9a393b",
         x86_64_linux: "e2c329190914b170e6ae8b3ba4091c4ced90a208a36105ef6489c1622ded4670"

  # delta.dev only serves short-lived signed URLs from a private bucket, so this
  # downloads the same binary from Zed's public delta-nix release mirror instead.
  # The mirror is byte-for-byte identical to the delta.dev artifact for each tag.
  url "https://github.com/zed-industries/delta-nix/releases/download/v#{version}/delta-linux-#{arch}.tar.gz"
  name "Delta"
  desc "Multiplayer environment for coding with agents"
  homepage "https://delta.dev/"

  livecheck do
    url "https://delta.dev/api/releases/stable/latest/asset?asset=delta&os=linux&arch=#{arch}"
    strategy :json do |json|
      json["version"]
    end
  end

  depends_on :linux

  binary "Delta/bin/delta"
  artifact "dev.zed.Delta.desktop",
           target: "#{Dir.home}/.local/share/applications/dev.zed.Delta.desktop"
  artifact "dev.zed.Delta.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/dev.zed.Delta.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home

    # Edit in staging rather than in the sandboxed home directory. Upstream launches the
    # app through the CLI, so keep the arguments after the binary (`%U`) intact.
    run "/bin/sed", args:        ["-e", "s|^Exec=[^ ]*|Exec={{HOMEBREW_PREFIX}}/bin/delta|",
                                  "{{staged_path}}/Delta/share/applications/dev.zed.Delta.desktop"],
                    stdout_path: "dev.zed.Delta.desktop"

    copy "Delta/share/icons/hicolor/512x512/apps/dev.zed.Delta.png", "dev.zed.Delta.png"
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/dev.zed.Delta.desktop", base: :home
    remove ".local/share/icons/hicolor/512x512/apps/dev.zed.Delta.png", base: :home
  end

  zap trash: [
    "~/.config/delta",
    "~/.local/share/delta",
  ]
end
