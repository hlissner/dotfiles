desc "Ensure emacs is installed and up to date"
task :emacs => "emacs:update"

namespace :emacs do

    task :install do
        unless Dir.exists?(File.expand_path("~/.emacs.d"))
            github('hlissner/emacs.d', '~/.emacs.d')
            Homebrew.install("emacs", "--with-gnutls --cocoa --keep-ctags --srgb")
            Homebrew.install("homebrew/dupes/tidy", "--HEAD")
            Homebrew.install "aspell"

            sh_safe "/usr/local/bin/npm install jshint -g"
            sh_safe "/usr/local/bin/npm install jsonlint -g"
        end
    end

    task :update do
        echo "Updating emacs.d"
        sh_safe "cd ~/.emacs.d && git pull"

        echo "You'll have to update emacs packages manually!"
    end

    task :remove do
        echo "Uninstalling emacs"
        Homebrew.remove "emacs"
        Homebrew.remove "aspell"
        rm_rf "~/.emacs.d" if Dir.exists?(File.expand_path("~/.emacs.d"))
    end

end
