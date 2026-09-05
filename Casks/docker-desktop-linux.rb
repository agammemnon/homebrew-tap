cask "docker-desktop-linux" do
  version "4.88.1"
  sha256 :no_check

  url "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
  name "Docker Desktop"
  desc "App to build and share containerised applications and microservices"
  homepage "https://www.docker.com/products/docker-desktop/"

  livecheck do
    url "https://desktop.docker.com/linux/main/amd64/appcast.xml"
    strategy :sparkle, &:short_version
  end

  binary "#{staged_path}/dd-extracted/opt/docker-desktop/bin/docker-desktop", target: "docker-desktop"
  artifact "docker-desktop.desktop",
           target: "#{Dir.home}/.local/share/applications/docker-desktop.desktop"
  artifact "docker-desktop.png",
           target: "#{Dir.home}/.local/share/icons/docker-desktop.png"

  preflight_steps do
    # Keep extraction declarative and stop if either command fails.
    mkdir_p "dd-extracted"
    run "rpm2cpio", args:        ["{{staged_path}}/docker-desktop-x86_64.rpm"],
                    stdout_path: "docker-desktop.cpio"
    run "cpio", args: ["-idmv"],
                stdin_path: "docker-desktop.cpio", chdir: "dd-extracted"
    remove ["docker-desktop-x86_64.rpm", "docker-desktop.cpio"]

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    if_path_exists "dd-extracted/opt/docker-desktop/share/icon.original.png" do
      copy "dd-extracted/opt/docker-desktop/share/icon.original.png", "docker-desktop.png"
    end

    if_path_exists "dd-extracted/usr/share/applications/docker-desktop.desktop" do
      copy "dd-extracted/usr/share/applications/docker-desktop.desktop", "docker-desktop.desktop"
      inreplace "docker-desktop.desktop", /^Exec=.*/, "Exec={{HOMEBREW_PREFIX}}/bin/docker-desktop",
                audit_result: false
      inreplace "docker-desktop.desktop", /^Icon=.*/, "Icon=docker-desktop", audit_result: false
    end

    mkdir_p ".config/systemd/user", base: :home
    if_path_exists "dd-extracted/usr/lib/systemd/user/docker-desktop.service" do
      copy "dd-extracted/usr/lib/systemd/user/docker-desktop.service",
           ".config/systemd/user/docker-desktop.service", target_base: :home
      inreplace ".config/systemd/user/docker-desktop.service", /^ExecStart=.*/,
                "ExecStart={{staged_path}}/dd-extracted/opt/docker-desktop/bin/com.docker.backend",
                base: :home, audit_result: false
    end

    mkdir_p ".docker/cli-plugins", base: :home
    symlink "dd-extracted/usr/lib/docker/cli-plugins/*", ".docker/cli-plugins",
            target_base: :home, source_glob: true, overwrite: true

    if_path_exists "dd-extracted/usr/bin/docker-credential-desktop" do
      symlink "dd-extracted/usr/bin/docker-credential-desktop", "bin/docker-credential-desktop",
              target_base: :homebrew_prefix, overwrite: true
    end
  end

  uninstall_preflight_steps do
    # Stopping an inactive service or disabling a missing unit is harmless.
    run "systemctl", args: ["--user", "stop", "docker-desktop"], must_succeed: false
    run "systemctl", args: ["--user", "disable", "docker-desktop"], must_succeed: false
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/docker-desktop.desktop", base: :home
    remove ".local/share/icons/docker-desktop.png", base: :home
    remove ".config/systemd/user/docker-desktop.service", base: :home
    remove "bin/docker-credential-desktop", base: :homebrew_prefix
    remove ".docker/cli-plugins/*", base: :home, symlink_target_contains: "dd-extracted"
    run "systemctl", args: ["--user", "daemon-reload"], must_succeed: false
  end

  zap trash: [
    "~/.config/systemd/user/docker-desktop.service",
    "~/.docker",
    "~/.local/share/applications/docker-desktop.desktop",
    "~/.local/share/icons/docker-desktop.png",
  ]

  caveats <<~EOS
    Docker Desktop requires additional post-install setup that the RPM
    post-install script normally handles:

      # Set capabilities for privileged port mapping
      sudo setcap cap_net_bind_service=+ep #{staged_path}/dd-extracted/opt/docker-desktop/bin/com.docker.backend

      # Add Kubernetes DNS entry
      echo '127.0.0.1 kubernetes.docker.internal' | sudo tee -a /etc/hosts

    To start Docker Desktop:
      docker-desktop

    To manage via systemd:
      systemctl --user start docker-desktop
      systemctl --user enable docker-desktop
  EOS
end
