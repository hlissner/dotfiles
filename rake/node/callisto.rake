
desc "Provision home server"
task :callisto do
    %w{
        zsh
        vim
    }.each { |task| Rake::Task[task].invoke }
end
