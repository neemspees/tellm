class Tellm < Formula
  desc "Minimal macOS CLI for Apple Intelligence on-device LLM"
  homepage "https://github.com/neemspees/tellm"
  url "https://github.com/neemspees/tellm/releases/download/0.0.8/tellm-macos-arm64.tar.gz"
  sha256 "0e9589a0a1d275d1e037bde27e44316ffec366cd36cea9e65f87883bc3ed16d4"
  license "MIT"

  depends_on macos: :tahoe
  depends_on arch: :arm64

  def install
    bin.install "tellm"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/tellm 2>&1", 1)
  end
end
