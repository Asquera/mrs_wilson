require './test/test_config'

context "a fresh harvest instance" do
  setup do
    Harvest.new
  end
  
  assert("timer is in stopped state") do
    
  end
end