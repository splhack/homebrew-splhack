require 'formula'

class Mobiledevice < Formula
  homepage 'https://github.com/imkira/mobiledevice'
  head 'https://github.com/imkira/mobiledevice.git'

  def install
    system "rake"
    bin.install "mobiledevice"
  end
end
