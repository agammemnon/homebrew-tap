cask "delta-linux" do
  arch arm: "aarch64", intel: "x86_64"
  os linux: "linux"

  version "0.28.3"
  sha256 arm64_linux:  "8178a28a92e893cf8646d4342874aa42a38796c69a17520f349c5fafc5e1df0c",
         x86_64_linux: "2b7b46240661f436384cee800efb6814f85198f6937a5c5b99fb8102b9d94dd3"

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
  # Install straight into ~/.local/share/icons instead of a themed size directory.
  # GTK resolves names here through its search-path fallback without reading
  # hicolor's icon-theme.cache, so the launcher icon cannot go blank when that
  # cache is stale (a themed icon added after the cache was built is invisible
  # until something runs `gtk-update-icon-cache`). zed-linux relies on the same
  # behaviour for `Icon=zed`. Upstream's desktop file uses `Icon=dev.zed.Delta`,
  # so the installed filename has to match that name.
  artifact "dev.zed.Delta.png",
           target: "#{Dir.home}/.local/share/icons/dev.zed.Delta.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    # Edit in staging rather than in the sandboxed home directory. Upstream launches the
    # app through the CLI, so keep the arguments after the binary (`%U`) intact.
    run "/bin/sed", args:        ["-e", "s|^Exec=[^ ]*|Exec={{HOMEBREW_PREFIX}}/bin/delta|",
                                  "{{staged_path}}/Delta/share/applications/dev.zed.Delta.desktop"],
                    stdout_path: "dev.zed.Delta.desktop"

    copy "Delta/share/icons/hicolor/512x512/apps/dev.zed.Delta.png", "dev.zed.Delta.png"
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/dev.zed.Delta.desktop", base: :home
    remove ".local/share/icons/dev.zed.Delta.png", base: :home
  end

  zap trash: [
    "~/.config/delta",
    "~/.local/share/delta",
  ]
end
