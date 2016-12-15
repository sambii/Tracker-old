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
  end

  describe "as teacher" do
    before do
      @teacher1.temporary_password='temporary'
      @teacher1.save
      sign_in(@teacher1)
      @username = @teacher1.username
      @err_page = "/teachers/#{@teacher1.id}"
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
      @err_page = "/school_administrators/#{@school_administrator.id}"
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
      @err_page = "/researchers/#{@researcher.id}"
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
      @err_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { can_login_first_time_and_reset_pwd(@system_administrator, true, true) }
  end

  describe "as student" do
    before do
      @student.temporary_password='temporary'
      @student.save
      sign_in(@student)
      @username = @student.username
      @err_page = "/students/#{@student.id}"
    end
    it { can_login_first_time_and_reset_pwd(@student, false, false) }
  end

  describe "as parent" do
    before do
      @student.parent.temporary_password='temporary'
      @student.parent.save
      sign_in(@student.parent)
      @username = @student.parent.username
      @err_page = "/parents/#{@student.parent.id}"
    end
    it { can_login_first_time_and_reset_pwd(@student.parent, false, false) }
  end

  ##################################################
  # test methods

  def can_login_first_time_and_reset_pwd(user, edit_student=false, edit_staff=false)
    assert_equal("/users/#{user.id}/change_password", current_path)
    page.fill_in 'user_password', :with => 'newpassword'
    page.fill_in 'user_password_confirmation', :with => 'newpassword'
    page.find("input[name='commit']").click
    assert_equal("/", current_path)
    page.fill_in 'user_username', :with => @username
    page.fill_in 'user_password', :with => 'newpassword'
    find("input[name='commit']").click
    # save_and_open_page
    if edit_student
      # reset student's password after confirming screen is correct
      # confirm screen has changed with new temp password
      # student login with temp password
      # student login with updated password
      # reset parent's password after confirming screen is correct
      # confirm screen has changed with new temp password
      # parent login with temp password
      # parent login with updated password
    else
      # cannot get to security screen or update password for student
    end
    if edit_staff
      # reset teacher's password after confirming screen is correct
      # confirm screen has changed with new temp password
      # teacher login with temp password
      # teacher login with updated password
    else
      # cannot get to security screen or update password for staff
    end 
  end


end
