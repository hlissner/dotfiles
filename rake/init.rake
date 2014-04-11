require_relative 'lib/output'

desc "Provision the node"
task :init,:node do |t,args|
    args.with_defaults(:node => `hostname`.strip)
    # TODO: chop of the *.local in osx hostnames

    path = "#{File.dirname(__FILE__)}/node/#{args.node}.rb"
    if File.exists?(path)
        echo "Setting up node: #{args.node}"
        require_relative "node/#{args.node}"
    else
        echo "#{args.node} node does not exist!"
    end
end
