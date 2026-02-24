class Tellm < Formula
  desc "Minimal macOS CLI for Apple Intelligence on-device LLM"
  homepage "https://github.com/neemspees/tellm"
  url "https://github.com/neemspees/tellm/releases/download/0.0.5/tellm-macos-arm64.tar.gz"
  sha256 "23516782929c7faa523ef1d0b1bb7944d00295596ca0fc02cbdff9b3985c44d8"
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
