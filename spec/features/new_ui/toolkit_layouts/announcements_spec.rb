# announcements_spec.rb
require 'spec_helper'


describe "Announcements", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    # @school1
    @school1 = FactoryGirl.create :school_current_year, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    @discipline = @subject1.discipline
    load_test_section(@section1_1, @teacher1)

    @announcement1 = FactoryGirl.create :announcement
    @announcement2 = FactoryGirl.create :announcement
  end


  describe "as teacher" do
    before do
      sign_in(@teacher1)
      @home_page = "/teachers/#{@teacher1.id}"
    end
    it { has_valid_announcements(:teacher) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { has_valid_announcements(:school_administrator) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { has_valid_announcements(:researcher) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { has_valid_announcements(:system_administrator) }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { has_valid_announcements(:student) }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { has_valid_announcements(:parent) }
  end

  ##################################################
  # test methods

  def has_valid_announcements(role)

    # has first announcement in header
    within("#announcements #announcement_#{@announcement1.id}") do
      page.should have_content(@announcement1.content)
      within(".announcement-alert .hide-alert") do
        page.should have_css("a[href='/announcements/#{@announcement1.id}/hide']")
      end
    end
    # hide first announcement
    page.should have_css("#announcements #announcement_#{@announcement2.id}")
    within("#announcements #announcement_#{@announcement1.id} .announcement-alert .hide-alert") do
      page.find("a[href='/announcements/#{@announcement1.id}/hide']").click
    end
    # confirm javascript hid the first announcement
    page.should_not have_css("#announcements #announcement_#{@announcement1.id}")

    # hide second announcement
    within("#announcements #announcement_#{@announcement2.id} .announcement-alert .hide-alert") do
      page.find("a[href='/announcements/#{@announcement2.id}/hide']").click
    end
    # confirm javascript hid the second announcement
    page.should_not have_css("#announcements #announcement_#{@announcement2.id}")

    # confirm the highlighted announcements block is no longer showing
    page.should_not have_css("#announcements")

    # confirm first announcement is hidden on page refresh (by cookie)
    page.should_not have_css("#announcements #announcement_#{@announcement1.id}")

    if role == :system_administrator
      page.should_not have_css("#announcements")
      find("#announcements-admin a[href='/announcements']").click
      assert_equal(current_path, '/announcements')

      announcements = page.all("#announcements tr")
      announcements.length.should == 2

      # add another announcement
      find("a#show-add[data-url='/announcements/new.js']").click
      fill_in("announcement_content", with: 'This is a new Announcement!')
      find("#modal_popup form#new_announcement input[type='submit']").click

      # confirm at announcements page with the new announcement listed
      assert_equal(current_path, '/announcements')
      announcements = page.all("#announcements tr")
      announcements.length.should == 3

      # get id of new announcement from returned announcement elements
      announcement_id = announcements[2][:id].split('_')[1]

      # edit new announcement
      within("#announcements tr#announcement_#{announcement_id}") do
        find("a[data-target='#modal_popup']").click
      end

      # confirm on edit page
      page.should have_content('System Alert Message')
      fill_in("announcement_content", with: 'This is a changed Announcement!')
      find("#modal_popup form#edit_announcement_#{announcement_id} input[type='submit']").click

      #remove changed announcement from list of announcements
      assert_equal(current_path, '/announcements')
      within("#announcements") do
        page.should have_content('This is a changed Announcement!')
        within(announcements[2]) do
          find('a#delete-item').click
        end
      end
      # click OK in javascript confirmation popup
      page.driver.browser.switch_to.alert.accept

      # confirm at announcements page without the new announcement listed
      assert_equal(current_path, '/announcements')
      announcements = page.all("#announcements tr")
      announcements.length.should == 2

      # confirm new announcement is no longer in the alert box at the top of the page
      within("#announcements") do
        page.should_not have_content('This is a new Announcement!')
      end

    else
      page.should_not have_css("#announcements-admin")
      page.should_not have_css("a[href='/announcements']")
    end


  end # has_valid_announcements

end
