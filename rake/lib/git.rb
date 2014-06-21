include Rake::DSL

def git(url,dest)
    if not Dir.exists?(dest)
        sh "git clone #{url} #{dest}" unless Dir.exists?(dest)
    end
end

def github(repo,dest)
    git "git@github.com:#{repo}.git", dest
end
