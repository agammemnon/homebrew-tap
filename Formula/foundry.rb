class Foundry < Formula
  desc "Command-line tool for building and managing IDE-like development environments"
  homepage "https://gitlab.gnome.org/GNOME/foundry"
  url "https://gitlab.gnome.org/GNOME/foundry.git", tag: "1.0.0", revision: "7a846cb896d5a405b68a86f6ae0a469e3f07057f"
  license "LGPL-2.1-or-later"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "gobject-introspection" => :build

  # Core runtime dependencies with version requirements from meson.build
  depends_on "glib" # >= 2.82
  depends_on "gom" # >= 0.5.0
  depends_on "libdex" # >= 1.1.alpha
  depends_on "json-glib" # >= 1.8
  depends_on "libpeas" # >= 2.0
  depends_on "sysprof" # sysprof-capture-4

  # Optional GTK dependencies
  depends_on "gtk4" => :optional # >= 4.20
  depends_on "gtksourceview5" => :optional # >= 5.18
  depends_on "vte3" => :optional # >= 0.80

  def install
    args = %w[
      --wrap-mode=nofallback
    ]

    # Configure GTK support based on optional dependencies
    if build.with? "gtk4"
      args << "-Dgtk=true"
      args << "-Dintrospection=enabled"
    else
      args << "-Dgtk=false"
      args << "-Dintrospection=disabled"
    end

    # Disable documentation by default (can be enabled separately)
    args << "-Ddocs=false"

    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    # Test basic command execution
    system "#{bin}/foundry", "--version"

    # Test that the main library is properly installed
    assert_predicate lib/"pkgconfig/libfoundry-1.pc", :exist?

    # Test that headers are installed
    assert_predicate include/"libfoundry-1/foundry.h", :exist?

    # If GTK was built, test GTK components too
    if build.with? "gtk4"
      assert_predicate lib/"pkgconfig/libfoundry-gtk-1.pc", :exist?
      assert_predicate include/"libfoundry-gtk-1/foundry-gtk.h", :exist?
    end
  end
end