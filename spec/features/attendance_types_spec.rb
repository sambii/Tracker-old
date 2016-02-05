require 'spec_helper'

describe "AttendanceTypeMaintenance" do
  before (:each) do
    @attendance_type1 = create :attendance_type
    @school = @attendance_type1.school
  end

  context 'should let sys admins maintain attendance_types' do
    before do 
      sys = create :system_administrator
      sign_in sys
      set_users_school(@school)
    end
    it { confirm_can_maintain_attendance_types }
  end

  context 'should let school admins maintain attendance_types' do
    before do
      sa = create :school_administrator, school: @school
      sign_in sa
    end
    it { confirm_can_maintain_attendance_types }
  end

  context "should not let teachers maintain attendance_type records" do
    before do
      @teacher = create :teacher, school: @school
      sign_in @teacher
    end
    it { confirm_cannot_maintain_attendance_types @teacher }
  end

  context "should not let students maintain attendance_type records" do
    before do
      @student = create :student, school: @school
      sign_in @student
    end
    it { confirm_cannot_see_attendance_types @student }
  end

  context "should not let parents maintain attendance_type records" do
    before do
      student = create :student, school: @school
      @parent = get_student_parent student, 'password'
      sign_in @parent
    end
    it { confirm_cannot_see_attendance_types(@parent) }
  end

  context "should not let researchers maintain attendance_type records" do
    before do
      @researcher = create :researcher
      sign_in @researcher
      set_users_school(@school)
    end
    it { confirm_cannot_maintain_attendance_types(@researcher) }
  end

  pending "test for deactivated tests"

  # find the parent record for a student, and set the password so we can login to it
  def get_student_parent(student, new_password)
    parent = student.parent
    parent.reset_password!(new_password, new_password)
    parent.temporary_password = nil
    parent.save
    return parent
  end

  def confirm_can_maintain_attendance_types
    visit new_attendance_type_path
    assert_match("/attendance_types/new", current_path)
    within('#new_attendance_type') do
      page.fill_in 'attendance_type_description', :with => 'NewDescription'
      page.has_checked_field?('attendance_type_active_false').should be_false
      page.has_checked_field?('attendance_type_active_true').should be_true
      page.click_button('Save')
    end
    #
    # confirm new attendance_type got created took place
    new_attendance_type = AttendanceType.find_by_description('NewDescription')
    current_path.should == attendance_types_path
    page.should have_css("#attendance_type_#{new_attendance_type.id}")
    within("#attendance_type_#{new_attendance_type.id.to_s}") do
      page.should have_content('NewDescription')
      page.should have_link(I18n.translate('action_titles.edit'))
      page.should_not have_selector("td.deactivated")
    end
    #
    # should list attendance_type
    
    page.should have_selector("#attendance_type_#{@attendance_type1.id.to_s}")
    within("#attendance_type_#{@attendance_type1.id.to_s}") do
      page.should have_content(@attendance_type1.description)
    end
    
    #
    # should be able to Edit an attendance_type
    within("#attendance_type_#{@attendance_type1.id.to_s}") do
      find_link(I18n.translate('action_titles.edit')).click
    end
    assert_match("/attendance_types/#{@attendance_type1.id.to_s}/edit", current_path)
    within('#edit_attendance_type_1') do
      find("#attendance_type_description").value.should have_content(@attendance_type1.description)
      page.fill_in 'attendance_type_description', :with => 'ChangedDescription'
      page.has_checked_field?('attendance_type_active_false').should be_false
      page.has_checked_field?('attendance_type_active_true').should be_true
      page.choose('attendance_type_active_false')
      page.has_checked_field?('attendance_type_active_false').should be_true
      page.has_checked_field?('attendance_type_active_true').should be_false
      page.click_button('Save')
    end
    #
    # confirm update took place
    att_type = AttendanceType.find(@attendance_type1.id)
    current_path.should == attendance_types_path
    page.should have_selector("#attendance_type_#{@attendance_type1.id.to_s}")
    within("#attendance_type_#{@attendance_type1.id.to_s}") do
      page.should have_content('ChangedDescription')
      page.should have_selector("td.deactivated")
    end
  end # end confirm_can_maintain

  def confirm_cannot_maintain_attendance_types(test_user)
    visit attendance_types_path
    current_path.should == attendance_types_path
    page.should have_selector("#attendance_type_#{@attendance_type1.id.to_s}")
    within("#attendance_type_#{@attendance_type1.id.to_s}") do
      page.should have_content(@attendance_type1.description)
      page.should_not have_link(I18n.translate('action_titles.edit'))
    end
    page.should_not have_link(I18n.translate('action_titles.create'))
    visit new_attendance_type_path
    current_path.should_not == new_attendance_type_path
    current_path.should == user_path(test_user)
    visit edit_attendance_type_path(test_user.id)
    current_path.should_not == edit_attendance_type_path(test_user.id)
    # user_path(test_user).should == current_path
  end # end confirm_cannot_maintain_attendance_types

  def confirm_cannot_see_attendance_types(test_user)
    visit attendance_types_path
    current_path.should_not == attendance_types_path
    visit new_attendance_type_path
    current_path.should_not == new_attendance_type_path
    visit edit_attendance_type_path(test_user.id)
    current_path.should_not == edit_attendance_type_path(test_user.id)
  end # end confirm_cannot_see_attendance_types

end

