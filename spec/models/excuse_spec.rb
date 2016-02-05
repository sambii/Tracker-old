require 'spec_helper'

describe Excuse do

  before do
    @school = create :school
    @excuse = build :excuse
  end

  subject { @excuse }

  it { should be_valid }

  # check relationships
  [:school].each do |rel|
    describe "should have #{rel} relationship" do
       it { should respond_to("#{rel}") }
    end
  end

  # todo - refactor these into methods from model_helper.rb

  # no need for test_responds_to_methods

  # check fields
  [:code, :description].each do |field|
    describe "field #{field} should have setters and getters" do
      it { should respond_to("#{field}") }
      it { should respond_to("#{field}=") }
    end
  end

  # this tests the required fields that when nil'ed out produce an invalid record
  [:school, :description].each do |field|
    it "should be invalid when #{field} is not present" do
      @excuse.send("#{field}=", nil)
      @excuse.should_not be_valid
    end
  end

  # this tests the required fields cannot be nil'ed out
  [].each do |field|
    it "should not be able to set #{field} to nil" do
      field_val = @excuse.send("#{field}")
      @excuse.send("#{field}=", nil)
      field_val.should == @excuse.send("#{field}")
    end
  end

  context "custom excuse tests" do
    it "should not allow mass assignment of school_id" do
      id_before = @excuse.school_id
      @excuse.update_attributes(school_id: 99)
      @excuse.school_id.should == id_before
    end
  end
  it "should not allow duplicate descriptions per school"

end
