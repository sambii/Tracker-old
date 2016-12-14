# attendance_entry_spec.rb
require 'spec_helper'


describe "Teacher Tracker", js:true do
  before (:each) do
    create_and_load_arabic_model_school

    @school1 = FactoryGirl.create :school_current_year, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    @discipline = @subject1.discipline
    load_test_section(@section1_1, @teacher1)

    @student_fname1 = FactoryGirl.create :student, school: @school1, first_name: 'First', last_name: 'Shows First'
    @enrollment1_1_f = FactoryGirl.create :enrollment, section: @section1_1, student: @student_fname1

    @teacher2 = FactoryGirl.create :teacher, school: @school1

    @subject2 = FactoryGirl.create :subject, subject_manager: @teacher1
    @section2_1 = FactoryGirl.create :section, subject: @subject2
    @section2_2 = FactoryGirl.create :section, subject: @subject2
    @discipline2 = @subject2.discipline

    @teaching_assignment2_1 = FactoryGirl.create :teaching_assignment, teacher: @teacher1, section: @section2_1
    @teaching_assignment2_2 = FactoryGirl.create :teaching_assignment, teacher: @teacher2, section: @section2_2

    @enrollment2_1_2 = FactoryGirl.create :enrollment, section: @section2_1, student: @student2
    @enrollment2_1_3 = FactoryGirl.create :enrollment, section: @section2_1, student: @student3
    @enrollment2_2_4 = FactoryGirl.create :enrollment, section: @section2_2, student: @student4
    @enrollment2_2_5 = FactoryGirl.create :enrollment, section: @section2_2, student: @student5

    @at_tardy = FactoryGirl.create :attendance_type, description: "Tardy", school: @school1
    @at_absent = FactoryGirl.create :attendance_type, description: "Absent", school: @school1
    @at_deact = FactoryGirl.create :attendance_type, description: "Deactivated", school: @school1, active: false
    @attendance_types = [@at_tardy, @at_absent, @at_deact]

    @excuse1 = FactoryGirl.create :excuse, school: @school1, code: 'EX', description: 'Excused'
    @excuse2 = FactoryGirl.create :excuse, school: @school1, code: 'DOC', description: "Doctor's note"
    @excuse3 = FactoryGirl.create :excuse, school: @school1, code: 'TRIP', description: "Field Trip"
    @excuses = [@excuse1, @excuse2, @excuse3]


    # @school2
    @school2 = FactoryGirl.create :school, :arabic
    @teacher2_1 = FactoryGirl.create :teacher, school: @school2
    @subject2_1 = FactoryGirl.create :subject, school: @school2, subject_manager: @teacher2_1
    @section2_1_1 = FactoryGirl.create :section, subject: @subject2_1

    @at_tardy2 = FactoryGirl.create :attendance_type, description: "Tardy2", school: @school2
    @excuse_sch2 = FactoryGirl.create :excuse, school: @school2, code: 'OOS', description: "Out of school"


    # @student attendance
    # in two subjects on multiple days
    @attendance1 = FactoryGirl.create :attendance,
      section: @section1_1,
      student: @student_fname1,
      attendance_type: @at_deact,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,1)
    @attendance2 = FactoryGirl.create :attendance,
      section: @section1_1,
      student: @student_fname1,
      attendance_type: @at_absent,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,2)
    @attendance3 = FactoryGirl.create :attendance,
      section: @section1_1,
      student: @student_fname1,
      attendance_type: @at_tardy,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,4)

    @attendance4 = FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student_fname1,
      attendance_type: @at_deact,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,1)
    @attendance5 = FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student_fname1,
      attendance_type: @at_absent,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,2)
    @attendance6 = FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student_fname1,
      attendance_type: @at_tardy,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,4)

    # other students
    # two sections of subject2 across two days
    @attendance7 = FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student3,
      attendance_type: @at_tardy,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,1)
    @attendance8 = FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student2,
      attendance_type: @at_absent,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,2)
    @attendance9 = FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student3,
      attendance_type: @at_tardy,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,2)

    # students not in @teacher1 classes on 9/5
    @attendance10 = FactoryGirl.create :attendance,
      section: @section2_2,
      student: @student4,
      attendance_type: @at_absent,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,5)
    @attendance11 = FactoryGirl.create :attendance,
      section: @section2_2,
      student: @student5,
      attendance_type: @at_tardy,
      excuse: @excuse1,
      attendance_date: Date.new(2015,9,5)

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
      @err_page = "/teachers/#{@teacher1.id}"
    end
    it { section_attendance_entry_is_valid }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @section.school
      sign_in(@school_administrator)
      @err_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { section_attendance_entry_is_valid }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@section.school)
      @err_page = "/researchers/#{@researcher.id}"
    end
    it { cannot_see_section_attendance_entry }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section.school)
      @err_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { section_attendance_entry_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @err_page = "/students/#{@student.id}"
    end
    it { cannot_see_section_attendance_entry }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @err_page = "/parents/#{@student.parent.id}"
    end
    it { cannot_see_section_attendance_entry }
  end

  ##################################################
  # test methods

  def cannot_see_section_attendance_entry
    # it "should not let unauthorized user see the section attendance page" do
    visit "/attendances/section_attendance/?section_id=#{@section.id}&layout=html_popup"
    page.should_not have_css('#attendance_date')
  end

  def section_attendance_entry_is_valid

    visit "/attendances/#{@section1_1.id}/section_attendance"

    # page should show attendance for current date
    within("form .block-title") do
      page.should have_content("Section Attendance for #{Date.today.to_s}")
    end

    # change attendance date to 9/1
    page.should have_css("#attendance_date_field")
    find("#attendance_date_field").value.should == Date.today.to_s
    page.execute_script("$('#attendance_date_field').val('2015-09-01')")
    page.execute_script("$('#attendance_date_field').trigger('change')")
    within("form .block-title") do
      page.should have_content("Section Attendance for 2015-09-01")
    end

    # confirm only school1 attendance types are listed
    within("table#attendance_table tbody tr#attendance_#{@student_fname1.id} select#attendance_#{@student_fname1.id}_attendance_type_id") do
      page.should_not have_content('Tardy2')
    end
    within("table#attendance_table tbody tr#attendance_#{@student_fname1.id} select#attendance_#{@student_fname1.id}_excuse_id") do
      page.should_not have_content('Out of school')
    end

    # confirm students are listed in correct order, and values already loaded are displayed.
    within("table#attendance_table tbody tr:nth-of-type(1)") do
      page.should have_content("#{@student_fname1.full_name}")
      find("select#attendance_#{@student_fname1.id}_attendance_type_id").value.should == @at_deact.id.to_s
      find("select#attendance_#{@student_fname1.id}_excuse_id").value.should == @attendance1.excuse.id.to_s
      find("input#attendance_#{@student_fname1.id}_comment").value.should == @attendance1.comment
    end
    page.should have_css("table#attendance_table tbody tr:nth-of-type(1)[id='attendance_#{@student_fname1.id}']")
    within("table#attendance_table tbody tr:nth-of-type(2)") do
      page.should have_content("#{@student.full_name}")
      find("select#attendance_#{@student.id}_attendance_type_id").value.should == ""
      find("select#attendance_#{@student.id}_excuse_id").value.should ==  ""
      find("input#attendance_#{@student.id}_comment").value.should == ""
    end
    page.should have_css("table#attendance_table tbody tr:nth-of-type(2)[id='attendance_#{@student.id}']")
    page.should have_css("table#attendance_table tbody tr:nth-of-type(3)[id='attendance_#{@student2.id}']")
    page.should have_css("table#attendance_table tbody tr:nth-of-type(4)[id='attendance_#{@student3.id}']")
    page.should have_css("table#attendance_table tbody tr:nth-of-type(5)[id='attendance_#{@student4.id}']")
    page.should have_css("table#attendance_table tbody tr:nth-of-type(6)[id='attendance_#{@student5.id}']")
    page.should have_css("table#attendance_table tbody tr:nth-of-type(7)[id='attendance_#{@student6.id}']")
    page.should have_css("table#attendance_table tbody tr:nth-of-type(8)[id='attendance_#{@student_new.id}']")
    page.should have_css("table#attendance_table tbody tr:nth-of-type(9)[id='attendance_#{@student_transferred.id}']")


  end  # section_attendance_entry_is_valid

end
