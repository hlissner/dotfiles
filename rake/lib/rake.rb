
def load_all(glob)
    Dir.glob("#{File.dirname(__FILE__)}/../#{glob}") { |file| load file }
end
