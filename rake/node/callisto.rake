desc "Provision home server"
task :callisto do
  %w{
    update
    pkg:zsh
    pkg:vim
    pkg:rbenv
  }.each { |task| Rake::Task[task].invoke }
end
