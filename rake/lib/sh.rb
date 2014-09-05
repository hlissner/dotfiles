require_relative 'output'

# A 'safe' sh function that won't stop rake in its tracks
# when it encounters a problem. I'll leave it up to the
# programmer to expect problems and terminate when necessary.
def sh_safe(cmd)
  begin
    return sh(cmd)
  rescue
    error $!
    return false
  end
end

def do_link(src, dest)
  if not (File.exist?(path_to_file) || File.symlink?(path_to_file))
    sh_safe "ln -sf #{src} #{dest}"
  end
end
