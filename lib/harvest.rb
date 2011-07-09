class Harvest
  attr_accessor :wilson
  
  def initialize(wilson)
    self.wilson = wilson
    super()
  end
    
  state_machine :timer, :initial => :stopped do
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
      #if transition.to_name == :choosing
      #  EM.add_timer(3) do
      #    transition.rollback
      #    MrsWilson.say_to_master("You didn't choose quick enough, rolling back")
      #  end
      #  
      #end
      #block.call
    end
  end
end