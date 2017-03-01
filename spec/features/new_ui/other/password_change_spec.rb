# password_change_spec.rb
require 'spec_helper'


describe "User can change password", js:true do
  before (:each) do
    create_and_load_arabic_model_school

    @school1 = FactoryGirl.create :school, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    @discipline = @subject1.discipline
    load_test_section(@section1_1, @teacher1)

    @student_no_email = FactoryGirl.create :student_no_email, school_id: @school1.id, first_name: 'Student', last_name: 'Has No Email'
  end

  describe "as teacher" do
    before do
      @teacher1.temporary_password='temporary'
      @teacher1.save
      sign_in(@teacher1)
      @username = @teacher1.username
      @home_page = "/teachers/#{@teacher1.id}"
    end
    it { can_login_first_time_and_reset_pwd(@teacher1, true, false) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      @school_administrator.temporary_password='temporary'
      @school_administrator.save
      sign_in(@school_administrator)
      @username = @school_administrator.username
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { can_login_first_time_and_reset_pwd(@school_administrator, true, true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      @researcher.temporary_password='temporary'
      @researcher.save
      sign_in(@researcher)
      # set_users_school(@school1)
      @username = @researcher.username
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { can_login_first_time_and_reset_pwd(@researcher, false, false) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      @system_administrator.temporary_password='temporary'
      @system_administrator.save
      sign_in(@system_administrator)
      # set_users_school(@school1)
      @username = @system_administrator.username
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { can_login_first_time_and_reset_pwd(@system_administrator, true, true) }
  end

  describe "as student" do
    before do
      @student.temporary_password='temporary'
      @student.save
      sign_in(@student)
      @username = @student.username
      @home_page = "/students/#{@student.id}"
    end
    it { can_login_first_time_and_reset_pwd(@student, false, false) }
  end

  describe "as parent" do
    before do
      @student.parent.temporary_password='temporary'
      @student.parent.save
      sign_in(@student.parent)
      @username = @student.parent.username
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { can_login_first_time_and_reset_pwd(@student.parent, false, false) }
  end

  ##################################################
  # test methods

  def can_login_first_time_and_reset_pwd(user, edit_student=false, edit_staff=false)
    # Note: user at change password page because there was a temporary password
    assert_equal("/users/#{user.id}/change_password", current_path)
    page.fill_in 'user_password', :with => 'newpassword'
    page.fill_in 'user_password_confirmation', :with => 'newpassword'
    page.find("input[name='commit']").click
    assert_equal("/", current_path)
    page.fill_in 'user_username', :with => @username
    page.fill_in 'user_password', :with => 'newpassword'
    find("input[name='commit']").click
    if edit_student
      # if user has to pick a school, pick it and go to home page
      if !user.school_id.present?
        find("#side-schools a[href='/schools']").click
        within("table tbody tr#school-#{@school1.id}") do
          find("a[href='/schools/#{@school1.id}']").click
        end
        visit @home_page
      end

      # reset student's password
      assert_equal(@home_page, current_path)
      within('#side-students') do
        find("a[href='/students']").click
      end
      assert_equal('/students', current_path)
      within("#student_#{@student.id}") do
        find("a[data-url='/students/#{@student.id}/security.js']").click
      end

      # confirm display of temporary password if there is one, and confirm the display of the reset password button
      within("#modal-body") do
        within("td#user_#{@student.parent.id}.parent-temp-pwd") do
          page.should have_css("span.temp-pwd")
          page.should have_css("a[href='/parents/#{@student.parent.id}/set_parent_temporary_password']")
        end
        within("td#user_#{@student.id}.student-temp-pwd") do
          page.should_not have_css("span.temp-pwd")
          find("a[href='/students/#{@student.id}/set_student_temporary_password']").click
        end
      end

      # confirm student now has a temporary password
      within("#modal-body") do
        # confirm screen has changed with new temp password
        within("td#user_#{@student.id}.student-temp-pwd") do
          within("span.temp-pwd") do
            page.should have_content("#{@student.temporary_password}")
          end
          page.should have_css("a[href='/students/#{@student.id}/set_student_temporary_password']")
        end
        # reset parent's password after confirming screen is correct
        within("td#user_#{@student.parent.id}.parent-temp-pwd") do
          page.should have_css("span.temp-pwd")
          find("a[href='/parents/#{@student.parent.id}/set_parent_temporary_password']").click
        end
      end

      within("#modal-body") do
        # confirm screen has changed with new temp password
        within("td#user_#{@student.parent.id}.parent-temp-pwd") do
          within("span.temp-pwd") do
            @student.parent.reload
            page.should have_content("#{@student.parent.temporary_password}")
          end
          page.should have_css("span.temp-pwd")
          page.should have_css("a[href='/parents/#{@student.parent.id}/set_parent_temporary_password']")
        end
      end

      # logout and back in as student, to confirm logging in with new password works correctly
      @student.reload
      student_email = @student.email

      page.find("#main-container header .dropdown-toggle").click
      page.find("#main-container header .dropdown-menu-right a[href='/users/sign_out']").click

      assert_equal("/", current_path)
      page.fill_in 'user_username', :with => @student.username
      page.fill_in 'user_password', :with => @student.temporary_password
      find("input[name='commit']").click

      page.fill_in 'user_password', :with => 'after_reset'
      page.fill_in 'user_password_confirmation', :with => 'after_reset'
      page.find("input[name='commit']").click

      page.fill_in 'user_username', :with => @student.username
      page.fill_in 'user_password', :with => 'after_reset'
      find("input[name='commit']").click

      assert_equal("/students/#{@student.id}", current_path)
      @student.reload
      assert_equal(student_email, @student.email)

      # log back in as user
      page.find("#main-container header .dropdown-toggle").click
      page.find("#main-container header .dropdown-menu-right a[href='/users/sign_out']").click
      page.fill_in 'user_username', :with => @username
      page.fill_in 'user_password', :with => 'newpassword'
      find("input[name='commit']").click

    else
      # cannot get to security screen or update password for student
    end

    if edit_staff
      # if user has to pick a school, pick it
      if !user.school_id.present?
        find("#side-schools a[href='/schools']").click
        within("table tbody tr#school-#{@school1.id}") do
          find("a[href='/schools/#{@school1.id}']").click
        end
      end

      # reset staff member's password
      within('#side-staff') do
        find("a[href='/users/staff_listing']").click
      end
      # orig_pwd = @teacher1.temporary_password
      assert_equal('/users/staff_listing', current_path)
      within("#user_#{@teacher1.id}") do
        find("a[data-url='/users/#{@teacher1.id}/security.js']").click
      end

      within("#modal-body") do
        within("td#user_#{@teacher1.id}") do
          page.should_not have_css("span.temp-pwd")
          find("a[href='/users/#{@teacher1.id}/set_temporary_password']").click
        end
      end

      within("#modal-body") do
        # confirm screen has changed with new temp password
        within("td#user_#{@teacher1.id}") do
          within("span.temp-pwd") do
            page.should have_content("#{@teacher1.temporary_password}")
          end
          page.should have_css("a[href='/users/#{@teacher1.id}/set_temporary_password']")
        end
      end

    else
      # cannot get to security screen or update password for staff
    end 
  end


end
