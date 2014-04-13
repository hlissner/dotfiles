require_relative 'lib/output'
require_relative 'lib/homebrew'
require_relative 'lib/pyenv'

task :pyenv => 'pyenv:update'

namespace :pyenv do

#     task :install do
#         unless Pyenv.is_installed?
#             echo "Installing pyenv"
#             Pyenv.bootstrap
#         end
#     end
#
#     task :v2 => :install do
#         # v = "2.0.0-p451"
#         # unless Pyenv.is_version_installed?(v)
#         #     echo "Building ruby #{v}"
#         #     Pyenv.install v, GLOBAL_GEMS
#         # end
#     end
#
#     task :v3 => :install do
#         # v = "1.9.3-p545"
#         # unless Pyenv.is_version_installed?(v)
#         #     echo "Building ruby #{v}"
#         #     Pyenv.install v, GLOBAL_GEMS
#         # end
#     end
#
#     task :remove do
#         # Pyenv.destroy
#     end

    task :update => :install do
        echoerr "Pyenv rakefile not yet implemented!"
        # Pyenv.installed_versions.each { |v| Pyenv.update v }
    end

end

