cask "intellij-idea-linux" do
  arch intel: "",
       arm:   "-aarch64"
  os linux: "linux"

  version "2025.3.4,253.32098.37"
  sha256 x86_64_linux: "b86ddae3a3fd6c2afbaca160a3b7d54f4b4fa6d1361ac2616bdb7a6416632ea1",
         arm64_linux:  "77bd86b37da1536d21eba1ecbe62f5d2e23dfaf96201b24e115ab18b98737a92"

  url "https://download.jetbrains.com/idea/ideaIU-#{version.csv.first}#{arch}.tar.gz"
  name "IntelliJ IDEA Ultimate"
  desc "Java IDE by JetBrains"
  homepage "https://www.jetbrains.com/idea/"

  livecheck do
    url "https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&type=release"
    strategy :json do |json|
      json["IIU"]&.map do |release|
        version = release["version"]
        build = release["build"]
        next if version.blank? || build.blank?

        "#{version},#{build}"
      end
    end
  end

  auto_updates false
  conflicts_with cask: "jetbrains-toolbox-linux"

  binary "#{HOMEBREW_PREFIX}/Caskroom/intellij-idea-linux/#{version}/idea-IU-#{version.csv.second}/bin/idea"
  artifact "jetbrains-idea.desktop",
           target: "#{Dir.home}/.local/share/applications/jetbrains-idea.desktop"
  artifact "idea-IU-#{version.csv.second}/bin/idea.svg",
           target: "#{Dir.home}/.local/share/icons/hicolor/scalable/apps/idea.svg"

  preflight do
    File.write("#{staged_path}/idea-IU-#{version.csv.second}/bin/idea64.vmoptions", "-Dide.no.platform.update=true\n", mode: "a+")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons/hicolor/scalable/apps")
    File.write("#{staged_path}/jetbrains-idea.desktop", <<~EOS)
      [Desktop Entry]
      Version=1.0
      Name=Intellij IDEA
      Comment=The IDE for pro Java and Kotlin development
      Exec=#{HOMEBREW_PREFIX}/bin/idea %u
      Icon=idea
      Type=Application
      Categories=Development;IDE;
      Keywords=jetbrains;ide;java;groovy;kotlin;scala;
      Terminal=false
      StartupWMClass=jetbrains-idea
      StartupNotify=true
    EOS
  end

  postflight do
    system "/usr/bin/xdg-icon-resource", "forceupdate"
  end

  zap trash: [
    "#{Dir.home}/.cache/JetBrains/IntelliJIdea#{version.major_minor}",
    "#{Dir.home}/.config/JetBrains/IntelliJIdea#{version.major_minor}",
    "#{Dir.home}/.local/share/JetBrains/IntelliJIdea#{version.major_minor}",
  ]
end
