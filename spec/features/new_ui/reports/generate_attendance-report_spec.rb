# generate_attendance-report_spec.rb
require 'spec_helper'


describe "Generate Attendance Report", js:true do
  before (:each) do

    load_multi_schools_sections # see load_section_helper.rb
    load_test_section(@section1_1, @teacher1)



    @at_tardy = FactoryGirl.create :attendance_type, description: "Tardy", school: @school1
    @at_absent = FactoryGirl.create :attendance_type, description: "Absent", school: @school1
    @at_deact = FactoryGirl.create :attendance_type, description: "Deactivated", school: @school1, active: false

    Rails.logger.debug("*** @enrollments: #{@enrollments.inspect}")

    Rails.logger.debug("*** @section1_1: #{@section1_1.inspect}")

    FactoryGirl.create :attendance,
      section: @enrollments[0].section,
      student: @enrollments[0].student,
      attendance_type: @at_tardy,
      attendance_date: Date.new(2015,9,1)
    FactoryGirl.create :attendance,
      section: @enrollments[1].section,
      student: @enrollments[1].student,
      attendance_type: @at_absent,
      attendance_date: Date.new(2015,9,1)
    FactoryGirl.create :attendance,
      section: @enrollments[0].section,
      student: @enrollments[0].student,
      attendance_type: @at_tardy,
      attendance_date: Date.new(2015,9,2)
    FactoryGirl.create :attendance,
      section: @enrollments[1].section,
      student: @enrollments[1].student,
      attendance_type: @at_deact,
      attendance_date: Date.new(2015,9,2)

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
      @err_page = "/teachers/#{@teacher1.id}"
    end
    it { has_valid_attendance_report(true) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { has_valid_attendance_report(true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { has_valid_attendance_report(false) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { has_valid_attendance_report(true) }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @err_page = "/students/#{@student.id}"
    end
    it { has_no_attendance_report }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @err_page = "/parents/#{@student.parent.id}"
    end
    it { has_no_attendance_report }
  end

  ##################################################
  # test methods

  def has_no_attendance_report
    # should not have a link to generate reports
    page.should_not have_css("#side-reports")
    page.should_not have_css("a", text: 'Generate Reports')
    # should fail when going to generate reports page directly
    visit new_generate_path
    assert_equal(@err_page, current_path)
    page.should_not have_content('Internal Server Error')
    # should fail when running attendance report directly
    visit attendance_report_attendances_path
    assert_equal(@err_page, current_path)
    within('head title') do
      page.should_not have_content('Internal Server Error')
    end
  end

  def has_valid_attendance_report(see_names)

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
        select('Attendance Report', from: "generate-type")
        find("select#generate-type").value.should == "attendance_report"
        page.should have_css('fieldset#ask-subjects', visible: true)
        page.should have_css('fieldset#ask-date-range', visible: true)
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
        
        sleep 20
        save_and_open_page

        # confirm that the required fields errors are displaying
        find("select#generate-type").value.should == "attendance_report"
        page.should have_css('fieldset#ask-subjects', visible: true)
        page.should have_css('fieldset#ask-date-range', visible: true)
        within("fieldset#ask-subjects") do
          page.should have_content('is a required field')
        end
        within("fieldset#ask-date-range") do
          page.should have_content('was an invalid value')
        end

        # fill in values for the attendance report
        select(@section1_1.subject.name, from: 'subject')
        # page.fill_in 'start-date', :with => '2015-06-02'
        # page.fill_in 'end-date', :with => '2015-06-08'
        # need to use javascript to fill in datepicker value
        page.execute_script("$('#start-date').val('2015-09-01')")
        page.execute_script("$('#end-date').val('2015-09-01')")

        # submit the request for the attendance report
        find("button", text: 'Generate').click
      end
    end

    assert_equal(attendance_report_attendances_path(), current_path)
    page.should_not have_content('Internal Server Error')

    within("#page-content") do
      within('.report-body') do
        
        page.should have_content("Attendance Report")
        within('table thead.table-title') do
          page.should have_content('ID')
          page.should have_content('Student Name')
          page.should have_content(@at_tardy.description)
          page.should have_content(@at_absent.description)
          page.should_not have_content('Other')
        end
        within("table tbody.tbody-header tr[data-student-id='#{@enrollments[0].student.id}']") do
          page.should have_content(@enrollments[0].student.full_name) if see_names
          within("td[data-type-id='#{@at_absent.id}']") do
            page.should have_content('0')
          end
          within("td[data-type-id='#{@at_tardy.id}']") do
            page.should have_content('1')
          end
          page.should_not have_css("td[data-type-id='9999999']")
        end
        within("table tbody.tbody-header tr[data-student-id='#{@enrollments[1].student.id}']") do
          page.should have_content(@enrollments[1].student.full_name) if see_names
          within("td[data-type-id='#{@at_absent.id}']") do
            page.should have_content('1')
          end
          within("td[data-type-id='#{@at_tardy.id}']") do
            page.should have_content('0')
          end
          page.should_not have_css("td[data-type-id='9999999']")
        end
        # should have inactive types dates listed at bottom of report
        page.should_not have_content('02 Sep 2015')
      end
    end

    ###############################################################################
    # generate a report with a deactivated attendance type showing 'Other' column
    page.should have_css("#side-reports a", text: 'Generate Reports')
    find("#side-reports a", text: 'Generate Reports').click
    page.should have_content('Generate Reports')
    within("#page-content") do
      within('form#new_generate') do
        select('Attendance Report', from: "generate-type")
        select(@section1_1.subject.name, from: 'subject')
        # javascript to fill in datepicker value
        page.execute_script("$('#start-date').val('2015-09-02')")
        page.execute_script("$('#end-date').val('2015-09-02')")
        # submit the request for the attendance report
        find("button", text: 'Generate').click
      end
    end

    assert_equal(attendance_report_attendances_path(), current_path)
    page.should_not have_content('Internal Server Error')

    within("#page-content") do
      within('.report-body') do
        
        page.should have_content("Attendance Report")
        within('table thead.table-title') do
          page.should have_content('ID')
          page.should have_content('Student Name')
          page.should have_content(@at_tardy.description)
          page.should have_content(@at_absent.description)
          page.should have_content('Other')
        end
        within("table tbody.tbody-header tr[data-student-id='#{@enrollments[0].student.id}']") do
          page.should have_content(@enrollments[0].student.full_name) if see_names
          within("td[data-type-id='#{@at_absent.id}']") do
            page.should have_content('0')
          end
          within("td[data-type-id='#{@at_tardy.id}']") do
            page.should have_content('1')
          end
          within("td[data-type-id='9999999']") do
            page.should have_content('0')
          end
        end
        within("table tbody.tbody-header tr[data-student-id='#{@enrollments[1].student.id}']") do
          page.should have_content(@enrollments[1].student.full_name) if see_names
          within("td[data-type-id='#{@at_absent.id}']") do
            page.should have_content('0')
          end
          within("td[data-type-id='#{@at_tardy.id}']") do
            page.should have_content('0')
          end
          within("td[data-type-id='9999999']") do
            page.should have_content('1')
          end
        end
        # should have inactive types dates listed at bottom of report
        page.should have_content('02 Sep 2015')
      end
    end

  end # def has_valid_attendance_report


end
