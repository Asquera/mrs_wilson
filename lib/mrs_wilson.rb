require 'rubygems'
require 'blather/client/dsl'
require 'state_machine'
require 'harvested'

module MrsWilson
  extend Blather::DSL
  
  def self.harvest
    #@harvest ||= Harvest.new(self)
    @harvest ||= Harvest.hardy_client(ENV['HARVEST.SUBDOMAIN'], ENV['HARVEST.EMAIL'], ENV['HARVEST.PASSWORD'])
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
  
  setup ENV['WILSON.BOT.ACCOUNT'], ENV['WILSON.BOT.PASSWORD']
  master ENV['WILSON.MASTER.ACCOUNT']
  
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
  
  message :chat?, :body => /#c/ do |m|
    harvest.start_choosing
    say_to_master 'Choosing...'
  end

  message :chat?, :body => /#e.*/ do |m|
    text = /#e(.*)/.match(m.body)[1]
    say m.from, "You said: #{text}"
  end
  
  message :chat?, :body => /#ts.*/ do |m|
    timer = stop_timer
    
    say m.from, "Stopped timer #{timer.notes}"
  end
  
  message :chat?, :body => /#l/ do |m|
    lines = harvest.time.all.each_with_index.map do |l, i|
      "#{i+1} #{l.started_at}-#{l.ended_at} #{l.project} #{l.task} #{l.notes}"
    end
    
    say m.from, lines.join("\n")
  end
  
  message :chat?, :body => /#t (.*)/ do |m|
    text = /#t(.*)/.match(m.body)[1]
    timer = track(text)
    
    say m.from, "Started timer #{timer.id}: #{timer.notes}"
    say m.from, "Last timer was running for: #{timer.hours_for_previously_running_timer}" if timer.hours_for_previously_running_timer
  end
  
  def self.run
    client.run
  end
  
  def self.track(text)
    harvest.time.create(notes: text, project_id: 748602, task_id: 461119)
  end
  
  def self.stop_timer
    harvest.time.all.last.tap do |t|
      harvest.time.toggle(t) if t.timer_started_at
    end
  end
  
  disconnected { client.connect }
end

EM.run {   
  MrsWilson.run 
}
