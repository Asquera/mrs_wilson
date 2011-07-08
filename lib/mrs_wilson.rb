require 'rubygems'
require 'blather/client/dsl'
require "state_machine"

class Harvest
  attr_accessor :wilson
  
  def initialize(wilson)
    self.wilson = wilson
    super()
  end
    
  state_machine :initial => :stopped do
    event :start do
      transition :started => same, :stopped => :started
    end
    
    event :stop do
      transition :stopped => same, :started => :stopped
    end
    
    before_transition :stopped => :start, :do => :log_transition
    
    event :start_choosing do
      transition any => :choosing
    end
    
    around_transition do |obj, transition, block|
      if transition.to_name == :choosing
        EM.add_timer(3) do
          transition.rollback
          MrsWilson.say_to_master("You didn't choose quick enough, rolling back")
        end
        
      end
      block.call
    end
  end
end

module MrsWilson
  extend Blather::DSL
  
  def self.harvest
    @harvest ||= Harvest.new(self)
  end
  
  def self.master(master = nil)
    if master == nil
      @master
    else
      @master = master
    end
  end
  
  def self.say_to_master(stanza)
    say master, stanza
  end
  
  #setup 'bot@florian-gilchers-macbook-pro.local', 'gandalf'
  #master 'test@florian-gilchers-macbook-pro.local'
  
  setup 'mrs.wilson@jabber.ccc.de', 'gandalf'
  master 'skade@jabber.ccc.de'
  
  when_ready { 
    puts "Connected ! send messages to #{jid.stripped}."
    p = Blather::Stanza::Presence::Subscription.new(master, :subscribe)
    write_to_stream p
  }
  
  subscription :request? do |s|
    write_to_stream s.approve!
  end
  
  status do |s|
    
  end
  
  
  message :chat?, :body => 'exit' do |m|
    say_to_master 'Exiting ...'
    shutdown
  end
  
  message :chat?, :body => "Who are you?" do |m|
    say m.from, "What gift do you think a good servant has that separates them from the others? Its the gift of anticipation. And I'm a good servant; I'm better than good, I'm the best; I'm the perfect servant. I know when they'll be hungry, and the food is ready. I know when they'll be tired, and the bed is turned down. I know it before they know it themselves."
  end
  
  message :chat?, :body => /#c/ do |m|
    harvest.start_choosing
    say_to_master 'Choosing...'
  end

  message :chat?, :body => /#e.*/ do |m|
    text = /#e(.*)/.match(m.body)[1]
    say m.from, "You said: #{text}"
  end
  
  message :chat?, :body => /#t (.*)/ do |m|
    text = /#t(.*)/.match(m.body)[1]
    track(text)
    say m.from, "Tracking your time: #{$1}"
  end
  
  def self.run
    client.run
  end
  
  def self.track(text)
    harvest.start!
  end
  
  disconnected { client.connect }
end

EM.run {   
  MrsWilson.run 
}
