# system_admin_home_spec.rb
require 'spec_helper'


describe "System Administrator Home Page", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    @system_administrator = FactoryGirl.create :system_administrator
    @researcher = FactoryGirl.create :researcher
    @school = FactoryGirl.create :school_current_year, :arabic
    @school_administrator = FactoryGirl.create :school_administrator, school: @school
    @teacher = FactoryGirl.create :teacher, school: @school
    @subject = FactoryGirl.create :subject, school: @school, subject_manager: @teacher
    @section = FactoryGirl.create :section, subject: @subject
    load_test_section(@section, @teacher)

    @school2 = FactoryGirl.create :school_current_year, :arabic
  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
      @home_page = "/teachers/#{@teacher.id}"
    end
    it { cannot_see_system_admin_home }
  end

  describe "as school administrator" do
    before do
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { cannot_see_system_admin_home }
  end

  describe "as researcher" do
    before do
      sign_in(@researcher)
      set_users_school(@section.school)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { cannot_see_system_admin_home }
  end

  describe "as system administrator" do
    before do
      sign_in(@system_administrator)
      set_users_school(@section.school)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { system_admin_home_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { cannot_see_system_admin_home }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { cannot_see_system_admin_home }
  end

  ##################################################
  # test methods

  def cannot_see_system_admin_home
    visit system_administrator_path(@system_administrator.id)
    assert_not_equal(current_path, "/system_administrators/#{@system_administrator.id}")
    assert_equal(current_path, @home_page)
  end

  def system_admin_home_is_valid
    # this is only seen by system administrator
    visit system_administrator_path(@system_administrator.id)
    assert_equal(current_path, "/system_administrators/#{@system_administrator.id}")

    within('#sys-admin-links') do
      page.should have_css("#system-alerts a[href='/announcements']")
      page.should have_css("#server-config a[href='/server_configs/1']")
      page.should have_css("#disciplines a[href='/disciplines']")
    end

    within('#school-listing') do
      # should list all schools in the system
      page.should have_css("tr#school-#{@model_school.id}")
      page.should have_css("tr#school-#{@training_school.id}")
      page.should have_css("tr#school-#{@school.id}")
      page.should have_css("tr#school-#{@school2.id}")
      page.all("tbody tr").count.should == 4
    end

  end

end

