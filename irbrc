unless ENV['TERM'] == 'dumb'
  require "pry"
  Pry.start
  exit
end
