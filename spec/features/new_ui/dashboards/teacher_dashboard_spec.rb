# teacher_dashboard_spec.rb
require 'spec_helper'


describe "Teacher Dashboard", js:true do
  before (:each) do
    @section = FactoryGirl.create :section
    @teacher = FactoryGirl.create :teacher, school: @section.school
    load_test_section(@section, @teacher)
    # todo - add prior/next year section
  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    # it { can_see_teacher_dashboard }
    it { teacher_dashboard_is_valid }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @section.school
      sign_in(@school_administrator)
    end
    # it { can_see_teacher_dashboard }
    it { teacher_dashboard_is_valid }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@section.school)
    end
    # it { can_see_teacher_dashboard }
    it { teacher_dashboard_is_valid }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section.school)
    end
    # it { can_see_teacher_dashboard }
    it { teacher_dashboard_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { cannot_see_teacher_dashboard }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { cannot_see_teacher_dashboard }
  end

  ##################################################
  # test methods

  def cannot_see_teacher_dashboard
    visit teacher_path(@teacher.id)
    assert_not_equal("/teachers/#{@teacher.id}", current_path)
  end

  def teacher_dashboard_is_valid
    visit teacher_path(@teacher.id)
    assert_equal("/teachers/#{@teacher.id}", current_path)
    within("#overall") do
      page.should have_content('6 - High Performance')
      page.should have_content('6 - Proficient')
      page.should have_content('6 - Not Yet Proficient')
      page.should have_content('6 - Unrated')
    end

    within("#prof_bar") do
      page.should have_css('div.high-rating-bar', text: '6')
      page.should have_css('div.prof-rating-bar', text: '6')
      page.should have_css('div.nyp-rating-bar', text: '6')
      page.should have_css('div.unrated-rating-bar', text: '6')
    end

    # make sure section count includes the 6 rated students, plus the new one.
    page.should have_css("#active_section tr[data-active-section-id='#{@section.id}'] td", text: '7 Students')

    page.should_not have_css("#nyp_student tr[data-nyp-student-id='#{@student_unenrolled.id}']")
    page.should_not have_css("#nyp_student tr[data-nyp-student-id='#{@student_transferred.id}']")
    page.should_not have_css("#nyp_student tr[data-nyp-student-id='#{@student_out.id}']")

    # todo - test for recent activity

    # todo - validate links on page
    # page.find("tr a[href='/sections/#{@section.id}/class_dashboard']").click
    # assert_equal("/sections/#{@section.id}/class_dashboard", current_path)
  end

end
