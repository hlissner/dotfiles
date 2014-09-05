require_relative 'lib/output'

task :default => :update

desc "Update the node (based on hostname)"
task :update, :node do |t, args|
  args.with_defaults(:node => `hostname`.gsub('.local', '').strip)
  Rake::Task["setup:#{args.node}"].invoke
end

# desc "Wipe the slate clean"
task :destroy do
  # are you sure?
  # are you really really sure?
  # TODO: EXTERMINATE!
end

namespace :setup do
  load_all("node/*.rake")
end
