ENV["LINUX_PPA"] = "ppa:bartbes/love-stable"

desc "Install/update Lua, Love2D & luarocks"
task :love => "love:update"

namespace :love do
  task :install do
    if !system("which luarocks")
      echo "Installing Lua, Love2D and luarocks"
      if is_linux?
        Package.install "lua5.1"

        Package.tap ENV["LINUX_PPA"]
        Package.install "luarocks"
        Package.install "love"
      elsif is_mac?
        Package.install "lua"

        Package.cask_install "love"
        Package.install "luarocks --HEAD"
      end

      sh_safe "luarocks install --server=http://rocks.moonscript.org moonrocks"
      sh_safe "luarocks install busted"
    end
  end

  task :update

  task :remove do
    Package.remove "luarocks"
    if is_linux?
      Package.remove "love"
      Package.untap ENV["LINUX_PPA"]
    elsif is_mac?
      Package.cask_remove "love"
    end
  end
end
