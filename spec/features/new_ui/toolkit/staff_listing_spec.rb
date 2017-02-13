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
    it { has_valid_staff_listing(false, false) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school
      sign_in(@school_administrator)
    end
    it { has_valid_staff_listing(true, true) }
  end

  describe "as counselor" do
    before do
      @counselor = FactoryGirl.create :counselor, school: @school
      sign_in(@counselor)
    end
    it { has_valid_staff_listing(false, true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school)
    end
    it { has_valid_staff_listing(false, true) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school)
    end
    it { has_valid_staff_listing(true, true) }
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

  def has_valid_staff_listing(can_create, can_see_sections)
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

    # all can see listing can see any teacher's dashboard
    within("#page-content") do
      within("tr#user_#{@teacher.id}") do
        page.should have_css("a[href='/users/#{@teacher.id}'] i.fa-dashboard")
        page.find("a[href='/users/#{@teacher.id}']").click
      end
    end
    # note will get redirected to primary role for user, in this case is teacher
    assert_equal("/teachers/#{@teacher.id}", current_path)
    page.should have_content("Teacher: #{@teacher.full_name}")


    # teachers can see section listing or tracker pages that are their own
    # all others who can see staff listing see them anyway
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
    # all others who can see staff listing see them anyway
    visit staff_listing_users_path
    assert_equal("/users/staff_listing", current_path)
    within("#page-content") do
      within("tr#user_#{@teacher_deact.id}") do
        if can_see_sections
          page.should have_css("a[href='/users/#{@teacher_deact.id}/sections_listing'] i.fa-check")
          page.find("a[href='/users/#{@teacher_deact.id}/sections_list']").click
        else # teacher cannot see other teachers section listing
          page.should_not have_css("a[href='/users/#{@teacher_deact.id}/sections_list'] i.fa-check")
        end
      end
    end
    if can_see_sections
      # note will get redirected to primary role for user, in this case is teacher
      assert_equal("/teachers/#{@teacher.id}/staff_listing", current_path)
      page.should have_content("All Sections for staff member: #{@teacher.full_name}")
      within("#section_#{@section.id}") do
        page.should have_css("a[href='/sections/#{@section.id}']")
      end
    end


    # teachers can see the user information for themselves
    # all others who can see staff listing can see all staff user information
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


    # teachers cannot see other user's information (except what is on the listing)
    # all others who can see staff listing can see all user's information
    # visit staff_listing_users_path
    assert_equal("/users/staff_listing", current_path)
    within("#page-content") do
      within("tr#user_#{@teacher_deact.id}") do
        if can_see_sections
          page.should have_css("i.fa-ellipsis-h")
          page.should have_css("a[data-url='/users/#{@teacher_deact.id}.js'] i.fa-ellipsis-h")
          page.find("a[data-url='/users/#{@teacher_deact.id}.js']").click
        else # teacher cannot see other teachers section listing
          page.should_not have_css("i.fa-ellipsis-h")
          page.should_not have_css("a[data-url='/users/#{@teacher_deact.id}.js'] i.fa-ellipsis-h")
        end
      end
    end
    if can_see_sections
      within("#modal_popup") do
        page.should have_content('View Staff')
      page.should have_content(@teacher_deact.first_name)
      page.should have_content(@teacher_deact.last_name)
        page.should have_css("button", text: 'Cancel')
        find("button", text: 'Cancel').click
      end
    end


    # all who can see staff listing see page view
    visit staff_listing_users_path
    assert_equal("/users/staff_listing", current_path)
    within("#page-content") do
      within("tr#user_#{@teacher.id}") do
        page.should have_css("i.fa-edit") if can_create
        page.should_not have_css("i.fa-edit") if !can_create
        page.should have_css("i.fa-unlock") if can_create
        page.should_not have_css("i.fa-unlock") if !can_create
      end

      # teachers and counselors cannot do this
      #########################
      # Deactivate the regular teacher
      within("tr#user_#{@teacher.id}") do
        # click the deactivate icon
        if can_create
          find('#remove-staff').click
          page.driver.browser.switch_to.alert.accept
        end
      end

      # teachers and counselors cannot do this
      #########################
      # confirm the teacher is deactivated
      if can_create
        page.should have_css("tr#user_#{@teacher.id}.deactivated")
        page.should_not have_css("tr#user_#{@teacher.id}.active")
      end

      # teachers and counselors cannot do this
      #########################
      # reactivate the originally deactivated teacher
      page.should have_css("tr#user_#{@teacher_deact.id}")
      page.should have_css("tr#user_#{@teacher_deact.id}.deactivated")
      page.should_not have_css("tr#user_#{@teacher_deact.id}.active")
      within("tr#user_#{@teacher_deact.id}") do
        page.should have_content("#{@teacher_deact.last_name}")
        page.should have_content("#{@teacher_deact.first_name}")
        page.should have_content("#{@teacher_deact.email}")
        page.should have_css("i.fa-undo") if can_create && @teacher_deact.active == false
        page.should_not have_css("i.fa-undo") if !can_create && @teacher_deact.active == false
      end
      # click the reactivate icon
      within("tr#user_#{@teacher_deact.id}") do
        if can_create
          find('#restore-staff').click
          page.driver.browser.switch_to.alert.accept
        end
      end
      # confirm the user is deactivated
      if can_create
        page.should have_css("tr#user_#{@teacher_deact.id}.active")
        page.should_not have_css("tr#user_#{@teacher_deact.id}.deactivated")
      end

    end # within("#page-content") do


    #########################
    # ensure that only the school admin, teacher and counselor roles display to admins in edit form
    # to do - full add, edit and deactivate tests (if not done elsewhere)
    if can_create # (system admins and school admins)
      within("#page-content") do
        within("tr#user_#{@teacher.id}") do
          page.should have_content("#{@teacher.last_name}")
          page.should have_content("#{@teacher.first_name}")
          page.should have_content("#{@teacher.email}")
          page.should have_css("i.fa-edit")
          find("a[data-url='/users/#{@teacher.id}/edit.js']").click
        end
      end
      page.should have_content('Edit Staff')
      assert_equal(page.all("fieldset.role-field").count.should, 3)
      page.should have_css('fieldset#role-sch-admin')
      page.should have_css('fieldset#role-teach')
      page.should have_css('fieldset#role-couns')

    else
      page.should_not have_css("i.fa-edit")
    end


  end # def has_valid_subjects_listing


end
