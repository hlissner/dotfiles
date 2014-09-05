include Rake::DSL

def git(url, dest)
  unless Dir.exists?("#{dest}/.git")
    rm_rf dest if Dir.exists?(dest)
    sh "git clone '#{url}' '#{dest}'"
  end
end

def github(repo, dest, protocol = "https")
  git "#{protocol}://github.com/#{repo}.git", dest
end
