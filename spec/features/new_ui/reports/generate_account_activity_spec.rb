# generate_account_activity_spec.rb
require 'spec_helper'


describe "Generate Account Activity Report", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    @school = FactoryGirl.create :school, :arabic
    @teacher = FactoryGirl.create :teacher, school: @school
    @subject = FactoryGirl.create :subject, school: @school, subject_manager: @teacher
    @section = FactoryGirl.create :section, subject: @subject
    @discipline = @subject.discipline

    load_test_section(@section, @teacher)


  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
      @home_page = "/teachers/#{@teacher.id}"
    end
    it { has_no_account_activity_report }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { has_valid_account_activity_report(:school_administrator) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { has_valid_account_activity_report(:researcher) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { has_valid_account_activity_report(:system_administrator) }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { has_no_reports }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
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
    # should fail when running tracker usage report directly
    visit tracker_usage_teachers_path
    assert_equal(@err_page, current_path)
    within('head title') do
      page.should_not have_content('Internal Server Error')
    end
  end

  def has_no_account_activity_report
    page.should have_css("#side-reports a", text: 'Generate Reports')
    find("#side-reports a", text: 'Generate Reports').click
    page.should have_content('Generate Reports')
    within("#page-content") do
      within('form#new_generate') do
        page.should have_selector("select#generate-type")
        within('select#generate-type') do
          page.should_not have_css('option#account_activity')
        end
      end
    end
    # should fail when running tracker usage report directly
    visit tracker_usage_teachers_path
    assert_equal(@err_page, current_path)
    within('head title') do
      page.should_not have_content('Internal Server Error')
    end
  end

  def has_valid_account_activity_report(role)
    page.should have_css("#side-reports a", text: 'Generate Reports')
    find("#side-reports a", text: 'Generate Reports').click
    page.should have_content('Generate Reports')
    within("#page-content") do
      within('form#new_generate') do
        page.should have_selector("select#generate-type")
        select('Account Activity Report', from: "generate-type")
        find("select#generate-type").value.should == "account_activity"
        if [:system_administrator, :school_administrator].include?(role)
          page.should have_css('fieldset.ask-user-type-groupings input#user-type-staff-box', visible: true)
        else
          page.should_not have_css('fieldset.ask-user-type-groupings input#user-type-staff-box')
        end
        # in case users other than administrators can see this report in the future
        page.should have_css('fieldset.ask-user-type-groupings input#user-type-students-box', visible: true)
        page.should have_css('fieldset.ask-user-type-groupings input#user-type-parents-box', visible: true)
        find("button", text: 'Generate').click
        # no user types clicked, should be able to click the generate button till one is clicked.
      end
    end


    assert_equal(account_activity_report_users_path(), current_path)
    page.should_not have_content('Internal Server Error')

    within("#page-content") do
      within('.report-header') do
        page.should have_content("Tracker Activity for School #{@school1.name}")
      end
      within('.report-body') do
        within("table tbody.tbody-header[data-tch-id='#{@teacher1.id}']") do
          page.should have_css("td.evid_count", text: '27')
          page.should have_css("td.evid_rated_count", text: '25')
          page.should have_css("td.los_count", text: '9')
          page.should have_css("td.los_rated_count", text: '7')
        end
        within("table tbody.tbody-body[data-tch-id='#{@teacher1.id}']") do
          page.should have_css("td.evid_count", text: '27')
          page.should have_css("td.evid_rated_count", text: '25')
          page.should have_css("td.los_count", text: '9')
          page.should have_css("td.los_rated_count", text: '7')
        end
      end
    end
  end # def has_valid_tracker_usage_report


end
