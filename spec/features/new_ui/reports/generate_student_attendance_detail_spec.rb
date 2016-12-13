# generate_student_attendance_detail_spec.rb
require 'spec_helper'


describe "Generate Student Attendance Detail Report", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    # @school1
    @school1 = FactoryGirl.create :school_current_year, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    @discipline = @subject1.discipline
    load_test_section(@section1_1, @teacher1)

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

    # @student attendance
    # in two subjects on multiple days
    FactoryGirl.create :attendance,
      section: @section1_1,
      student: @student,
      attendance_type: @at_deact,
      attendance_date: Date.new(2015,9,1)
    FactoryGirl.create :attendance,
      section: @section1_1,
      student: @student,
      attendance_type: @at_absent,
      attendance_date: Date.new(2015,9,2)
    FactoryGirl.create :attendance,
      section: @section1_1,
      student: @student,
      attendance_type: @at_tardy,
      attendance_date: Date.new(2015,9,4)

    FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student,
      attendance_type: @at_deact,
      attendance_date: Date.new(2015,9,1)
    FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student,
      attendance_type: @at_absent,
      attendance_date: Date.new(2015,9,2)
    FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student,
      attendance_type: @at_tardy,
      attendance_date: Date.new(2015,9,4)

    # other students
    # two sections of subject2 across two days
    FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student3,
      attendance_type: @at_tardy,
      attendance_date: Date.new(2015,9,1)
    FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student2,
      attendance_type: @at_absent,
      attendance_date: Date.new(2015,9,2)
    FactoryGirl.create :attendance,
      section: @section2_1,
      student: @student3,
      attendance_type: @at_tardy,
      attendance_date: Date.new(2015,9,2)

    # students not in @teacher1 classes on 9/5
    FactoryGirl.create :attendance,
      section: @section2_2,
      student: @student4,
      attendance_type: @at_absent,
      attendance_date: Date.new(2015,9,5)
    FactoryGirl.create :attendance,
      section: @section2_2,
      student: @student5,
      attendance_type: @at_tardy,
      attendance_date: Date.new(2015,9,5)

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
      @err_page = "/teachers/#{@teacher1.id}"
    end
    it { has_valid_student_attendance_detail_report(true, false) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { has_valid_student_attendance_detail_report(true, true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
      @err_page = "/researchers/#{@researcher.id}"
    end
    it { has_no_student_attendance_detail_report }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { has_valid_student_attendance_detail_report(true, true) }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @err_page = "/students/#{@student.id}"
    end
    it { has_no_reports }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @err_page = "/parents/#{@student.parent.id}"
    end
    it { has_no_reports }
  end

  ##################################################
  # test methods

  def has_no_reports
    # should not have a link to generate reports
    page.should_not have_css("#side-reports")
    page.should_not have_css("a", text: 'Generate Reports')
    # should fail when going to generate reports page directly
    visit new_generate_path
    assert_equal(@err_page, current_path)
    page.should_not have_content('Internal Server Error')
    # should fail when running attendance report directly
    visit student_attendance_detail_report_attendances_path
    assert_equal(@err_page, current_path)
    within('head title') do
      page.should_not have_content('Internal Server Error')
    end
  end

  def has_no_student_attendance_detail_report
    # should not have a link to generate reports
    page.should have_css("#side-reports")
    page.should have_css("a", text: 'Generate Reports')
    # should fail when going to generate reports page directly
    visit new_generate_path
    assert_not_equal(@err_page, current_path)
    page.should_not have_content('Internal Server Error')
    # should fail when running attendance report directly
    visit student_attendance_detail_report_attendances_path
    assert_equal(@err_page, current_path)
    within('head title') do
      page.should_not have_content('Internal Server Error')
    end
  end

  def has_valid_student_attendance_detail_report(see_names, see_all_sections)

    ###############################################################################
    # generate a report with all attendance types used are active (no 'Other' column)
    page.should have_css("#side-reports a", text: 'Generate Reports')
    find("#side-reports a", text: 'Generate Reports').click

    page.should have_content('Generate Reports')
    within("#page-content") do
      within('form#new_generate') do
        page.should have_css('fieldset#ask-subjects', visible: false)
        page.should have_css('fieldset#ask-date-range', visible: false)
        page.should have_selector("select#generate-type")
        select('Student Attendance Detail Report', from: "generate-type")
        find("select#generate-type").value.should == "student_attendance_detail_report"
        page.should have_css('fieldset#ask-student', visible: true)
        page.should have_css('fieldset#ask-date-range', visible: true)
        page.should have_css('fieldset#ask-attendance-type', visible: true)
        page.should have_css('fieldset#ask-details', visible: true)
        page.fill_in 'start-date', :with => '2015-06-02' # note: generates an invalid date in datepicker
        page.fill_in 'end-date', :with => '2015-06-08' # note: generates an invalid date in datepicker
        find("button", text: 'Generate').click
      end
    end

    # should return back to generate reports page with required fields errors
    page.should have_content('Generate Reports')
    page.should_not have_content('Internal Server Error')
    within("#page-content") do
      within('form#new_generate') do

        # confirm that the required fields errors are displaying
        find("select#generate-type").value.should == "student_attendance_detail_report"
        page.should have_css('fieldset#ask-subjects', visible: false)
        page.should have_css('fieldset#ask-student', visible: true)
        page.should have_css('fieldset#ask-date-range', visible: true)
        within("fieldset#ask-student") do
          page.should_not have_content('is a required field')
        end
        within("fieldset#ask-date-range") do
          page.should have_content('was an invalid value')
        end

        # fill in values for the attendance report (detail report for all students with deactivated types)
        # select(@student.full_name, from: 'student')
        # need to use javascript to properly fill in datepicker value
        # entering dates including 9/5 so teacher1 should not be able to see
        page.execute_script("$('#start-date').val('2015-09-01')")
        page.execute_script("$('#end-date').val('2015-09-05')")
        find('fieldset#ask-details #details-box').should_not be_checked
        find('fieldset#ask-details #details-box').click
        find('fieldset#ask-details #details-box').should be_checked

        # submit the request for the attendance report
        find("button", text: 'Generate').click
      end
    end

    assert_equal(student_attendance_detail_report_attendances_path(), current_path)
    page.should_not have_content('Internal Server Error')

    within("#page-content") do
      page.should have_content("Student Attendance Detail Report")
      within('.report-body') do
        within('table thead.table-title') do
          page.should have_content('Date')
          page.should have_content('Section')
          page.should have_content(@at_tardy.description)
          page.should have_content(@at_absent.description)
          page.should have_content('Other')
        end

        # @student
        within("table tr.header-row[data-student-id='#{@student.id}']") do
          if see_names
            page.should have_content(@student.full_name)
          else
            page.should_not have_content(@student.full_name)
          end
        end

        # @student 9/1
        within("table tr[data-student-id='#{@student.id}'][data-section-id='#{@section1_1.id}'][data-date='2015-09-01']") do
          page.should have_css('td .attendance-date', text: '2015-09-01')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '')
          page.should have_css("td[data-type-id='9999999']", text: '1')
        end
        within("table tr[data-student-id='#{@student.id}'][data-section-id='#{@section2_1.id}'][data-date='2015-09-01']") do
          page.should have_css('td .attendance-date', text: '2015-09-01')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '')
          page.should have_css("td[data-type-id='9999999']", text: '1')
        end
        within("table tr.total-row[data-student-id='#{@student.id}'][data-date='2015-09-01']") do
          page.should have_css('td.attendance-date', text: 'Total 2015-09-01')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '0')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '0')
          page.should have_css("td[data-type-id='9999999']", text: '2')
        end

        # @student 9/2
        within("table tr[data-student-id='#{@student.id}'][data-section-id='#{@section1_1.id}'][data-date='2015-09-02']") do
          page.should have_css('td .attendance-date', text: '2015-09-02')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '1')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '')
          page.should have_css("td[data-type-id='9999999']", text: '')
        end
        within("table tr[data-student-id='#{@student.id}'][data-section-id='#{@section2_1.id}'][data-date='2015-09-02']") do
          page.should have_css('td .attendance-date', text: '2015-09-02')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '1')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '')
          page.should have_css("td[data-type-id='9999999']", text: '')
        end
        within("table tr.total-row[data-student-id='#{@student.id}'][data-date='2015-09-02']") do
          page.should have_css('td.attendance-date', text: 'Total 2015-09-02')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '2')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '0')
          page.should have_css("td[data-type-id='9999999']", text: '0')
        end

        # @student 9/4
        within("table tr[data-student-id='#{@student.id}'][data-section-id='#{@section1_1.id}'][data-date='2015-09-04']") do
          page.should have_css('td .attendance-date', text: '2015-09-04')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '1')
          page.should have_css("td[data-type-id='9999999']", text: '')
        end
        within("table tr[data-student-id='#{@student.id}'][data-section-id='#{@section2_1.id}'][data-date='2015-09-04']") do
          page.should have_css('td .attendance-date', text: '2015-09-04')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '1')
          page.should have_css("td[data-type-id='9999999']", text: '')
        end
        within("table tr.total-row[data-student-id='#{@student.id}'][data-date='2015-09-04']") do
          page.should have_css('td.attendance-date', text: 'Total 2015-09-04')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '0')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '2')
          page.should have_css("td[data-type-id='9999999']", text: '0')
        end

        # total @student
        within("table tr.total-student-row[data-student-id='#{@student.id}']") do
          page.should have_css("a[href='/users/#{@student.id}']")
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '2')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '2')
          page.should have_css("td[data-type-id='9999999']", text: '2')
        end

        # @student2
        within("table tr.header-row[data-student-id='#{@student2.id}']") do
          if see_names
            page.should have_content(@student2.full_name)
          else
            page.should_not have_content(@student2.full_name)
          end
        end

        # @student2 9/2
        within("table tr[data-student-id='#{@student2.id}'][data-section-id='#{@section2_1.id}'][data-date='2015-09-02']") do
          page.should have_css('td .attendance-date', text: '2015-09-02')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '1')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '')
          page.should have_css("td[data-type-id='9999999']", text: '')
        end
        within("table tr.total-row[data-student-id='#{@student2.id}'][data-date='2015-09-02']") do
          page.should have_css('td.attendance-date', text: 'Total 2015-09-02')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '1')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '0')
          page.should have_css("td[data-type-id='9999999']", text: '0')
        end

        # total @student
        within("table tr.total-row[data-student-id='#{@student2.id}']") do
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '1')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '0')
          page.should have_css("td[data-type-id='9999999']", text: '0')
        end

        # @student3 9/2
        within("table tr[data-student-id='#{@student3.id}'][data-section-id='#{@section2_1.id}'][data-date='2015-09-02']") do
          page.should have_css('td .attendance-date', text: '2015-09-02')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '1')
          page.should have_css("td[data-type-id='9999999']", text: '')
        end
        within("table tr.total-row[data-student-id='#{@student3.id}'][data-date='2015-09-02']") do
          page.should have_css('td.attendance-date', text: 'Total 2015-09-02')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '0')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '1')
          page.should have_css("td[data-type-id='9999999']", text: '0')
        end

        # total @student
        within("table tr.total-row[data-student-id='#{@student3.id}']") do
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '0')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '1')
          page.should have_css("td[data-type-id='9999999']", text: '0')
        end

        # should have inactive types dates listed at bottom of report
        page.should_not have_content('02 Sep 2015')
      end
    end

    ###############################################################################
    # generate a report with no 'Other' column for @student and no section detail under date
    page.should have_css("#side-reports a", text: 'Generate Reports')
    find("#side-reports a", text: 'Generate Reports').click
    page.should have_content('Generate Reports')
    within("#page-content") do
      within('form#new_generate') do
        select('Student Attendance Detail Report', from: "generate-type")
        find("select#generate-type").value.should == "student_attendance_detail_report"
        select(@student.full_name, from: 'student')
        page.execute_script("$('#start-date').val('2015-09-02')")
        page.execute_script("$('#end-date').val('2015-09-04')")
        find("button", text: 'Generate').click
      end
    end

    assert_equal(student_attendance_detail_report_attendances_path(), current_path)
    page.should_not have_content('Internal Server Error')

    within("#page-content") do
      page.should have_content("Student Attendance Detail Report")
      within('.report-body') do
        within('table thead.table-title') do
          page.should have_content('Date')
          page.should have_content('Section')
          page.should have_content(@at_tardy.description)
          page.should have_content(@at_absent.description)
          page.should_not have_content('Other')
        end

        # @student
        within("table tr.header-row[data-student-id='#{@student.id}']") do
          if see_names
            page.should have_content(@student.full_name)
          else
            page.should_not have_content(@student.full_name)
          end
        end

        # @student 9/2
        within("table tr[data-student-id='#{@student.id}'][data-date='2015-09-02']") do
          page.should have_css('td.attendance-date', text: 'Total 2015-09-02')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '2')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '0')
          page.should_not have_css("td[data-type-id='9999999']")
        end

        # @student 9/4
        within("table tr[data-student-id='#{@student.id}'][data-date='2015-09-04']") do
          page.should have_css('td.attendance-date', text: 'Total 2015-09-04')
          page.should have_css("td[data-type-id='#{@at_absent.id}']", text: '0')
          page.should have_css("td[data-type-id='#{@at_tardy.id}']", text: '2')
          page.should_not have_css("td[data-type-id='9999999']")
        end

        # should not have other students listed
        page.should_not have_css("table tr.header-row[data-student-id='#{@student2.id}']")
        page.should_not have_css("table tr.header-row[data-student-id='#{@student3.id}']")

        # should have inactive types dates listed at bottom of report
        page.should_not have_content('02 Sep 2015')
      end
    end

    ###############################################################################
    # generate a report all students with deactivated attendance type
    page.should have_css("#side-reports a", text: 'Generate Reports')
    find("#side-reports a", text: 'Generate Reports').click
    page.should have_content('Generate Reports')
    within("#page-content") do
      within('form#new_generate') do
        select('Student Attendance Detail Report', from: "generate-type")
        # select(@student.full_name, from: 'student')
        page.execute_script("$('#start-date').val('2015-09-01')")
        page.execute_script("$('#end-date').val('2015-09-04')")
        select("Deactivated", from: "attendance-type-select")
        find('fieldset#ask-details #details-box').should_not be_checked
        find('fieldset#ask-details #details-box').click
        find('fieldset#ask-details #details-box').should be_checked
        find("button", text: 'Generate').click
      end
    end

    assert_equal(student_attendance_detail_report_attendances_path(), current_path)
    page.should_not have_content('Internal Server Error')

    within("#page-content") do
      page.should have_content("Student Attendance Detail Report")
      within('.report-body') do
        within('table thead.table-title') do
          page.should have_content('Date')
          page.should have_content('Section')
          page.should_not have_content(@at_tardy.description)
          page.should_not have_content(@at_absent.description)
          page.should have_content(@at_deact.description)
          page.should_not have_content('Other')
        end

        # @student
        within("table tr.header-row[data-student-id='#{@student.id}']") do
          if see_names
            page.should have_content(@student.full_name)
          else
            page.should_not have_content(@student.full_name)
          end
        end

        # @student 9/1
        within("table tr[data-student-id='#{@student.id}'][data-section-id='#{@section1_1.id}'][data-date='2015-09-01']") do
          page.should have_css('td .attendance-date', text: '2015-09-01')
          page.should_not have_css("td[data-type-id='#{@at_absent.id}']")
          page.should_not have_css("td[data-type-id='#{@at_tardy.id}']")
          page.should have_css("td[data-type-id='#{@at_deact.id}']", text: '1')
          page.should_not have_css("td[data-type-id='9999999']")
        end
        within("table tr[data-student-id='#{@student.id}'][data-section-id='#{@section2_1.id}'][data-date='2015-09-01']") do
          page.should have_css('td .attendance-date', text: '2015-09-01')
          page.should_not have_css("td[data-type-id='#{@at_absent.id}']")
          page.should_not have_css("td[data-type-id='#{@at_tardy.id}']")
          page.should have_css("td[data-type-id='#{@at_deact.id}']", text: '1')
          page.should_not have_css("td[data-type-id='9999999']")
        end
        within("table tr.total-row[data-student-id='#{@student.id}'][data-date='2015-09-01']") do
          page.should have_css('td.attendance-date', text: 'Total 2015-09-01')
          page.should_not have_css("td[data-type-id='#{@at_absent.id}']")
          page.should_not have_css("td[data-type-id='#{@at_tardy.id}']")
          page.should have_css("td[data-type-id='#{@at_deact.id}']", text: '2')
          page.should_not have_css("td[data-type-id='9999999']")
        end
        # total @student
        within("table tr.total-row[data-student-id='#{@student.id}']") do
          page.should_not have_css("td[data-type-id='#{@at_absent.id}']")
          page.should_not have_css("td[data-type-id='#{@at_tardy.id}']")
          page.should have_css("td[data-type-id='#{@at_deact.id}']", text: '2')
          page.should_not have_css("td[data-type-id='9999999']")
        end
        # should have inactive types dates listed at bottom of report
        page.should_not have_content('02 Sep 2015')
      end
    end

  end # def has_valid_student_attendance_detail_report


end
