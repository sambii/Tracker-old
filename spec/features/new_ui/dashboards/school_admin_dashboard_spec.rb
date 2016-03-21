# teacher_dashboard_spec.rb
require 'spec_helper'


describe "School Admin Dashboard", js:true do
  before (:each) do
    @section = FactoryGirl.create :section
    @teacher = FactoryGirl.create :teacher, school: @section.school
    @school_administrator = FactoryGirl.create :school_administrator, school: @section.school
    load_test_section(@section, @teacher)
    @subject = @section.subject
  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    it { cannot_see_school_admin_dashboard }
  end

  describe "as school administrator" do
    before do
      sign_in(@school_administrator)
    end
    it { school_admin_dashboard_is_valid }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@section.school)
    end
    it { cannot_see_school_admin_dashboard }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section.school)
    end
    it { school_admin_dashboard_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { cannot_see_school_admin_dashboard }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { cannot_see_school_admin_dashboard }
  end

  ##################################################
  # test methods

  def cannot_see_school_admin_dashboard
    visit school_administrator_path(@school_administrator.id)
    assert_not_equal("/school_administrators/#{@school_administrator.id}", current_path)
  end

  def school_admin_dashboard_is_valid
    visit school_administrator_path(@school_administrator.id)
    assert_equal("/school_administrators/#{@school_administrator.id}", current_path)

    # Note overall lo counts should == prof bar counts for each color
    
    within("#overall") do
      page.should have_content('9 - High Performance')
      page.should have_content('9 - Proficient')
      page.should have_content('9 - Not Yet Proficient')
      page.should have_content('9 - Unrated')
    end

    within("#proficiency") do
      page.should have_css('div.high-rating-bar', text: '9')
      page.should have_css('div.prof-rating-bar', text: '9')
      page.should have_css('div.nyp-rating-bar', text: '9')
      page.should have_css('div.unrated-rating-bar', text: '9')
    end

    # make sure learning outcomes covered match
    within("#learning") do
      page.should have_content("4 out of 4")
    end

    #  validate links on page
    find("#prof-subj-#{@subject.id}")[:href].should have_content("/subjects/#{@subject.id}")
    find("#learning-subj-#{@subject.id}")[:href].should have_content("/subjects/#{@subject.id}")

    # page.find("tr a[href='/sections/#{@section.id}/class_dashboard']").click
    # assert_equal("/sections/#{@section.id}/class_dashboard", current_path)
  end

end
