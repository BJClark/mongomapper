require 'test_helper'

class ValidationsTest < Test::Unit::TestCase
  context "Validations" do
    setup do
      @document = Class.new do
        include MongoMapper::Document
      end
    end
    
    context "Validating acceptance of" do
      should "work with validates_acceptance_of macro" do
        @document.key :terms, String
        @document.validates_acceptance_of :terms
        doc = @document.new(:terms => '')
        doc.should have_error_on(:terms)
        doc.terms = '1'
        doc.should_not have_error_on(:terms)
      end
    end

    context "validating confirmation of" do
      should "work with validates_confirmation_of macro" do
        @document.key :password, String
        @document.validates_confirmation_of :password
        doc = @document.new
        doc.password = 'foobar'
        doc.should have_error_on(:password)
        doc.password_confirmation = 'foobar'
        doc.should_not have_error_on(:password)
      end
    end

    context "validating format of" do
      should "work with validates_format_of macro" do
        @document.key :name, String
        @document.validates_format_of :name, :with => /.+/
        doc = @document.new
        doc.should have_error_on(:name)
        doc.name = 'John'
        doc.should_not have_error_on(:name)
      end
      
      should "work with :format shorcut key" do
        @document.key :name, String, :format => /.+/
        doc = @document.new
        doc.should have_error_on(:name)
        doc.name = 'John'
        doc.should_not have_error_on(:name)
      end
    end
    
    context "validating length of" do
      should "work with validates_length_of macro" do
        @document.key :name, String
        @document.validates_length_of :name, :minimum => 5
        doc = @document.new
        doc.should have_error_on(:name)
      end
      
      context "with :length => integer shortcut" do
        should "set maximum of integer provided" do
          @document.key :name, String, :length => 5
          doc = @document.new
          doc.name = '123456'
          doc.should have_error_on(:name)
          doc.name = '12345'
          doc.should_not have_error_on(:name)
        end
      end
      
      context "with :length => range shortcut" do
        setup do
          @document.key :name, String, :length => 5..7
        end
        
        should "set minimum of range min" do
          doc = @document.new
          doc.should have_error_on(:name)
          doc.name = '123456'
          doc.should_not have_error_on(:name)
        end
        
        should "set maximum of range max" do
          doc = @document.new
          doc.should have_error_on(:name)
          doc.name = '12345678'
          doc.should have_error_on(:name)
          doc.name = '123456'
          doc.should_not have_error_on(:name)
        end
      end
      
      context "with :length => hash shortcut" do
        should "pass options through" do
          @document.key :name, String, :length => {:minimum => 2}
          doc = @document.new
          doc.should have_error_on(:name)
          doc.name = '12'
          doc.should_not have_error_on(:name)
        end
      end
    end # validates_length_of
    
    context "Validating numericality of" do
      should "work with validates_numericality_of macro" do
        @document.key :age, Integer
        @document.validates_numericality_of :age
        doc = @document.new
        doc.age = 'String'
        doc.should have_error_on(:age)
        doc.age = 23
        doc.should_not have_error_on(:age)
      end
      
      context "with :numeric shortcut" do
        should "work with integer or float" do
          @document.key :weight, Float, :numeric => true
          doc = @document.new
          doc.weight = 'String'
          doc.should have_error_on(:weight)
          doc.weight = 23.0
          doc.should_not have_error_on(:weight)
          doc.weight = 23
          doc.should_not have_error_on(:weight)
        end
      end
      
      context "with :numeric shortcut on Integer key" do
        should "only work with integers" do
          @document.key :age, Integer, :numeric => true
          doc = @document.new
          doc.age = 'String'
          doc.should have_error_on(:age)
          doc.age = 23.1
          doc.should have_error_on(:age)
          doc.age = 23
          doc.should_not have_error_on(:age)
        end
      end
    end # numericality of
    
    context "validating presence of" do
      should "work with validates_presence_of macro" do
        @document.key :name, String
        @document.validates_presence_of :name
        doc = @document.new
        doc.should have_error_on(:name)
      end
      
      should "work with :required shortcut on key definition" do
        @document.key :name, String, :required => true
        doc = @document.new
        doc.should have_error_on(:name)
      end
    end    
  end # Validations
  
  context "Saving a new document that is invalid" do
    setup do
      @document = Class.new do
        include MongoMapper::Document
        key :name, String, :required => true
      end
      
      @document.collection.clear
    end

    should "not insert document" do
      doc = @document.new
      doc.save
      @document.count.should == 0
    end
    
    should "populate document's errors" do
      doc = @document.new
      doc.errors.size.should == 0
      doc.save
      doc.errors.full_messages.should == ["Name can't be empty"]
    end
  end
  
  context "Saving a document that is invalid (destructive)" do
    setup do
      @document = Class.new do
        include MongoMapper::Document
        key :name, String, :required => true
      end
      
      @document.collection.clear
    end

    should "raise error" do
      doc = @document.new
      lambda { doc.save! }.should raise_error(MongoMapper::DocumentNotValid)
    end
  end
  
  context "Saving an existing document that is invalid" do
    setup do
      @document = Class.new do
        include MongoMapper::Document
        key :name, String, :required => true
      end
      
      @document.collection.clear
      @doc = @document.create(:name => 'John Nunemaker')
    end

    should "not update document" do
      @doc.name = nil
      @doc.save
      @document.find(@doc.id).name.should == 'John Nunemaker'
    end
    
    should "populate document's errors" do
      @doc.name = nil
      @doc.save
      @doc.errors.full_messages.should == ["Name can't be empty"]
    end
  end
end