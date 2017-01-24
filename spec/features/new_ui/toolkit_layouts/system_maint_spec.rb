# system_maint_spec.rb
require 'spec_helper'


describe "System Maintenance", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    # @school1
    @school1 = FactoryGirl.create :school_current_year, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    @discipline = @subject1.discipline
    load_test_section(@section1_1, @teacher1)

  end


  describe "as teacher" do
    before do
      sign_in(@teacher1)
      @home_page = "/teachers/#{@teacher1.id}"
    end
    it { has_valid_system_maintenance(:teacher) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { has_valid_system_maintenance(:school_administrator) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { has_valid_system_maintenance(:researcher) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { has_valid_system_maintenance(:system_administrator) }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { has_valid_system_maintenance(:student) }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { has_valid_system_maintenance(:parent) }
  end

  ##################################################
  # test methods

  def has_valid_system_maintenance(role)

    # has System Maint link in Toolkit
    if role == :system_administrator

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

    else
      # should not have a active toolkit item for System Maint.
      page.should_not have_css("#side-sys-maint")
      page.should_not have_css("a[href='/system_administrators/system_maintenance']")
      # try to go directly to page
      visit system_maintenance_system_administrators_path
      assert_equal(@home_page, current_path)
    end


  end # has_valid_system_maintenance

end
