# student_dashboard_spec.rb
require 'spec_helper'


describe "Student Dashboard", js:true do
  before (:each) do
    @section = FactoryGirl.create :section
    @teacher = FactoryGirl.create :teacher, school: @section.school

    # load_multi_schools_sections # see load_section_helper.rb
    load_test_section(@section, @teacher)
  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
      @current_role = 'teacher'
    end
    it { role_display_is_valid }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @section.school
      sign_in(@school_administrator)
      @current_role = 'school_administrator'
    end
    it { role_display_is_valid }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      @current_role = 'researcher'
      set_users_school(@section.school)
    end
    it { role_display_is_valid }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      @current_role = 'system_administrator'
      set_users_school(@section.school)
    end
    it { role_display_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @current_role = 'student'
    end
    it { role_display_is_valid }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @current_role = 'parent'
    end
    it { role_display_is_valid }
  end

  describe "as school administrator & teacher" do
    before do
      @teacher.school_administrator = true
      @teacher.save
      sign_in(@teacher)
     # note role starts out as highest
      @current_role = 'school_administrator'
    end
    it { role_display_is_valid }
  end

  ##################################################
  # test methods

  def role_display_is_valid
    visit root_path()
    Rails.logger.debug("+++ @test_user.role_symbols.inspect: #{@test_user.role_symbols.inspect}")
    assert_equal("/#{@current_role.pluralize}/#{@test_user.id}", current_path)
    Rails.logger.debug("+++ @test_user.role_symbols.length: #{@test_user.role_symbols.length}")
    if @test_user.role_symbols.length > 1
      page.should have_css('li#side-role')
      within("li#side-role") do
        if @test_user.system_administrator?
          page.should have_content('System Administrator')
        else
          page.should_not have_content('System Administrator')
        end
        if @test_user.researcher?
          page.should have_content('Researcher')
        else
          page.should_not have_content('Researcher')
        end
        if @test_user.school_administrator?
          page.should have_content('School Administrator')
        else
          page.should_not have_content('School Administrator')
        end
        if @test_user.teacher?
          page.should have_content('Teacher')
        else
          page.should_not have_content('Teacher')
        end
        if @test_user.counselor?
          page.should have_content('Counselor')
        else
          page.should_not have_content('Counselor')
        end
        if @test_user.student?
          page.should have_content('Student')
        else
          page.should_not have_content('Student')
        end
      end
    else
      page.should_not have_css('li#side-role')
    end
    Rails.logger.debug("+++ @test_user.teacher? #{@test_user.teacher?}")
    if @test_user.teacher?
      Rails.logger.debug("+++ @teaching_assignment.inspect: #{@teaching_assignment.inspect}")
      page.should have_css('li#side-current')
      within ('li#side-current') do
        page.should have_css('a.sidebar-nav-menu')
        page.should_not have_css('a.sidebar-nav-menu.disabled')
        page.should have_content("#{@teaching_assignment.section.name} - #{@teaching_assignment.section.line_number}")
      end
      page.should have_css('li#side-past')
      within ('li#side-past') do
        page.should have_css('a.sidebar-nav-menu')
        # this is only valid if there are any past sections - not yet in test data
        # page.should_not have_css('a.sidebar-nav-menu.disabled')
      end
    elsif @test_user.staff?
      page.should have_css('li#side-current')
      within ('li#side-current') do
        page.should have_css('a.sidebar-nav-menu.disabled')
      end
    end

  end

end
