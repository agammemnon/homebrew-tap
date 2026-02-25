cask "docker-desktop-linux" do
  version "4.62.0,219486"
  sha256 :no_check

  url "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
  name "Docker Desktop"
  desc "App to build and share containerised applications and microservices"
  homepage "https://www.docker.com/products/docker-desktop/"

  livecheck do
    url "https://desktop.docker.com/linux/main/amd64/appcast.xml"
    strategy :sparkle
  end

  binary "#{staged_path}/dd-extracted/opt/docker-desktop/bin/docker-desktop", target: "docker-desktop"
  artifact "docker-desktop.desktop",
           target: "#{Dir.home}/.local/share/applications/docker-desktop.desktop"
  artifact "docker-desktop.png",
           target: "#{Dir.home}/.local/share/icons/docker-desktop.png"

  preflight do
    # Extract RPM contents
    rpm_file = "#{staged_path}/docker-desktop-x86_64.rpm"
    extract_dir = "#{staged_path}/dd-extracted"
    FileUtils.mkdir_p extract_dir
    system "cd '#{extract_dir}' && rpm2cpio '#{rpm_file}' | cpio -idmv"
    FileUtils.rm rpm_file

    # Set up desktop integration
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    # Copy icon
    icon_source = "#{extract_dir}/opt/docker-desktop/share/icon.original.png"
    FileUtils.cp icon_source, "#{staged_path}/docker-desktop.png" if File.exist?(icon_source)

    # Use bundled desktop file with modified paths
    bundled_desktop = "#{extract_dir}/usr/share/applications/docker-desktop.desktop"
    if File.exist?(bundled_desktop)
      desktop_content = File.read(bundled_desktop)
      desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/docker-desktop")
      desktop_content.gsub!(/^Icon=.*/, "Icon=#{Dir.home}/.local/share/icons/docker-desktop.png")
      File.write("#{staged_path}/docker-desktop.desktop", desktop_content)
    end
  end

  uninstall_postflight do
    FileUtils.rm("#{Dir.home}/.local/share/applications/docker-desktop.desktop")
    FileUtils.rm("#{Dir.home}/.local/share/icons/docker-desktop.png")
  end

  zap trash: [
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

    To manage via systemd (requires creating a service unit):
      systemctl --user start docker-desktop
      systemctl --user enable docker-desktop
  EOS
end
