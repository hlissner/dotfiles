include Rake::DSL

def git(url,dest)
    sh "git clone #{url} #{dest}" unless File.exists?(dest)
end

def github(repo,dest)
    git "git@github.com:#{repo}.git", dest
end
