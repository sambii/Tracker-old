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

    # should not have a active toolkit item for System Maint.
    page.should_not have_css("#side-sys-maint")
    page.should_not have_css("a[href='/system_administrators/system_maintenance']")
    # try to go directly to page
    visit system_maintenance_system_administrators_path
    assert_equal(@home_page, current_path)

  end

  def system_admin_home_is_valid
    # this is only seen by system administrator
    visit system_administrator_path(@researcher.id)
    assert_equal(current_path, "/system_administrators/#{@system_administrator.id}")

    # should have an active toolkit item for system maintenance
    within("#side-sys-maint") do
      find("a[href='/system_administrators/system_maintenance']").click
    end
    assert_not_equal(@home_page, current_path)
    assert_equal('/system_administrators/system_maintenance', current_path)

    within("#page-content h2") do
      page.should have_content('System Maintenance')
    end

    within("#page-content #sys-maint #sys-admin-links") do
      within('#system-alerts') do
        page.should have_css("a[href='/announcements']")
        page.should have_content('System Alerts')
      end
    end

  end

end

