# staff_listing_spec.rb
require 'spec_helper'


describe "Staff Listing", js:true do
  before (:each) do
    create_and_load_arabic_model_school

    @school = FactoryGirl.create :school, :arabic
    @teacher = FactoryGirl.create :teacher, school: @school
    @teacher_deact = FactoryGirl.create :teacher, school: @school, active: false
    @subject = FactoryGirl.create :subject, school: @school, subject_manager: @teacher
    @section = FactoryGirl.create :section, subject: @subject
    @discipline = @subject.discipline
    load_test_section(@section, @teacher)


  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    it { has_valid_staff_listing(:teacher) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school
      sign_in(@school_administrator)
    end
    it { has_valid_staff_listing(:school_administrator) }
  end

  # to do - do this once toolkit and home page for counselor exists
  # describe "as counselor" do
  #   before do
  #     @counselor = FactoryGirl.create :counselor, school: @school
  #     sign_in(@counselor)
  #   end
  #   it { has_valid_staff_listing(:counselor) }
  # end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school)
    end
    it { has_valid_staff_listing(:researcher) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school)
    end
    it { has_valid_staff_listing(:system_administrator) }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { has_no_staff_listing }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { has_no_staff_listing }
  end

  ##################################################
  # test methods

  def has_no_staff_listing
    visit staff_listing_users_path
    assert_not_equal("/users/staff_listing", current_path)
  end

  def has_valid_staff_listing(role)
    visit staff_listing_users_path
    assert_equal("/users/staff_listing", current_path)
    within("#page-content") do
      page.should have_content("All Staff for #{@school.name}")
      page.should have_css("tr#user_#{@teacher.id}")
      page.should_not have_css("tr#user_#{@teacher.id}.deactivated")
      page.should have_css("tr#user_#{@teacher.id}.active")
      within("tr#user_#{@teacher.id}") do
        page.should have_content("#{@teacher.last_name}")
        page.should have_content("#{@teacher.first_name}")
        page.should have_content("#{@teacher.email}")
      end
    end

    ########################
    # Dashboard visiblity and availability testing
    # all who can see staff listing (teachers, admins, counselor, researcher) can see any teacher's dashboard
    within("#page-content") do
      within("tr#user_#{@teacher.id}") do
        page.should have_css("a[href='/users/#{@teacher.id}'] i.fa-dashboard")
        page.find("a[href='/users/#{@teacher.id}']").click
      end
    end
    # note will get redirected to primary role for user, in this case is teacher
    assert_equal("/teachers/#{@teacher.id}", current_path)
    page.should have_content("Teacher: #{@teacher.full_name}")


    ########################
    # Section Listing visiblity and availability testing
    # teachers can see section listing or tracker pages that are their own
    # all others who can see staff listing (admins, counselor, researcher) can see them
    visit staff_listing_users_path
    assert_equal("/users/staff_listing", current_path)
    within("#page-content") do
      within("tr#user_#{@teacher.id}") do
        page.should have_css("a[href='/users/#{@teacher.id}/sections_list'] i.fa-check")
        page.find("a[href='/users/#{@teacher.id}/sections_list']").click
      end
    end
    assert_equal("/users/#{@teacher.id}/sections_list", current_path)
    page.should have_content("All Sections for staff member: #{@teacher.full_name}")
    within("#section_#{@section.id}") do
      page.should have_css("a[href='/sections/#{@section.id}']")
    end
    # teachers cannot see section listing or tracker pages that are not their own
    if [:teacher].include?(role)
      visit staff_listing_users_path
      assert_equal("/users/staff_listing", current_path)
      within("#page-content") do
        within("tr#user_#{@teacher_deact.id}") do
          page.should_not have_css("a[href='/users/#{@teacher_deact.id}/sections_list'] i.fa-check")
        end
      end
    end


    ########################
    # View Staff Information visiblity and availability testing
    # teachers can see their own user information
    # all others who can see staff listing (admins, counselor, researcher) can see any user's information
    visit staff_listing_users_path
    assert_equal("/users/staff_listing", current_path)
    within("#page-content") do
      within("tr#user_#{@teacher.id}") do
        page.should have_css("i.fa-ellipsis-h")
        page.should have_css("a[data-url='/users/#{@teacher.id}.js'] i.fa-ellipsis-h")
        page.find("a[data-url='/users/#{@teacher.id}.js']").click
      end
    end
    within("#modal_popup") do
      page.should have_content('View Staff')
      page.should have_content(@teacher.first_name)
      page.should have_content(@teacher.last_name)
      page.should have_css("button", text: 'Cancel')
      find("button", text: 'Cancel').click
    end
    # teachers cannot see other user's information
    if [:teacher].include?(role)
      # visit staff_listing_users_path
      assert_equal("/users/staff_listing", current_path)
      within("#page-content") do
        within("tr#user_#{@teacher_deact.id}") do
          page.should_not have_css("i.fa-ellipsis-h")
          page.should_not have_css("a[data-url='/users/#{@teacher_deact.id}.js'] i.fa-ellipsis-h")
        end
      end
    end


    ########################
    # Edit Staff Information visiblity and availability testing
    # teachers can edit their own user information for themselves
    # admins can edit all staff user information
    # visit staff_listing_users_path
    if [:teacher, :school_administrator, :system_administrator].include?(role)
      assert_equal("/users/staff_listing", current_path)
      within("#page-content") do
        within("tr#user_#{@teacher.id}") do
          page.should have_css("i.fa-edit")
          page.should have_css("a[data-url='/users/#{@teacher.id}/edit.js'] i.fa-edit")
          page.find("a[data-url='/users/#{@teacher.id}/edit.js']").click
        end
      end
      within("#modal_popup") do
        page.should have_css("h2", text: 'Edit Staff')
        within("form#edit_user_#{@teacher.id}") do

          # ensure that only the admins can choose roles in edit form
          if [:school_administrator, :system_administrator].include?(role)
            assert_equal(page.all("fieldset.role-field").count.should, 3)
            page.should have_css('fieldset#role-sch-admin')
            page.should have_css('fieldset#role-teach')
            page.should have_css('fieldset#role-couns')
            # add counselor role to @teacher
            check('user[counselor]')
          else # teacher editing
            assert_equal(page.all("fieldset.role-field").count.should, 0)
            page.should_not have_css('fieldset#role-sch-admin')
            page.should_not have_css('fieldset#role-teach')
            page.should_not have_css('fieldset#role-couns')
          end

          page.should have_css('#staff_first_name', value: @teacher.first_name)
          page.should have_css('#staff_last_name', value: @teacher.last_name)
          page.fill_in 'staff_first_name', :with => 'Changed First Name'
          page.fill_in 'staff_last_name', :with => 'Changed Last Name'
          page.should have_css("button", text: 'Save')
          find("button", text: 'Save').click
        end
      end
      assert_equal("/users/staff_listing", current_path)
      within("#page-content table #user_#{@teacher.id}") do
        page.should have_css('.user-first-name', 'Changed First Name')
        page.should have_css('.user-last-name', 'Changed Last Name')
        within('.user-roles') do
          page.should have_content('teacher')
          if [:school_administrator, :system_administrator].include?(role)
            page.should have_content('counselor')
          else
            page.should_not have_content('counselor')
          end
        end
      end    
    end
    # teachers and counselors cannot edit other user's information
    # researchers cannot edit any user's information
    if [:teacher, :counselor, :researcher].include?(role)
      # visit staff_listing_users_path
      # assert_equal("/users/staff_listing", current_path)
      within("#page-content tr#user_#{@teacher_deact.id}") do
        page.should_not have_css("i.fa-edit")
        page.should_not have_css("a[data-url='/users/#{@teacher_deact.id}.js'] i.fa-edit")
      end
    end


    ########################
    # Staff Security Information visiblity and availability testing
    # Only admins can view and reset security information for staff
    # visit staff_listing_users_path
    if [:school_administrator, :system_administrator].include?(role)
      assert_equal("/users/staff_listing", current_path)
      within("#page-content tr#user_#{@teacher.id}") do
        page.should have_css("i.fa-unlock")
        page.should have_css("a[data-url='/users/#{@teacher.id}/security.js'] i.fa-unlock")
        page.find("a[data-url='/users/#{@teacher.id}/security.js']").click
      end
      within("#modal_popup") do
        page.should have_css("h2", text: 'Staff Security and Access')
        within("#modal-body table") do
          page.should have_content(@teacher.username)
        end
        page.find(".modal-footer button", text: 'Close').click
      end
      assert_equal("/users/staff_listing", current_path)
    else
      assert_equal("/users/staff_listing", current_path)
      within("#page-content") do
        within("tr#user_#{@teacher.id}") do
          page.should_not have_css("i.fa-unlock")
          page.should_not have_css("a[data-url='/users/#{@teacher.id}/security.js']")
        end
      end
    end


    #########################
    # only admins can deactivate or reactivate staff members
    if [:teacher, :counselor, :researcher].include?(role)
      visit staff_listing_users_path
      assert_equal("/users/staff_listing", current_path)
      within("#page-content tr#user_#{@teacher.id}") do
        page.should_not have_css("#remove-staff")
      end
    elsif [:school_administrator, :system_administrator].include?(role)
      visit staff_listing_users_path
      assert_equal("/users/staff_listing", current_path)
      within("#page-content tr#user_#{@teacher.id}") do
        # click the deactivate icon
        find('#remove-staff').click
        page.driver.browser.switch_to.alert.accept
      end
      # confirm the teacher is deactivated
      page.should have_css("tr#user_#{@teacher.id}.deactivated")
      page.should_not have_css("tr#user_#{@teacher.id}.active")
      # reactivate the originally deactivated teacher
      page.should have_css("tr#user_#{@teacher_deact.id}")
      page.should have_css("tr#user_#{@teacher_deact.id}.deactivated")
      page.should_not have_css("tr#user_#{@teacher_deact.id}.active")
      within("tr#user_#{@teacher_deact.id}") do
        page.should have_content("#{@teacher_deact.last_name}")
        page.should have_content("#{@teacher_deact.first_name}")
        page.should have_content("#{@teacher_deact.email}")
      end
      # click the reactivate icon
      within("tr#user_#{@teacher_deact.id}") do
        find('#restore-staff').click
        page.driver.browser.switch_to.alert.accept
      end
      # confirm the user is deactivated
      page.should have_css("tr#user_#{@teacher_deact.id}.active")
      page.should_not have_css("tr#user_#{@teacher_deact.id}.deactivated")
    else
      # no other roles should be tested here
      assert_equal(true, false)
    end # within("#page-content") do


    ########################
    # Add New Staff visiblity and availability testing
    # Only admins can create new staff
    # visit staff_listing_users_path
    assert_equal("/users/staff_listing", current_path)
    if [:school_administrator, :system_administrator].include?(role)
      within("#page-content #button-block") do
        page.should have_css("i.fa-plus-square")
        page.should have_css("a[data-url='/users/new/new_staff'] i.fa-plus-square")
        page.find("a[data-url='/users/new/new_staff']").click
      end
      within("#modal_popup") do
        page.should have_css("h2", text: 'Create Staff Member')
        page.find("form.new_user button", text: 'Cancel').click
      end
      assert_equal("/users/staff_listing", current_path)
    else
      within("#page-content #button-block") do
        page.should_not have_css("i.fa-plus-square")
        page.should_not have_css("a[data-url='/users/new/new_staff'] i.fa-plus-square")
      end
    end


  end # def has_valid_subjects_listing


end
