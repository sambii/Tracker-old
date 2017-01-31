# researcher_home_spec.rb
require 'spec_helper'


describe "Researcher Home Page", js:true do
  before (:each) do
    @researcher = FactoryGirl.create :researcher
    @section = FactoryGirl.create :section
    @school = @section.school
    @teacher = FactoryGirl.create :teacher, school: @school
    load_test_section(@section, @teacher)
    # todo - add prior/next year section
  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
      @home_page = "/teachers/#{@teacher.id}"
    end
    it { cannot_see_researcher_home }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school
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
    it { researcher_home_is_valid(true) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section.school)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { researcher_home_is_valid(false) }
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

  def researcher_home_is_valid(researcher)
    # this is only seen by researcher and system administrator
    visit researcher_path(@researcher.id)
    assert_equal(current_path, "/researchers/#{@researcher.id}")
    # has valid school summary page
    within("#overall #school-acronym") do
      page.should have_content(@school.acronym)
    end
    within("#school-summary") do
      page.should have_css("a[href='/schools/#{@school.id}/dashboard']")
      page.should have_css("a[href='/teachers/tracker_usage']")
      page.should have_css("a[href='/subjects/progress_meters']")
      page.should have_css("a[href='/subjects/proficiency_bars']")
      if researcher
        page.should_not have_css("a[href='/students/reports/proficiency_bar_chart']")
        page.should_not have_css("a[href='/users/account_activity_report']")
      else
        # system administrator
        page.should have_css("a[href='/students/reports/proficiency_bar_chart']")
        page.should have_css("a[href='/users/account_activity_report']")
      end
    end
  end

end
