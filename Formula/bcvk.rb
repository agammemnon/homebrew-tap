class Bcvk < Formula
  desc "CLI tool for launching ephemeral VMs from bootc container images"
  homepage "https://github.com/bootc-dev/bcvk"
  url "https://github.com/bootc-dev/bcvk.git", tag: "v0.14.0", revision: "a422cde52bf28d1e4280ed6b72889d3fa41800da"
  license any_of: ["Apache-2.0", "MIT"]

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "openssl" => :build
  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on :linux

  def install
    system "cargo", "install", "--locked", "--path", "crates/kit", "--root", prefix
  end

  def caveats
    <<~EOS
      bcvk requires the following runtime dependencies:
        podman, qemu-kvm, qemu-img, virtiofsd, openssh-clients, binutils

      For libvirt integration, also install:
        libvirt-client
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bcvk --version")
  end
end
