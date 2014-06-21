require_relative 'lib/output'

desc "Provision the node"
task :init,:node do |t,args|
    args.with_defaults(:node => `hostname`.gsub('.local', '').strip)
    # TODO: chop off the *.local in osx hostnames

    path = "#{File.dirname(__FILE__)}/node/#{args.node}.rb"
    if File.exists?(path)
        echo "Setting up node: #{args.node}"
        require_relative "node/#{args.node}"
        echo "Done!"
    else
        echo "#{args.node} node does not exist!"
    end
end

desc "Update the node"
task :default => :init
