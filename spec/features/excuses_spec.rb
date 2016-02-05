require 'spec_helper'

describe "ExcuseMaintenance" do
  before (:each) do
    @school = create :school
    @excuse1 = create :excuse, school: @school
    @excuses = create_list :excuse, 2, school: @school
  end

  context 'should let sys admins maintain excuses' do
    before do
      sys_admin = create :system_administrator
      sign_in(sys_admin)
      set_users_school(@school)
    end
    it { confirm_can_maintain_excuses }
  end

  context 'should let school admins maintain excuses' do
    before do
      school_admin = create :school_administrator, school: @school
      sign_in(school_admin)
    end
    it { confirm_can_maintain_excuses }
  end

  context "should not let teachers maintain excuse records" do
    before do
      @teacher = create :teacher, school: @school
      sign_in @teacher
    end
    it { confirm_cannot_maintain_excuses @teacher }
  end

  context "should not let students maintain excuse records" do
    before do
      @student = create :student, school: @school
      sign_in @student
    end
    it { confirm_cannot_see_excuses @student }
  end

  context "should not let parents maintain excuse records" do
    before do
      student = create :student, school: @school
      @parent = get_student_parent student, 'password'
      sign_in @parent
    end
    it { confirm_cannot_see_excuses @parent }
  end

  context "should not let researchers maintain excuse records" do
    before do
      @researcher = create :researcher
      sign_in @researcher
      set_users_school @school
    end
    it { confirm_cannot_maintain_excuses @researcher }
  end

  pending "should not allow duplicate descriptions per school"

  # find the parent record for a student, and set the password so we can login to it
  def get_student_parent(student, new_password)
    parent = Parent.find_by_username(student.username+'_p')
    parent.reset_password!(new_password, new_password)
    parent.temporary_password = nil
    parent.save
    return parent
  end

  def confirm_can_maintain_excuses
    visit new_excuse_path
    assert_match("/excuses/new", current_path)
    within('#new_excuse') do
      page.fill_in 'excuse_code', :with => 'NewCode'
      page.fill_in 'excuse_description', :with => 'NewDescription'
      page.has_checked_field?('excuse_active_false').should be_false
      page.has_checked_field?('excuse_active_true').should be_true
      page.click_button('Save')
    end
    #
    # confirm new excuse got created took place
    new_excuse = Excuse.find_by_code('NewCode')
    excuses_path.should == current_path
    page.should have_selector("#excuse_#{new_excuse.id.to_s}")
    within("#excuse_#{new_excuse.id.to_s}") do
      page.should have_content('NewCode')
      page.should have_content('NewDescription')
      page.should_not have_selector("td.deactivated")
    end
    #
    # should list all excuses
    @excuses.each do |e|
      page.should have_selector("#excuse_#{e.id.to_s}")
      within("#excuse_#{e.id.to_s}") do
        page.should have_content(e.code)
        page.should have_content(e.description)
      end
    end
    #
    # should be able to Edit an excuse
    within("#excuse_#{@excuse1.id.to_s}") do
      find_link('Edit').click
    end
    assert_match("/excuses/#{@excuse1.id.to_s}/edit", current_path)
    within('#edit_excuse_1') do
      find("#excuse_code").value.should have_content(@excuse1.code)
      page.fill_in 'excuse_code', :with => 'ChangedCode'
      find("#excuse_description").value.should have_content(@excuse1.description)
      page.fill_in 'excuse_description', :with => 'ChangedDescription'
      page.has_checked_field?('excuse_active_false').should be_false
      page.has_checked_field?('excuse_active_true').should be_true
      page.choose('excuse_active_false')
      page.has_checked_field?('excuse_active_false').should be_true
      page.has_checked_field?('excuse_active_true').should be_false
      page.click_button('Save')
    end
    #
    # confirm update took place
    excuses_path.should == current_path
    page.should have_selector("#excuse_#{@excuse1.id.to_s}")
    within("#excuse_#{@excuse1.id.to_s}") do
      page.should have_content('ChangedCode')
      page.should have_content('ChangedDescription')
      page.should have_selector("td.deactivated")
    end
  end # end confirm_can_maintain

  def confirm_cannot_maintain_excuses(test_user)
    visit excuses_path
    user_path(test_user).should_not == current_path
    excuses_path.should == current_path
    page.should have_selector("#excuse_#{@excuse1.id.to_s}")
    within("#excuse_#{@excuse1.id.to_s}") do
      page.should have_content(@excuse1.description)
      page.should_not have_link(I18n.translate('action_titles.edit'))
    end
    page.should_not have_link(I18n.translate('action_titles.create'))
    visit new_excuse_path
    new_excuse_path.should_not == current_path
    user_path(test_user).should == current_path
    visit edit_excuse_path(1)
    edit_excuse_path(1).should_not == current_path
    # user_path(test_user).should == current_path
  end # end confirm_cannot_maintain

  def confirm_cannot_see_excuses(test_user)
    visit excuses_path
    current_path.should_not == excuses_path
    visit new_excuse_path
    current_path.should_not == new_excuse_path
    visit edit_excuse_path(test_user.id)
    current_path.should_not == edit_excuse_path(test_user.id)
  end # end confirm_cannot_see

end

