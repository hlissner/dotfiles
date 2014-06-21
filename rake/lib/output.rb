def echo(msg)
    # print green text
    puts "\e[32m=> #{msg}\e[0m"
end

def echoerr(msg)
    # print red text
    puts "\e[31m=> #{msg}\e[0m"
end
