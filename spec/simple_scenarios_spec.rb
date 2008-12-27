require File.join(File.dirname(__FILE__), "spec_helper")

describe SimpleScenarios do
  
  before(:each) do
    
    entities = @entities = {} # this is for non-mixin test
    
    SimpleScenarios(:animals) do
      @rhino = {:type => :animal, :name => "Rhino"}
      entities[:rhino] = @rhino
    end
    
    SimpleScenarios(:staff => :animals) do # this tests non-array dependency
      @oleg = {:type => :person, :name => "Oleg"}
      entities[:oleg] = @oleg
    end
  
    SimpleScenarios(:paris_zoo => [ :animals, :staff ] ) do
      @zoo = {:type => :zoo, :city => "Paris", :manager => @oleg}
      @rhino[:zoo] = @zoo
      entities[:zoo] = @zoo
    end
  end

  def assert_zoo_instance(instance)
    assert_zoo_entities(
      instance.instance_variable_get(:@rhino), 
      instance.instance_variable_get(:@oleg),
      instance.instance_variable_get(:@zoo)
    )
  end
  
  def assert_zoo_entities(rhino, oleg, zoo)
    rhino.should_not be_nil
    oleg.should_not be_nil
    zoo.should_not be_nil
    
    rhino[:name].should == "Rhino"
    rhino[:zoo].should  == zoo
    zoo[:manager].should == oleg
  end
  
  describe "as a mixin" do
    before(:each) do
      @scenario = SimpleScenarios(:paris_zoo)
      @scenario.should be_kind_of(Module)
      scenario = @scenario
      @class = Class.new do
        include scenario
      end
      @instance = @class.new
      @instance.setup_scenario
    end
    
    it "should create entities" do
      assert_zoo_instance(@instance)
    end
  end
  
  describe "SimpleScenarios(scenario_name).setup(instance)" do
    before(:each) do
      @instance = Object.new
      SimpleScenarios(:paris_zoo).setup(@instance)
    end
    it "should create entities" do
      assert_zoo_instance(@instance)
    end
  end
  
  describe "SimpleScenarios.setup(scenario_name, instance)" do
    before(:each) do
      @instance = Object.new
      SimpleScenarios.setup(:paris_zoo, @instance)
    end
    it "should create entities" do
      assert_zoo_instance(@instance)
    end
  end

  describe "SimpleScenarios(scenario_name).setup" do
    before(:each) do
      SimpleScenarios(:paris_zoo).setup
    end
    it "should create entities" do
      assert_zoo_entities(@entities[:rhino], @entities[:oleg], @entities[:zoo])
    end
  end

  describe "SimpleScenarios.setup(scenario_name)" do
    before(:each) do
      SimpleScenarios.setup(:paris_zoo)
    end
    it "should create entities" do
      assert_zoo_entities(@entities[:rhino], @entities[:oleg], @entities[:zoo])
    end
  end
  
end
