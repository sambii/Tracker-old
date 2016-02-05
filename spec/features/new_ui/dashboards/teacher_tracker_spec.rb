# teacher_dashboard_spec.rb
require 'spec_helper'


describe "Teacher Tracker", js:true do
  before (:each) do
    @section = FactoryGirl.create :section
    @teacher = FactoryGirl.create :teacher, school: @section.school
    load_test_section(@section, @teacher)
  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    it { teacher_tracker_is_valid }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @section.school
      sign_in(@school_administrator)
    end
    it { teacher_tracker_is_valid }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@section.school)
    end
    it { teacher_tracker_is_valid }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section.school)
    end
    it { teacher_tracker_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { cannot_see_teacher_tracker }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { cannot_see_teacher_tracker }
  end

  ##################################################
  # test methods

  def cannot_see_teacher_tracker
    visit section_path(@section.id)
    assert_not_equal("/sections/#{@section.id}", current_path)
  end

  def teacher_tracker_is_valid
    visit section_path(@section.id)
    assert_equal("/sections/#{@section.id}", current_path)

    # todo - enter tests
    within("table[data-section-id='#{@section.id}']") do
      # page.should have_content('xxxx')
    end

    # todo - validate links on page
    # page.find("tr a[href='/sections/#{@section.id}/class_dashboard']").click
    # assert_equal("/sections/#{@section.id}/class_dashboard", current_path)
  end

end
