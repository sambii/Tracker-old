# researcher_home_spec.rb
require 'spec_helper'


describe "Researcher Home Page", js:true do
  before (:each) do
    @researcher = FactoryGirl.create :researcher
    @section = FactoryGirl.create :section
    @teacher = FactoryGirl.create :teacher, school: @section.school
    load_test_section(@section, @teacher)
    # todo - add prior/next year section
  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
      @home_page = "/teachers/#{@teacher1.id}"
    end
    it { cannot_see_researcher_home }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @section.school
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { cannot_see_researcher_home }
  end

  describe "as researcher" do
    before do
      sign_in(@researcher)
      set_users_school(@section.school)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { researcher_home_is_valid }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section.school)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { researcher_home_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { cannot_see_researcher_home }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { cannot_see_researcher_home }
  end

  ##################################################
  # test methods

  def cannot_see_researcher_home
    visit researcher_path(@researcher.id)
    assert_not_equal(current_path, "/researchers/#{@researcher.id}")
    assert_equal(current_path, @home_page)
  end

  def researcher_home_is_valid
    visit researcher_path(@researcher.id)
    assert_not_equal(current_path, "/researchers/#{@researcher.id}")
    # has valid school summary page
    within("#overall #school-acronym") do
      page.should have_content(@school2.acronym)
    end
    within("#summary") do
      page.should have_css("/schools/#{@school1.id}/dashboard")
      page.should have_css("/teachers/tracker_usage")
      page.should have_css("/subjects/progress_meters")
      page.should have_css("/subjects/proficiency_bars")
      if researcher
        page.should_not have_css("/students/reports/proficiency_bar_chart")
        page.should_not have_css("/users/account_activity_report")
        page.should_not have_css("/users/staff_activity_report")
      else
        page.should have_css("/students/reports/proficiency_bar_chart")
        page.should_not have_css("/users/account_activity_report")
        page.should have_css("/users/staff_activity_report")
      end
    end
  end

end
