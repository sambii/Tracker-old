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
    end
    it { can_login_first_time(@teacher1) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      @school_administrator.temporary_password='temporary'
      @school_administrator.save
      sign_in(@school_administrator)
    end
    it { can_login_first_time(@school_administrator) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      @researcher.temporary_password='temporary'
      @researcher.save
      sign_in(@researcher)
      # set_users_school(@school1)
    end
    it { can_login_first_time(@researcher) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      @system_administrator.temporary_password='temporary'
      @system_administrator.save
      sign_in(@system_administrator)
      # set_users_school(@school1)
    end
    it { can_login_first_time(@system_administrator) }
  end

  describe "as student" do
    before do
      @student.temporary_password='temporary'
      @student.save
      sign_in(@student)
    end
    it { can_login_first_time(@student) }
  end

  describe "as parent" do
    before do
      @student.parent.temporary_password='temporary'
      @student.parent.save
      sign_in(@student.parent)
    end
    it { can_login_first_time(@student.parent) }
  end

  ##################################################
  # test methods

  def can_login_first_time(user)
    assert_equal("/users/#{user.id}/change_password", current_path)
    page.fill_in 'user_password', :with => 'newpassword'
    page.fill_in 'user_password_confirmation', :with => 'newpassword'
    page.find("input[name='commit']").click
    assert_equal("/", current_path)
  end


end
