def echo(msg, level = 1)
  # print green text
  puts "\e[32m#{"="*level}> #{msg}\e[0m"
end

def error(msg)
  # print red text
  puts "\e[31m=> #{msg}\e[0m"
end
