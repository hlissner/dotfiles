desc "Ensure vim/macvim is installed and up to date"
task :vim => "vim:update"

namespace :vim do
  task :install do
    vim_path = File.expand_path("~/.vim")

    if is_mac?
      Package.install "lua"
      %w{vim macvim}.each { |pkg| Package.install "#{pkg} --with-lua --with-luajit" }
    elsif is_linux?
      Package.install "lua5.1"

      unless Dir.exists?(vim_path)
        sh_safe "sudo apt-get install libncurses5-dev libgnome2-dev libgnomeui-dev \
                    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
                    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev ruby1.9-dev mercurial"

        sh_safe "hg clone https://code.google.com/p/vim/ /tmp/vim"
        sh_safe "cd /tmp/vim && ./configure --with-features=huge \
                                            --enable-multibyte \
                                            --enable-rubyinterp \
                                            --enable-pythoninterp \
                                            --enable-perlinterp \
                                            --enable-luainterp \
                                            --enable-clipboard \
                                            --enable-cscope --prefix=/usr \
                           && make VIMRUNTIMEDIR=/usr/share/vim/vim74
                           && sudo make install"
        sh_safe "rm -rf /tmp/vim"
      end
    end
    Package.install "luajit"

    unless Dir.exists?(vim_path)
      github('hlissner/vim', vim_path)
      github('Shougo/neobundle.vim', "#{vim_path}/bundle/neobundle.vim")
    end
  end

  task :update => 'vim:install' do
    path = File.expand_path("~/.vim")

    echo "Updating vim"
    sh_safe "cd #{path} && git pull"

    echo "Updating vim plugins"
    Dir.glob("#{path}/bundle/*") do |f|
      echo ":: Updating #{File.basename(f)}:"
      sh_safe "cd #{f} && git pull"
    end

    if is_linux?
      echo "Can't update compiled vim itself! Use pkg:vim:install"
    end
  end

  task :remove do
    if is_mac?
      echo "Uninstalling vim"
      Package.remove "vim"
      Package.remove "macvim"
    end
  end
end
