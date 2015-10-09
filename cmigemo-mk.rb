require 'formula'

class CmigemoMk < Formula
  homepage 'http://www.kaoriya.net/software/cmigemo'
  head 'https://github.com/koron/cmigemo', :using => :git

  depends_on 'nkf' => :build

  def install
    ENV.append 'LDFLAGS', '-headerpad_max_install_names'

    system "./configure", "--prefix=#{prefix}"
    system "make osx-dict"
    cd 'dict' do
      system "make utf-8"
    end
    ENV.j1 # Install can fail on multi-core machines unless serialized
    system "make osx-install"
  end
end
