# SimpleFixtures is an alternative to dm-sweatshop
#
# Oleg Andreev <oleganza@gmail.com> 
# November 24, 2008
# License: WTFPL (http://sam.zoy.org/wtfpl/)
#
module SimpleFixtures
  # Define a named fixture. Named fixtures other than :default are merged to :default one 
  #
  # A.define_fixture(:a => 1)
  # A.define_fixture {|overrides|  {:a => 1}.merge(overrides)  }
  # A.define_fixture(:some_name, :a => 1)
  # A.define_fixture(:some_name, proc {|overrides|  {:a => 1}  })
  #
  def define_fixture(name = nil, attrs = nil, &blk)
    if !name.is_a?(Symbol) # name and attrs could be nil, but blk != nil
      attrs = name
      name  = :__default__
    end
    fixtures[name] = attrs || blk || {}
  end
  
  # DSSV = double space separated values.
  # Example:  
  #               name      email                  account
  #   oleg        Oleg      oleganza@gmail.com     proc {Account.fixture!(:idbns)}
  #   antares     Michael   mk@------.com          proc {Account.fixture!(:nr)}
  #
  def dssv_fixtures(dssv)
    splitted_lines = dssv.to_a.
      map{|l|     l.strip }.           # strip spaces and CR/LF
      select{|l| !l.empty? }.          # remove blank lines
      map{|l|     l.split(/\s\s+/) }   # split by two+ spaces
    
    fields = splitted_lines.shift.map { |f| f.strip.to_sym }
    
    splitted_lines.each do |arr|
      arr.size != (fields.size + 1) and raise "Malformed DSSV fixture format (check double spaces!)"
      # extract tag as Symbol
      tag = arr.shift.to_sym
      # add field names to values and convert to hash {:name=>"Name", :email=>"email", ...}
      attrs = Hash[*(fields.zip(arr).flatten)]
      # define named fixture
      define_fixture(tag, attrs.inject({}) { |h, (k, v)|
        h[k] = (v =~ %r{^proc\s?\{.*\}$}i ? eval(v) : P.autotype(v))
        h
      })
    end
  end
  
  def fixture!(*args, &blk)
    instance = fixture(*args, &blk)
    instance.save or raise "Could not save #{instance}! Errors: #{instance.errors.to_a.inspect}"
    instance
  end
  
  # A.fixture                    # default fixture
  # A.fixture(:a => 1)           # default fixture with overrides
  # A.fixture(:black)            # :black fixture
  # A.fixture(:black, :a => 1)   # :black fixture with overrides
  #
  def fixture(*args, &blk)
    new(fixture_attributes(*args), &blk)
  end
  
  def fixture_attributes(*args)
    P.fixture_attributes(self, *args)
  end
  
  def fast_clean!
    @unique_fixtures = nil
    super rescue nil
  end
  
  def unique_fixture!(name, overrides = {})
    @unique_fixtures ||= Hash.new # this should be cleared in DM.fast_clean!
    @unique_fixtures[name] ||= fixture!(name, overrides)
  end
  
  def fixtures
    @fixtures ||= Hash.new({})
  end
  
  module P extend self
    def autotype(str) # for DSSV
      case str
      when /^\:([\w\d_]+)$/: $1.to_sym
      when /^\d[\d\_]+$/:    str.to_i
      when /^\d[\d\_\.]+$/:  str.to_f
      else str
      end
    end
    def fixture_attributes(model, *args)
      name = args.shift if args.first.is_a?(Symbol)
      execute_merge(model, model.fixtures[:__default__],  # default fixture attributes
      execute_merge(model, model.fixtures[name],          # named attributes override default fixture
      execute_merge(model, args.shift || {}, args.shift || {}))).   # local attributes override named fixture
      inject({}) do |h, (k,v)|
        h[k] = (v.respond_to?(:call)) ? v.call : v if v
        h
      end
    end
    def execute_merge(model, proc_or_hash, overrides = {})
      case proc_or_hash
      when Proc: proc_or_hash.call(overrides)
      when Hash: proc_or_hash.merge(overrides)
      else
        raise "Attributes must be Proc, DuckType(:call) or Hash (was #{proc_or_hash.inspect})"
      end
    end
  end # P
  
  module RandomFixtures
    def random_sha1
      require 'digest/sha1'
      Digest::SHA1.hexdigest("#{rand(2**160)}")
    end

    # Generates exponentially distributed time values
    def random_fixture_datetime(range = 55, base = 1.5)
      offset = (base**(rand * range))
      offset > 2**30 && offset = 2**30
      Time.now - offset
    end
  end
  include RandomFixtures
end # SimpleFixtures

DataMapper::Model.send(:include, SimpleFixtures) if defined?(DataMapper)
