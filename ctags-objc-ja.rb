require 'formula'

class CtagsObjcJa < Formula
  homepage 'https://github.com/splhack/ctags-objc-ja'
  head 'https://github.com/splhack/ctags-objc-ja.git'

  depends_on "autoconf" => :build

  def install
    ENV["HOMEBREW_OPTFLAGS"] = "-march=core2" if build.with? 'binary-release'
    ENV.append 'LDFLAGS', '-headerpad_max_install_names'

    system "autoconf"
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-macro-patterns",
                          "--enable-japanese-support",
                          "--with-readlib"
    system "make install"
  end
end
