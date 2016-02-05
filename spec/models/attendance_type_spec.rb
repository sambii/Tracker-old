require 'spec_helper'

describe AttendanceType do

  before do
    @attendance_type = build :attendance_type
  end

  subject { @attendance_type }

  it { should be_valid }

  # no need for test_has_relationships

  # no need for test_responds_to_methods

  # check if fields exist
  test_has_fields [:description]

  # this tests the required fields that when nil'ed out produce an invalid record
  [:description].each do |field|
    it "should be invalid when #{field} is not present" do
      @attendance_type.send("#{field}=", nil)
      @attendance_type.should_not be_valid
    end
  end

  context "custom attendance types tests" do
    it "should not allow mass assignment of school_id" do
      id_before = @attendance_type.school_id
      @attendance_type.update_attributes(school_id: 99)
      @attendance_type.school_id.should == id_before
    end
  end
  pending "should not allow duplicate descriptions per school"
end
