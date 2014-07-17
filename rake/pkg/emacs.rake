desc "Ensure emacs is installed and up to date"
task :emacs => "emacs:update"

namespace :emacs do

  task :install do
    Homebrew.install("emacs", "--with-gnutls --cocoa --keep-ctags --srgb")
    Homebrew.install "aspell"
    github('hlissner/emacs.d', '~/.emacs.d')
  end

  task :update do
    echo "Updating emacs.d"
    sh_safe "cd ~/.emacs.d && git pull"

    echo "You'll have to update emacs manually!"
  end

  task :remove do
    echo "Uninstalling emacs"
    Homebrew.remove "emacs"
    Homebrew.remove "aspell"
    rm_rf "~/.emacs.d" if Dir.exists? "~/.emacs.d"
  end

end
