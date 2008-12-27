# SimpleScenario helps to define extensible scenarios.
#
# Oleg Andreev <oleganza@gmail.com> 
# November 24, 2008
# License: WTFPL (http://sam.zoy.org/wtfpl/)
#
#
# ==== Define scenario
#
#   SimpleScenarios(:animals) do
#     @rhino = Animal.fixture!(:name => "Rhino")
#   end
# 
#   SimpleScenarios(:paris_zoo => [ :animals, :staff ] ) do
#     @rhino.zoo = Zoo.fixture!(:city => "Paris")
#   end
#
#
# ==== Setup scenario
#
#   SimpleScenarios(:paris_zoo).setup
#   SimpleScenarios.setup(:paris_zoo)
#
#
# ==== Setup mixin scenario
#
#   include SimpleScenarios(:paris_zoo)
#   setup_scenario
#   
#
module SimpleScenarios extend self
  
  def new
    mod = self
    Class.new{ include mod }.new
  end
  
  def add(*args, &blk)
    name, deps = parse_args(args)
    scenarios[name] = {:name => name, :deps => deps, :body => blk}
  end
  
  # inits scenario lazily
  def find(name)
    r = scenarios[name] or raise "SimpleScenario #{name.inspect} not found!"
    (Scenario === r) ? r : (scenarios[name] = Scenario.new(self, r[:name], r[:deps], &r[:body]))
  end
  
  def setup(name, instance = nil)
    find(name).setup(instance)
  end

  def scenarios
    @scenarios ||= Hash.new
  end
  
  def parse_args(args)
    if args.first.is_a?(Hash) # [{:a => [:b, :c]}]  or  [{:a => :b}]
      name         = args.first.keys.first
      dependencies = args.first[name] || [ ]
      dependencies = [ dependencies ] unless dependencies.is_a?(Array)
    else # [:a]
      name = args.first.to_sym
      dependencies = [ ]
    end
    [name, dependencies]
  end
  
  class Scenario < Module
    attr_reader :scenarios, :name, :dependencies
    def initialize(scenarios, name, dependencies, &body_proc)
      @scenarios     = scenarios
      @name          = name
      @dependencies  = dependencies
      @body_proc     = body_proc or raise "No body_proc!"
      
      each_dependency do |scenario|
        include scenario
      end
      
      define_method(:setup_scenario) do 
        super rescue nil
        instance_eval(&body_proc)
      end
      
      define_method(:inspect) do 
        %{#<Scenario Instance:0x#{object_id.to_s(16)} #{name.inspect} => #{dependencies.inspect}>}
      end
    end
    
    def setup(instance = Object.new)
      (class<<instance; self; end).send(:include, self)
      instance.setup_scenario
    end
    
    def each_dependency
      @dependencies.each do |dep|
        yield @scenarios.find(dep)
      end
    end
    
    def inspect
      %{#<Scenario:0x#{object_id.to_s(16)} #{@name.inspect} => #{@dependencies.inspect}>}
    end
    
  end
end

module Kernel
  def SimpleScenarios(*args, &blk)
    ::SimpleScenarios.send(blk ? :add : :find, *args, &blk)
  end
end
