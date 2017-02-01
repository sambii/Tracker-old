# server_config_spec.rb
require 'spec_helper'


describe "Server Configuration Maintenance", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    @system_administrator = FactoryGirl.create :system_administrator
    @researcher = FactoryGirl.create :researcher
    @school = FactoryGirl.create :school_current_year, :arabic
    @school_administrator = FactoryGirl.create :school_administrator, school: @school
    @teacher = FactoryGirl.create :teacher, school: @school
    @subject = FactoryGirl.create :subject, school: @school, subject_manager: @teacher
    @section = FactoryGirl.create :section, subject: @subject

    load_test_section(@section, @teacher, false) # no server config file created

    @school2 = FactoryGirl.create :school_current_year, :arabic

  end


  describe "as teacher" do
    before do
      sign_in(@teacher)
      @home_page = "/teachers/#{@teacher.id}"
    end
    it { cannot_see_server_config }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { cannot_see_server_config }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      # set_users_school(@school)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { cannot_see_server_config }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      # set_users_school(@school)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { can_maintain_server_config }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { cannot_see_server_config }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { cannot_see_server_config }
  end

  ##################################################
  # test methods

  def cannot_see_server_config
    visit system_administrator_path(@system_administrator.id)
    assert_not_equal(current_path, "/system_administrators/#{@system_administrator.id}")
    assert_equal(current_path, @home_page)

  end # cannot_see_system_admin_home

  def can_maintain_server_config
    # this is only seen by a system administrator, so landing page should be the sys admin home page

    ##################################################
    # ensure that system admins are quickly warned and can quickly fix a missing server configuration record.

    # confirm that sys admin home page has a warning about server config table
    page.should have_css('#overall #sys-admin-links #server-config span.ui-error')

    # confirm that viewing at the server config record automatically creates one
    page.find('#overall #sys-admin-links #server-config a').click
    within('#breadcrumb-flash-msgs') do
      page.should have_content('ERROR: Server Config did not exist, Default one Created, Please Edit!')
    end

    # confirm missing server config record error message is gone from home page
    visit system_administrator_path(@system_administrator.id)
    page.should_not have_css('#overall #sys-admin-links #server-config span.ui-error')

    ##################################################
    # edit the server config record and confirm all required fields must be filled in

    # bring up edit server configuration record
    page.find('#overall #sys-admin-links #server-config a').click
    page.should have_css('h2 strong', text: 'View Server Configuration')
    page.find("#overall a[href='/server_configs/1/edit']").click
    page.should have_css('h2 strong', text: 'Edit Server Configuration')

    # try to save server config record with blanks, and confirm we get errors back
    within('form#edit_server_config_1') do
      fill_in('support_email', with: '')
      fill_in('support_team', with: '')
      fill_in('school_support_team', with: '')
      fill_in('server_url', with: '')
      fill_in('server_name', with: '')
      fill_in('web_server_name', with: '')
      find('button', text: 'Save').click
    end

    # confirm that we are still in the edit server config page with errors
    page.should have_css('h2 strong', text: 'Edit Server Configuration')
    within('form#edit_server_config_1') do
      page.should have_css('fieldset#support-email span.ui-error')
      page.should have_css('fieldset#support-team span.ui-error')
      page.should have_css('fieldset#school-support-team span.ui-error')
      page.should have_css('fieldset#server-url span.ui-error')
      page.should have_css('fieldset#server-name span.ui-error')
      page.should have_css('fieldset#web-server-name span.ui-error')
    end

    within('form#edit_server_config_1') do
      fill_in('support_email', with: 'trackersupport2@21pstem.org')
      fill_in('support_team', with: 'Tracker Support Team2')
      fill_in('school_support_team', with: 'School IT Support Team2')
      fill_in('server_url', with: 'https://21pstem.org')
      fill_in('server_name', with: 'Tracker System2')
      fill_in('web_server_name', with: 'PARLO Tracker Web Server2')
      find('button', text: 'Save').click
    end

    page.should have_css('h2 strong', text: 'View Server Configuration')
    within('div#server-config') do
      page.should have_css('span#support-email', text: 'trackersupport2@21pstem.org')
      page.should have_css('span#support-team', text: 'Tracker Support Team2')
      page.should have_css('span#school-support-team', text: 'School IT Support Team2')
      page.should have_css('span#server-url', text: 'https://21pstem.org')
      page.should have_css('span#server-name', text: 'Tracker System2')
      page.should have_css('span#web-server-name', text: 'PARLO Tracker Web Server2')
    end

  end # can_maintain_server_config

end
