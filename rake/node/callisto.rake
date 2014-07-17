
desc "Provision home server"
task :callisto do
    %w{
        osx
        homebrew
        zsh
        vim
        nginx
        mongodb
        gitlab
    }.each { |task| Rake::Task[task].invoke }
end
