require 'formula'

class MacvimKaoriya < Formula
  homepage 'http://code.google.com/p/macvim-kaoriya/'
  head 'https://github.com/splhack/macvim.git'

  depends_on 'cmigemo-mk' => :build
  depends_on 'ctags-objc-ja' => :build
  depends_on 'gettext-mk' => :build

  option 'with-binary-release', ''

  GETTEXT = "#{HOMEBREW_PREFIX}/Cellar/gettext-mk/0.18.1.1"

  def install
    ENV["HOMEBREW_OPTFLAGS"] = "-march=core2" if build.with? 'binary-release'
    ENV.append 'MACOSX_DEPLOYMENT_TARGET', '10.8'
    ENV.append 'CFLAGS', '-mmacosx-version-min=10.8'
    ENV.append 'LDFLAGS', '-mmacosx-version-min=10.8 -headerpad_max_install_names'
    ENV.append 'VERSIONER_PERL_VERSION', '5.16'
    ENV.append 'VERSIONER_PYTHON_VERSION', '2.7'
    ENV.append 'vi_cv_path_python3', '/usr/local/bin/python3'

    error = nil
    [
      "#{HOMEBREW_PREFIX}/Cellar/python3/3.4.2_1/bin/python3",
      "#{HOMEBREW_PREFIX}/Cellar/ruby/2.2.0/bin/ruby",
      "#{HOMEBREW_PREFIX}/Cellar/lua/5.2.3_1/bin/lua",
      "#{HOMEBREW_PREFIX}/Cellar/lua51/5.1.5/bin/lua5.1",
      "#{HOMEBREW_PREFIX}/Cellar/luajit/2.0.3_1/bin/luajit",
    ].each do |file|
      unless File.exist?(file)
        error ||= "brew install python3 ruby lua lua51 luajit\n"
        error += "can't find #{file}\n"
      end
    end
    raise error unless error.nil?

    system './configure', "--prefix=#{prefix}",
                          '--with-features=huge',
                          '--enable-multibyte',
                          '--enable-netbeans',
                          '--with-tlib=ncurses',
                          '--enable-cscope',
                          '--enable-perlinterp=dynamic',
                          '--enable-pythoninterp=dynamic',
                          '--enable-python3interp=dynamic',
                          '--enable-rubyinterp=dynamic',
                          '--with-ruby-command=/usr/bin/ruby',
                          '--enable-ruby19interp=dynamic',
                          "--with-ruby19-command=#{HOMEBREW_PREFIX}/Cellar/ruby/2.2.0/bin/ruby",
                          '--enable-luainterp=dynamic',
                          "--with-lua-prefix=#{HOMEBREW_PREFIX}/Cellar/lua51/5.1.5",
                          '--enable-lua52interp=dynamic',
                          "--with-lua52-prefix=#{HOMEBREW_PREFIX}/Cellar/lua/5.2.3_1"

    gettext = "#{GETTEXT}/bin/"
    inreplace 'src/po/Makefile' do |s|
      s.gsub! /^(XGETTEXT\s*=.*)(xgettext.*)/, "\\1#{gettext}\\2"
      s.gsub! /^(MSGMERGE\s*=.*)(msgmerge.*)/, "\\1#{gettext}\\2"
    end

    Dir.chdir('src/po') {system 'make'}
    system 'make'

    prefix.install 'src/MacVim/build/Release/MacVim.app'

    app = prefix + 'MacVim.app/Contents'
    frameworks = app + 'Frameworks'
    macos = app + 'MacOS'
    vimdir = app + 'Resources/vim'
    runtime = vimdir + 'runtime'
    docja = vimdir + 'plugins/vimdoc-ja/doc'

    system "#{macos + 'Vim'} -c 'helptags #{docja}' -c q"

    macos.install 'src/MacVim/mvim'
    mvim = macos + 'mvim'
    ['vimdiff', 'view', 'mvimdiff', 'mview'].each do |t|
      ln_s 'mvim', macos + t
    end
    inreplace mvim do |s|
      s.gsub! /^# (VIM_APP_DIR=).*/, "\\1`dirname \"$0\"`/../../.."
      s.gsub! /^(binary=).*/, "\\1\"`(cd \"$VIM_APP_DIR/MacVim.app/Contents/MacOS\"; pwd -P)`/Vim\""
    end

    cp "#{HOMEBREW_PREFIX}/bin/ctags", macos

    dict = runtime + 'dict'
    mkdir_p dict
    Dir.glob("#{HOMEBREW_PREFIX}/share/migemo/utf-8/*").each do |f|
      cp f, dict
    end

    resource("CMapResources").stage do
      cp 'CMap/UniJIS-UTF8-H', runtime/'print/UniJIS-UTF8-H.ps'
    end

    [
      "#{HOMEBREW_PREFIX}/opt/gettext-mk/lib/libintl.8.dylib",
      "#{HOMEBREW_PREFIX}/lib/libmigemo.1.dylib",
    ].each do |lib|
      newname = "@executable_path/../Frameworks/#{File.basename(lib)}"
      system "install_name_tool -change #{lib} #{newname} #{macos + 'Vim'}"
      cp lib, frameworks
    end

    cp "#{HOMEBREW_PREFIX}/lib/libluajit-5.1.2.dylib", frameworks
    File.open(vimdir + 'vimrc', 'a').write <<EOL
let $LUA_DLL = simplify($VIM . '/../../Frameworks/libluajit-5.1.2.dylib')
EOL
  end

  resource("CMapResources") do
    url 'http://jaist.dl.sourceforge.net/project/cmap.adobe/cmapresources_japan1-6.tar.z'
    sha1 '9467d7ed73c16856d2a49b5897fc5ea477f3a111'
  end
end
