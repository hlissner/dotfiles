require_relative "lib/rake"

verbose(false)

namespace :pkg do load_all("pkg/*.rake") end
