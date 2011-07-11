require 'rubygems'
require 'blather/client/dsl'
require 'state_machine'
require 'harvested'
require 'yaml'

module MrsWilson
  extend Blather::DSL
  
  def self.default_config
    m = Hashie::Mash.new
    m.harvest!.subdomain    = ENV['HARVEST.SUBDOMAIN']
    m.harvest!.email        = ENV['HARVEST.EMAIL']
    m.harvest!.password     = ENV['HARVEST.PASSWORD']
    m.wilson!.bot!.account  = ENV['WILSON.BOT.ACCOUNT']
    m.wilson!.bot!.password = ENV['WILSON.BOT.PASSWORD']
    m.wilson!.bot!.master   = ENV['WILSON.MASTER.ACCOUNT']
    m
  end
  
  def self.config
    @config ||= load_config
  end
  
  def self.load_config
    m = Hashie::Mash.new
    m = m.deep_update(default_config)
    m.deep_update(YAML.load(File.read('config.yml')))
  end
  
  def self.harvest
    cfg = config.harvest
    @harvest ||= Harvest.hardy_client(cfg.harvest.subdomain, cfg.harvest.email, cfg.harvest.password)
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
  
  setup config.wilson.bot.account, config.wilson.bot.password 
  master config.wilson.bot.master
  
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
