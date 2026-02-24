class Tellm < Formula
  desc "Minimal macOS CLI for Apple Intelligence on-device LLM"
  homepage "https://github.com/neemspees/tellm"
  url "https://github.com/neemspees/tellm/releases/latest/download/tellm-macos-arm64.tar.gz"
  sha256 "SHA256"
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
