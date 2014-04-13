include Rake::DSL

def git(url,dest)
    sh "git clone #{url} #{dest}" unless Dir.exists?(dest)
end

def github(repo,dest)
    git "git@github.com:#{repo}.git", dest
end
