require 'formula'

class CmigemoMk < Formula
  homepage 'http://www.kaoriya.net/software/cmigemo'
  head 'https://github.com/koron/cmigemo', :using => :git

  depends_on 'nkf' => :build

  patch :DATA

  def install
    ENV.append 'LDFLAGS', '-headerpad_max_install_names'

    system "./configure", "--prefix=#{prefix}"
    system "make osx-dict"
    cd 'dict' do
      system "make utf-8"
    end
    ENV.deparallelize # Install can fail on multi-core machines unless serialized
    system "make osx-install"
  end
end

__END__
diff --git a/dict/dict.mak b/dict/dict.mak
index 8ea8a66..0b01f8f 100644
--- a/dict/dict.mak
+++ b/dict/dict.mak
@@ -6,7 +6,7 @@
 
 DICT 		= migemo-dict
 DICT_BASE	= base-dict
-SKKDIC_BASEURL 	= http://openlab.ring.gr.jp/skk/dic
+SKKDIC_BASEURL 	= https://raw.githubusercontent.com/skk-dev/dict/master
 SKKDIC_FILE	= SKK-JISYO.L
 EUCJP_DIR	= euc-jp.d
 UTF8_DIR	= utf-8.d
@@ -21,8 +21,7 @@ $(DICT_BASE): $(SKKDIC_FILE) ../tools/skk2migemo.pl ../tools/optimize-dict.pl
 	$(PERL) ../tools/optimize-dict.pl < dict.tmp > $@
 	-$(RM) dict.tmp
 $(SKKDIC_FILE):
-	$(HTTP) $(SKKDIC_BASEURL)/$@.gz
-	$(GUNZIP) $@.gz
+	$(HTTP) $(SKKDIC_BASEURL)/$@
 
 ##############################################################################
 # Dictionary in cp932
