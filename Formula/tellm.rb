class Tellm < Formula
  desc "Minimal macOS CLI for Apple Intelligence on-device LLM"
  homepage "https://github.com/neemspees/tellm"
  url "https://github.com/neemspees/tellm/releases/download/0.0.6/tellm-macos-arm64.tar.gz"
  sha256 "cc1ebddf9bb5255ddd2d4a77a9d2308f0ce3937f0f39980ad04bc4f05058db33"
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
