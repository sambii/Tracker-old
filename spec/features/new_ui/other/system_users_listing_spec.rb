# system_users_listing_spec.rb
require 'spec_helper'


describe "System Users Listing", js:true do
  before (:each) do
    create_and_load_arabic_model_school

    @school = FactoryGirl.create :school, :arabic
    @teacher = FactoryGirl.create :teacher, school: @school
    @teacher_deact = FactoryGirl.create :teacher, school: @school, active: false
    @subject = FactoryGirl.create :subject, school: @school, subject_manager: @teacher
    @section = FactoryGirl.create :section, subject: @subject
    @discipline = @subject.discipline
    load_test_section(@section, @teacher)

    @school_administrator = FactoryGirl.create :school_administrator, school: @school
    @researcher = FactoryGirl.create :researcher
    @system_administrator = FactoryGirl.create :system_administrator

  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
      @home_page = "/teachers/#{@teacher.id}"
    end
    it { has_no_system_users_listing }
  end

  describe "as school administrator" do
    before do
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { has_no_system_users_listing }
  end

  describe "as researcher" do
    before do
      sign_in(@researcher)
      set_users_school(@school)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { has_no_system_users_listing }
  end

  describe "as system administrator" do
    before do
      sign_in(@system_administrator)
      set_users_school(@school)
      @home_page = "/system_administrators/#{@system_administrator.id}"
   end
    it { has_valid_system_users_listing }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { has_no_system_users_listing }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { has_no_system_users_listing }
  end


  ##################################################
  # test methods


  def has_no_system_users_listing
    # should not have a active toolkit item for System Users Listing.
    page.should_not have_css("#side-sys-users")
    page.should_not have_css("a[href='/system_administrators/system_users']")
    # try to go directly to page
    visit system_maintenance_system_administrators_path
    assert_equal(current_path, @home_page)
  end # has_no_system_users_listing

  def has_valid_system_users_listing
    # should have an active toolkit item for System Users Listing.
    within("#side-sys-users") do
      find("a[href='/system_administrators/system_users']").click
    end
    assert_not_equal(current_path, @home_page)
    assert_equal('/system_administrators/system_users', current_path)

    within("#page-content h2") do
      page.should have_content('System Users Listing')
    end

    system_users = page.all("#system-users tr.user-list-item")
    system_users.length.should == 2

    # make sure only correct users are listed
    # create an array of ids of system users from returned page elements
    sys_user_ids = Array.new
    sys_user_ids << system_users[0][:id].split('_')[1]
    sys_user_ids << system_users[1][:id].split('_')[1]
    # confirm each user is properly included or not included in the listed users
    sys_user_ids.should include(@researcher.id.to_s)
    sys_user_ids.should include(@system_administrator.id.to_s)
    sys_user_ids.should_not include(@teacher.id.to_s)
    sys_user_ids.should_not include(@teacher_deact.id.to_s)
    sys_user_ids.should_not include(@school_administrator.id.to_s)
    sys_user_ids.should_not include(@student.id.to_s)
    sys_user_ids.should_not include(@student.parent.id.to_s)

    ##############################
    # add a new system user

    # count current number of email messages in test array
    start_email_count = ActionMailer::Base.deliveries.count

    find("#page-content a#add-system-user").click
    within('#modal_popup #modal_content #modal-body') do
      within('h2') do
        page.should have_content('Add System User')
      end
      within('form#new_user') do
        # submit blank form to check for errors
        find('#btn-save').click
      end
    end
    within('#modal_popup #modal_content #modal-body') do
      # should remain in dialog box with errors
      within('h2') do
        page.should have_content('Add System User')
      end
      within('form#new_user') do
        within('div.ui-error') do
          page.should have_content('Role is required')
        end
        within('#given-name-field') do
          page.should have_content('Given/First Name is required')
        end
        within('#family-name-field') do
          page.should have_content('Family/Last Name is required')
        end
        within('#email-field') do
          page.should have_content('Email is required')
        end
        choose('sys-admin')
        fill_in('staff_first_name', with: 'Added')
        fill_in('staff_last_name', with: 'System User')
        fill_in('staff_email', with: 'testing@sample.com')
        find('#btn-save').click
      end
    end

    assert_equal('/system_administrators/system_users', current_path)

    within("#page-content h2") do
      page.should have_content('System Users Listing')
    end

    updated_system_users = page.all("#system-users tr.user-list-item")
    updated_system_users.length.should == 3

    # confirm email message was sent
    assert_equal(start_email_count + 1, ActionMailer::Base.deliveries.count)


    ##############################
    # get the newly added system user by comparing the difference between listings

    new_system_user_id = ''
    updated_system_users.each do |su|
      su_id = su[:id].split('_')[1]
      if !sys_user_ids.include?(su_id)
        # new user id - save id
        new_system_user_id = su_id
        break
      end
    end
    assert_not_equal('', new_system_user_id)
    

    ##############################
    # edit the newly created system user

    within("tr#user_#{new_system_user_id}") do
      find("a[data-url='/system_administrators/#{new_system_user_id}/edit_system_user']").click
    end

    within('#modal_popup #modal_content #modal-body') do
      # edit dialog box should pop up
      within('h2') do
        page.should have_content('Edit System User')
      end
      within("form#edit_user_#{new_system_user_id}.edit_user") do
        page.has_checked_field?('researcher').should be_false
        page.has_checked_field?('sys-admin').should be_true
        page.should have_css("input#staff_first_name", value: 'Added')
        page.should have_css("input#staff_last_name", value: 'System User')
        page.should have_css("input#staff_email", value: 'testing@sample.com')
        page.choose('researcher')
        page.fill_in('staff_first_name', with: 'Changed')
        page.fill_in('staff_last_name', with: 'To Researcher')
        page.fill_in('staff_email', with: 'testingr@sample.com')
        page.fill_in('staff_street_address', with: '1 Main St.')
        page.fill_in('staff_city', with: 'Anytown')
        page.fill_in('staff_state', with: 'Anystate')
        page.fill_in('staff_zip_code', with: '12345')
        find('#btn-save').click
      end
    end


    ##############################
    # view the updated system user
    within("tr#user_#{new_system_user_id}") do
      find("a[data-url='/users/#{new_system_user_id}.js']").click
    end

    within('#modal_popup #modal_content #modal-body') do
      # view/show dialog box should pop up
      within('h2') do
        page.should have_content('View Staff')
      end
      within(".page-form") do
        page.should have_content('researcher')
        page.should have_content('Changed')
        page.should have_content('To Researcher')
        page.should have_content('testingr@sample.com')
        page.should have_content('1 Main St.')
        page.should have_content('Anytown')
        page.should have_content('Anystate')
        page.should have_content('12345')
        # find("button").click
      end
    end


    ##############################
    # deactivate the system user
    visit system_users_system_administrators_path
    assert_equal('/system_administrators/system_users', current_path)

    page.should_not have_css("tr#user_#{new_system_user_id}.deactivated")

    within("tr#user_#{new_system_user_id}") do
      find("a#remove-staff").click
    end
    # click OK in javascript confirmation popup
    page.driver.browser.switch_to.alert.accept
    page.should have_css("tr#user_#{new_system_user_id}.deactivated")


    ##############################
    # reactivate the system user
    visit system_users_system_administrators_path
    assert_equal('/system_administrators/system_users', current_path)

    page.should have_css("tr#user_#{new_system_user_id}.deactivated")

    within("tr#user_#{new_system_user_id}") do
      find("a#restore-staff").click
    end
    # click OK in javascript confirmation popup
    page.driver.browser.switch_to.alert.accept
    page.should_not have_css("tr#user_#{new_system_user_id}.deactivated")

  end # def has_valid_system_users_listing

end
