
task :mjolnir => 'mjolnir:update'

namespace :mjolnir do
  task :install do
    Package.install "lua", "luarocks"
    sh "mkdir -p ~/.luarocks"
    sh "echo 'rocks_servers = { \"http://rocks.moonscript.org\" }' > ~/.luarocks/config.lua"
    sh "luarocks install mjolnir.hotkey"
    sh "luarocks install mjolnir.application"
    sh "luarocks install mjolnir._asm.modal_hotkey"
  end
end
