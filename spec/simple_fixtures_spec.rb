require File.join(File.dirname(__FILE__), "spec_helper")

describe SimpleFixtures do
  
  before(:each) do
    @model = Class.new do 
      attr_accessor :attrs, :blk
      def initialize(attrs, &blk)
        @attrs = attrs
        @blk   = blk
      end
      def save
        @saved = true
      end
      def saved?
        @saved
      end
    end
    
    @model.extend(SimpleFixtures)
  end

  describe "regular named fixtures" do
    
    before(:each) do
      model = @model
      @model.define_fixture(            :name => "Person", :friend => proc { model.fixture!(:with_block) } )
      @model.define_fixture(:oleg,      :name => "Oleg",   :friend => proc { model.fixture!(:antares)    } )
      @model.define_fixture(:antares,    proc {{:name => "MK"}})
      @model.define_fixture(:with_block) do |overrides| # with block, but without a friend
        overrides.merge(:with_block => :i_am_over_it, :friend => nil)
      end
    end
    
    it "should have named fixtures" do
      @model.fixtures[:__default__].should_not be_empty
      @model.fixtures[:oleg].should_not be_empty
      @model.fixtures[:antares].should respond_to(:call)
      @model.fixtures[:with_block].should respond_to(:call)
    end

    it "should generate a named and default fixtures using Model#fixture and #fixture!" do
      f = @model.fixture(&@some_block)

      f.should_not be_saved
      f.attrs[:friend].should be_saved    

      f.attrs[:name].should == "Person"
      f.attrs[:friend].should be_kind_of(@model)
      f.attrs[:friend].attrs[:name].should == "Person"
      f.attrs[:friend].attrs[:with_block].should == :i_am_over_it
      f.attrs[:friend].attrs[:friend].should == nil
    end
    
  end # regular
  
  describe "with DSSV" do
    before(:each) do
      @model.dssv_fixtures(%{
                     name                   autotype     country
         spb         St. Petersburg         5_000_000    proc { ("Rus" + "sia").to_sym }
         paris       Paris, Île-de-France   :symbol      proc {%{France}}
      })
    end
    
    it "should generate named fixtures" do
      spb = @model.fixture(:spb)
      spb.attrs.should == {:name => "St. Petersburg", :autotype => 5_000_000, :country => :Russia }
      paris = @model.fixture(:paris)
      paris.attrs.should == {:name => "Paris, Île-de-France", :autotype => :symbol, :country => "France" }
    end

    describe "(malformed DSSV)" do
      it {
        lambda{ @model.dssv_fixtures(%{
                       a     b        c
           tag1        a     b        c             
           tag2        a     b    b2  c
        }) }.should raise_error 
      }
    end
    
  end # DSSV
  
end
