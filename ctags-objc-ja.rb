require 'formula'

class CtagsObjcJa < Formula
  homepage 'https://github.com/splhack/ctags-objc-ja'
  head 'https://github.com/splhack/ctags-objc-ja.git'

  depends_on "autoconf" => :build

  def install
    ENV.remove_macosxsdk
    ENV.macosxsdk '10.7'
    ENV.append 'LDFLAGS', '-mmacosx-version-min=10.7 -headerpad_max_install_names'

    system "autoconf"
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-macro-patterns",
                          "--enable-japanese-support",
                          "--with-readlib"
    system "make install"
  end
end
