require 'formula'

class MacvimKaoriya < Formula
  homepage 'http://code.google.com/p/macvim-kaoriya/'
  head 'https://github.com/splhack/macvim.git'

  depends_on 'cmigemo-mk' => :build
  depends_on 'gettext' => :build
  depends_on 'lua' => :build
  depends_on 'lua51' => :build
  depends_on 'luajit' => :build
  depends_on 'python3' => :build
  depends_on 'ruby' => :build
  depends_on 'universal-ctags' => :build

  option 'with-binary-release', ''

  def get_path(name)
    f = Formulary.factory(name)
    if f.rack.directory?
      kegs = f.rack.subdirs.map { |keg| Keg.new(keg) }.sort_by(&:version)
      return kegs.last.to_s unless kegs.empty?
    end
    nil
  end

  def install
    error = nil
    depend_formulas = %w(gettext lua lua51 luajit python3 ruby)
    depend_formulas.each do |formula|
      var = "@" + formula.gsub("-", "_")
      instance_variable_set(var, get_path(formula))
      if instance_variable_get(var).nil?
        error ||= "brew install " + depend_formulas.join(" ") + "\n"
        error += "can't find #{formula}\n"
      end
    end
    raise error unless error.nil?

    if build.with? 'binary-release'
      ENV.append 'MACOSX_DEPLOYMENT_TARGET', '10.9'
      ENV.append 'CFLAGS', '-mmacosx-version-min=10.9'
      ENV.append 'LDFLAGS', '-mmacosx-version-min=10.9 -headerpad_max_install_names'
    end
    perl_version = '5.16'
    ENV.append 'VERSIONER_PERL_VERSION', perl_version
    ENV.append 'VERSIONER_PYTHON_VERSION', '2.7'
    ENV.append 'vi_cv_path_python3', "#{HOMEBREW_PREFIX}/bin/python3"
    ENV.append 'vi_cv_path_plain_lua', "#{HOMEBREW_PREFIX}/bin/lua-5.1"
    ENV.append 'vi_cv_dll_name_perl', "/System/Library/Perl/#{perl_version}/darwin-thread-multi-2level/CORE/libperl.dylib"
    ENV.append 'vi_cv_dll_name_python3', "#{HOMEBREW_PREFIX}/Frameworks/Python.framework/Versions/3.5/Python"

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
                          "--with-ruby19-command=#{@ruby}/bin/ruby",
                          '--enable-luainterp=dynamic',
                          "--with-lua-prefix=#{@lua51}",
                          '--enable-lua52interp=dynamic',
                          "--with-lua52-prefix=#{@lua}"

    system "PATH=$PATH:#{@gettext}/bin make -C src/po MSGFMT=#{@gettext}/bin/msgfmt"
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

    vimprocdir = vimdir + 'plugins/vimproc'
    rm_rf vimprocdir
    mkdir vimprocdir
    system "git clone --depth=1 https://github.com/Shougo/vimproc.vim.git"
    system "make -C vimproc.vim"
    system "tar -C vimproc.vim -cf - autoload doc lib plugin|(cd #{vimdir/'plugins/vimproc'}; tar xf -)"

    dict = runtime + 'dict'
    mkdir_p dict
    Dir.glob("#{HOMEBREW_PREFIX}/share/migemo/utf-8/*").each do |f|
      cp f, dict
    end

    resource("CMapResources").stage do
      cp 'UniJIS-UTF8-H', runtime/'print/UniJIS-UTF8-H.ps'
    end

    [
      "#{HOMEBREW_PREFIX}/opt/gettext/lib/libintl.8.dylib",
      "#{HOMEBREW_PREFIX}/opt/cmigemo-mk/lib/libmigemo.1.dylib",
    ].each do |lib|
      newname = "@executable_path/../Frameworks/#{File.basename(lib)}"
      system "install_name_tool -change #{lib} #{newname} #{macos + 'Vim'}"
      cp lib, frameworks
    end

    cp "#{@luajit}/lib/libluajit-5.1.2.dylib", frameworks
    File.open(vimdir + 'vimrc', 'a').write <<EOL
" Lua interface with embedded luajit
exec "set luadll=".simplify(expand("$VIM/../../Frameworks/libluajit-5.1.2.dylib"))
EOL

    if build.with? 'binary-release'
      vim = "#{macos + 'Vim'} -u NONE -U NONE"
      system "#{vim} -c lua 'print(\"MacVim\")' -c q|grep -q -w MacVim"
      system "#{vim} -c perl 'VIM::Msg(\"MacVim\")' -c q|grep -q -w MacVim"
      system "#{vim} -c py 'print(\"MacVim\")' -c q|grep -q -w MacVim"
      system "#{vim} -c py3 'print(\"MacVim\")' -c q|grep -q -w MacVim"
      system "#{vim} -c ruby 'puts(\"MacVim\")' -c q|grep -q -w MacVim"
    end
  end

  resource("CMapResources") do
    url 'https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/cmapresources_japan1-6/CMap/UniJIS-UTF8-H'
    sha1 'd6d945e2bee577f4f17d3ae93a11b585eff3346a'
  end
end
