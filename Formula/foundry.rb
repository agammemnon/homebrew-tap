class Foundry < Formula
  desc "Command-line tool for building and managing IDE-like development environments"
  homepage "https://gitlab.gnome.org/GNOME/foundry"
  url "https://gitlab.gnome.org/GNOME/foundry.git", tag: "1.0.0", revision: "7a846cb896d5a405b68a86f6ae0a469e3f07057f"
  license "LGPL-2.1-or-later"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "gobject-introspection" => :build
  depends_on "cmake" => :build
  depends_on "gettext" => :build
  depends_on "glib"
  depends_on "libdex"
  depends_on "json-glib"
  depends_on "libpeas"
  depends_on "template-glib"
  depends_on "libsoup"
  depends_on "gom"
  depends_on "libadwaita"
  depends_on "libpanel"
  depends_on "sysprof"
  depends_on "libgit2"
  depends_on "editorconfig"
  depends_on "libxml2"
  depends_on "universal-ctags"
  depends_on "cmark"

  def install
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["glib"].opt_lib/"pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["libgit2"].opt_lib/"pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["gettext"].opt_lib/"pkgconfig"

    # Set C_INCLUDE_PATH to ensure headers are found
    include_dirs = [
      Formula["glib"].opt_include/"glib-2.0",
      Formula["glib"].opt_lib/"glib-2.0/include",
      Formula["glib"].opt_include/"gio-unix-2.0",
      Formula["libxml2"].opt_include/"libxml2",
      Formula["libdex"].opt_include/"libdex-1",
      Formula["json-glib"].opt_include/"json-glib-1.0",
      Formula["libpeas"].opt_include/"libpeas-2",
      Formula["template-glib"].opt_include/"template-glib-1.0",
      Formula["libsoup"].opt_include/"libsoup-3.0",
      Formula["gom"].opt_include/"gom-1.0",
      Formula["sysprof"].opt_include/"sysprof-6"
    ]
    
    ENV["C_INCLUDE_PATH"] = include_dirs.join(":")
    ENV["CPLUS_INCLUDE_PATH"] = include_dirs.join(":")
    
    args = %W[
      --wrap-mode=nofallback
      --prefix=#{prefix}
      --libdir=#{lib}
      --buildtype=plain
      -Dgtk=false
      -Dintrospection=disabled
      -Ddocs=false
      -Dfeature-flatpak=false
    ]

    mkdir "build" do
      system "meson", "..", *args
      system "meson", "compile", "--verbose"
      system "meson", "install"
    end
    
    # Remove the compiled schemas file - it will be regenerated in post_install
    (share/"glib-2.0/schemas/gschemas.compiled").unlink if (share/"glib-2.0/schemas/gschemas.compiled").exist?
    
    # Fix lib64 issue if it still occurs
    if (prefix/"lib64").exist? && !(prefix/"lib").exist?
      ln_s "lib64", prefix/"lib"
    end
  end

  test do
    system "#{bin}/foundry", "--help"
  end
end