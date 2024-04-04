# lib/rb/notify.rb

class Notify
  def self.send(message, **) = new.send(message, **)
  def self.error(message, **) = new.error(message, **)

  def initialize(**defaults) = @defaults = defaults

  def send(message,
           title:   @defaults[:title],
           app:     @defaults[:app],
           icon:    @defaults[:icon],
           urgency: @defaults[:urgency] || "normal",
           id:      @defaults[:id],
           tag:     @defaults[:tag])
    sh('notify-send', title, message,
       { u: urgency,
         a: app,
         i: icon,
         r: id.to_s,
         h: tag && "string:x-dunst-stack-tag:#{tag}" },
       verbose: !!ENV['VERBOSE'])
  end

  def error(message, **)
    send(message,
         urgency: 'critical',
         tag: 'hey_error',
         **)
  end
end
