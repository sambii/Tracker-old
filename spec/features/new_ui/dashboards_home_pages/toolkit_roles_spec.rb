# student_dashboard_spec.rb
require 'spec_helper'


describe "Student Dashboard", js:true do
  before (:each) do
    @section = FactoryGirl.create :section
    @school = @section.school
    @teacher = FactoryGirl.create :teacher, school: @school

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
      @school_administrator = FactoryGirl.create :school_administrator, school: @school
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
      set_users_school(@school)
    end
    it { role_display_is_valid }
    it { researcher_toolkit_no_changes }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      @current_role = 'system_administrator'
      set_users_school(@school)
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
    it { role_display_is_valid(true) }
  end

  ##################################################
  # test methods

  def role_display_is_valid(dual_role=false)
    visit root_path()
    assert_equal("/#{@current_role.pluralize}/#{@test_user.id}", current_path)
    if @test_user.role_symbols.length > 1
      page.should have_css('li#side-role')
      within("li#side-role") do
        if @test_user.system_administrator?
          page.should have_content('Sys Admin')
        else
          page.should_not have_content('Sys Admin')
        end
        if @test_user.researcher?
          page.should have_content('Researcher')
        else
          page.should_not have_content('Researcher')
        end
        if @test_user.school_administrator?
          page.should have_content('School Admin')
        else
          page.should_not have_content('School Admin')
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
    if @test_user.teacher?
      if dual_role
        # open up list of available roles if needed
        if !find("#side-role a[href='/teachers/#{@teacher.id}?role=teacher']").visible?
          find("#side-role a.sidebar-nav-menu").click
        end
        # change role to teacher if school admin and teacher
        find("#side-role a[href='/teachers/#{@teacher.id}?role=teacher']").click
      end
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
  def researcher_toolkit_no_changes
    visit root_path()
    assert_equal("/#{@current_role.pluralize}/#{@test_user.id}", current_path)
    @test_user.role_symbols.length .should be 1
    page.should_not have_css('li#side-role')
    @test_user.researcher?.should be true
    page.should have_css('li#side-current a.disabled')
    page.should have_css('li#side-past a.disabled')
    page.should have_css('li#side-add-lo a.disabled')
    page.should have_css('li#side-add-evid a.disabled')
    page.should have_css('li#side-restore-evid a.disabled')
    page.should have_css('li#side-attend a.disabled')
    page.should have_css('li#side-attendance-maint a.disabled')
    page.should have_css('li#side-reports a')
    page.should_not have_css('li#side-reports a.disabled')
    page.should have_css('li#side-staff a')
    page.should_not have_css('li#side-staff a.disabled')
    page.should have_css('li#side-students a')
    page.should_not have_css('li#side-students a.disabled')
    page.should have_css('li#side-subjects a')
    page.should_not have_css('li#side-subjects a.disabled')
    page.should have_css('li#side-schools a')
    page.should_not have_css('li#side-schools a.disabled')
    page.should_not have_css('li#side-templates')
    visit section_path(@section.id)
    # confirm researcher does not see section maintenance items if in a section
    page.should have_css('li#side-add-lo a.disabled')
    page.should have_css('li#side-add-evid a.disabled')
    page.should have_css('li#side-restore-evid a.disabled')
    # confirm researcher cannot see link to enter attendance
    page.should have_css('li#side-attend a.disabled')

  end

end
