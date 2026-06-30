cask "goland-linux" do
  arch intel: "",
       arm:   "-aarch64"
  os linux: "linux"

  version "2026.1.3,261.25134.147"

  on_macos do
    sha256 :no_check
  end

  on_linux do
    sha256 x86_64_linux: "b11f4110054558cc6a81d54d03cd595c27391abd2b46fb0e91cdc1fc0391b83c",
           arm64_linux:  "fedfb1ed8bf497027d70e361514c9bc4fcb6d114661c6cc159bc08a7ee4df73f"
  end

  url "https://download.jetbrains.com/go/goland-#{version.csv.first}#{arch}.tar.gz"
  name "GoLand"
  desc "Go (golang) IDE"
  homepage "https://www.jetbrains.com/goland/"

  livecheck do
    url "https://data.services.jetbrains.com/products/releases?code=GO&latest=true&type=release"
    strategy :json do |json|
      json["GO"]&.map do |release|
        version = release["version"]
        build = release["build"]
        next if version.blank? || build.blank?

        "#{version},#{build}"
      end
    end
  end

  auto_updates false
  conflicts_with cask: "jetbrains-toolbox-linux"

  binary "#{HOMEBREW_PREFIX}/Caskroom/goland-linux/#{version}/GoLand-#{version.csv.first}/bin/goland"
  artifact "jetbrains-goland.desktop",
           target: "#{Dir.home}/.local/share/applications/jetbrains-goland.desktop"
  artifact "GoLand-#{version.csv.first}/bin/goland.svg",
           target: "#{Dir.home}/.local/share/icons/hicolor/scalable/apps/goland.svg"

  preflight do
    File.write("#{staged_path}/GoLand-#{version.csv.first}/bin/goland64.vmoptions", "-Dide.no.platform.update=true\n", mode: "a+")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons/hicolor/scalable/apps")
    File.write("#{staged_path}/jetbrains-goland.desktop", <<~EOS)
      [Desktop Entry]
      Version=1.0
      Name=GoLand
      Comment=An IDE for Go and Web
      Exec=#{HOMEBREW_PREFIX}/bin/goland %u
      Icon=goland
      Type=Application
      Categories=Development;IDE;
      Keywords=jetbrains;ide;go;golang;
      Terminal=false
      StartupWMClass=jetbrains-goland
      StartupNotify=true
    EOS
  end

  postflight do
    system "/usr/bin/xdg-icon-resource", "forceupdate"
  end

  zap trash: [
    "#{Dir.home}/.cache/JetBrains/GoLand#{version.major_minor}",
    "#{Dir.home}/.config/JetBrains/GoLand#{version.major_minor}",
    "#{Dir.home}/.local/share/JetBrains/GoLand#{version.major_minor}",
  ]
end
