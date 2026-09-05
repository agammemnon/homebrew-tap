cask "rubymine-linux" do
  arch arm: "-aarch64"
  os linux: "linux"

  version "2026.2.1,262.9437.192"

  on_macos do
    sha256 :no_check
  end
  on_linux do
    sha256 arm64_linux:  "715beb531d348ac1404be2d8f1316f0191ad95b499753718d0e4783920b106dd",
           x86_64_linux: "71f1f34ea1d23f3f69c1d66bad70246564200f79af00406df3de3b5076b2c0e2"
  end

  url "https://download.jetbrains.com/ruby/RubyMine-#{version.csv.first}#{arch}.tar.gz"
  name "RubyMine"
  desc "Ruby on Rails IDE"
  homepage "https://www.jetbrains.com/rubymine/"

  livecheck do
    url "https://data.services.jetbrains.com/products/releases?code=RM&latest=true&type=release"
    strategy :json do |json|
      json["RM"]&.map do |release|
        version = release["version"]
        build = release["build"]
        next if version.blank? || build.blank?

        "#{version},#{build}"
      end
    end
  end

  auto_updates false
  conflicts_with cask: "jetbrains-toolbox-linux"

  binary "rubymine/bin/rubymine"
  artifact "jetbrains-rubymine.desktop",
           target: "#{Dir.home}/.local/share/applications/jetbrains-rubymine.desktop"
  artifact "rubymine/bin/rubymine.svg",
           target: "#{Dir.home}/.local/share/icons/hicolor/scalable/apps/rubymine.svg"

  preflight_steps do
    # Normalise the versioned directory before referring to it in declarative steps.
    move "RubyMine-*", "rubymine", source_glob: true
    touch "rubymine/bin/rubymine64.vmoptions"
    inreplace "rubymine/bin/rubymine64.vmoptions", /\z/, "-Dide.no.platform.update=true\n"
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/scalable/apps", base: :home
    write_file "jetbrains-rubymine.desktop", <<~EOS
      [Desktop Entry]
      Version=1.0
      Name=RubyMine
      Comment=A Ruby and Rails IDE
      Exec={{HOMEBREW_PREFIX}}/bin/rubymine %u
      Icon=rubymine
      Type=Application
      Categories=Development;IDE;
      Keywords=jetbrains;ide;ruby;rails;
      Terminal=false
      StartupWMClass=jetbrains-rubymine
      StartupNotify=true
    EOS
  end

  postflight_steps do
    run "/usr/bin/xdg-icon-resource", args: ["forceupdate"], must_succeed: false,
                                  writable_paths: [".local/share/icons"], writable_base: :home
  end

  zap trash: [
    "#{Dir.home}/.cache/JetBrains/RubyMine#{version.major_minor}",
    "#{Dir.home}/.config/JetBrains/RubyMine#{version.major_minor}",
    "#{Dir.home}/.local/share/JetBrains/RubyMine#{version.major_minor}",
  ]
end
