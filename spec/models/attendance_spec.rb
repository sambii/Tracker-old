require 'spec_helper'

describe Attendance do

  #In the future, consider using a separate factory for daily and section attendance because
  #daily attendance does not need a section, and other possible future differences
  before(:each) { @attendance = build :attendance }

  subject { @attendance }

  it "should validate daily records" do
    should be_valid
  end

  test_has_relationships [:school, :student, :excuse, :attendance_type]

  test_responds_to_methods [:attendance_date=, :attendance_date]

  test_has_fields [:school, :section, :student, :excuse, :attendance_type, :attendance_date]
   
  # this tests the required fields that when nil'ed out produce an invalid record
  [:school, :student, :attendance_type].each do |field|
    it "should be invalid when #{field} is not present" do
      @attendance.send("#{field}=", nil)
      @attendance.should_not be_valid
    end
  end

  context "should not be able to set field to nil" do
    [:attendance_date].each do |field|
      before { @attendance.send("#{field}=", nil) }
      it { should_not be_valid }
    end
  end

  it "should not allow mass assignment of school_id" do
    id_before = @attendance.school_id
    @attendance.update_attributes(school_id: 99)
    @attendance.school_id.should == id_before
  end


  describe "- Attendance date tests -" do
    
    context "should not let the user set a bad date string." do
      before { @attendance.attendance_date = '1984-13-13' }
      it { should_not be_valid }
    end

    context "should let the user set the date with a good String date." do
      before { @attendance.attendance_date = '1983-12-13' }
      it { should be_valid }
    end

    context "should let the user set the date with a Date instance." do
      before { @attendance.attendance_date = Date.parse('1983-12-13') }
      it { should be_valid }
    end

    context "should let the user set the date with a DateTime string." do
      before { @attendance.attendance_date = '1983-12-13 05:00' }
      it { should be_valid }
    end

    context "should let the user set the date with a DateTime instance." do
      before do
        @attendance.attendance_date = DateTime.parse('1983-12-13 05:00') 
        @attendance.save
      end
      it { @attendance.reload.attendance_date.should == Date.parse('1983-12-13') }
    end

    pending "Investigate if we need to Test that attendance date is within the school year"
    pending "Address mass updates in the app, especially as related to attendance"

  end

 
  context "- Section Attendance records -" do
    before {  @section_attendance = build :attendance }
    subject { @section_attendance }
    it "should validate section records" do
      should be_valid
    end
  end
 
end