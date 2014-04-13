require 'colorize'

def echo(msg)
    puts "=> #{msg}".bold.green
end

def echoerr(msg)
    puts "=> #{msg}".bold.red
end
