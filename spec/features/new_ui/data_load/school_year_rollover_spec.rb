# school_year_rollover_spec.rb
require 'spec_helper'


describe "Rollover School Year", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    # two subjects in @school1
    @school1 = FactoryGirl.create :school_current_year
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    # @section1_1 = FactoryGirl.create :section
    # @subject1 = @section1_1.subject
    # @school1 = @section1_1.school
    # @teacher1 = @subject1.subject_manager
    @discipline = @subject1.discipline

    load_test_section(@section1_1, @teacher1)

    @section1_2 = FactoryGirl.create :section, subject: @subject1
    ta1 = FactoryGirl.create :teaching_assignment, teacher: @teacher1, section: @section1_2
    @section1_3 = FactoryGirl.create :section, subject: @subject1
    ta2 = FactoryGirl.create :teaching_assignment, teacher: @teacher1, section: @section1_3

    @subject2 = FactoryGirl.create :subject, subject_manager: @teacher1
    @section2_1 = FactoryGirl.create :section, subject: @subject2
    @section2_2 = FactoryGirl.create :section, subject: @subject2
    @section2_3 = FactoryGirl.create :section, subject: @subject2
    @discipline2 = @subject2.discipline

    # @school2 is ready to be rolled over
    @school2 = FactoryGirl.create :school_prior_year
    @teacher2_1 = FactoryGirl.create :teacher, school: @school2
    @subject2_1 = FactoryGirl.create :subject, school: @school2, subject_manager: @teacher2_1
    @section2_1_1 = FactoryGirl.create :section, subject: @subject2_1
    @section2_1_2 = FactoryGirl.create :section, subject: @subject2_1
    @section2_1_3 = FactoryGirl.create :section, subject: @subject2_1

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
    end
    it { no_nav_to_schools_page }
    it { no_rollover_school_year(true, @school1) }
    it { no_rollover_model_school_year(true) }
  end

  describe "as school administrator 1" do
    before do
      @school_administrator1 = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator1)
    end
    it { no_nav_to_schools_page }
    it { no_rollover_school_year_yet(@school1) }
    it { no_rollover_model_school_year(true) }
  end

  describe "as school administrator 2" do
    before do
      @school_administrator2 = FactoryGirl.create :school_administrator, school: @school2
      sign_in(@school_administrator2)
    end
    it { no_nav_to_schools_page }
    it { rollover_school_year(@school2) }
    it { no_rollover_model_school_year(true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { nav_to_schools_page }
    it { no_rollover_school_year(true, @school1) }
    it { no_rollover_model_school_year(true) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { nav_to_schools_page }
    it { valid_sys_admin_school_listing(@school1, @school2) }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { no_nav_to_schools_page }
    it { no_rollover_school_year(false, @school1) }
    it { no_rollover_model_school_year(false) }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { no_nav_to_schools_page }
    it { no_rollover_school_year(false, @school1) }
    it { no_rollover_model_school_year(false) }
  end

  ##################################################
  # test methods

  def nav_to_schools_page
    page.should have_css("li#side-schools")
  end # nav_to_schools_page

  def no_nav_to_schools_page
    page.should_not have_css("li#side-schools")
  end # no_nav_to_schools_page

  def no_rollover_school_year(is_staff, school)
    visit schools_path()
    if is_staff
      assert_equal("/schools", current_path)
      page.should_not have_css("a[href='/schools/#{school.id}/new_year_rollover']")
    else
      assert_not_equal("/schools", current_path)
    end
    visit subjects_path()
    if is_staff
      assert_equal("/subjects", current_path)
      page.should_not have_css("a[href='/schools/#{school.id}/new_year_rollover']")
    else
      assert_not_equal("/subjects", current_path)
    end
  end # no_rollover_school_year

  def no_rollover_model_school_year(is_staff)
    visit schools_path()
    if is_staff
      assert_equal("/schools", current_path)
      page.should_not have_css("a[href='/schools/1/new_year_rollover']")
      page.should_not have_css("a[href='/subject_outcomes/upload_lo_file']")
    else
      assert_not_equal("/schools", current_path)
    end

    visit subjects_path()
    if is_staff
      assert_equal("/subjects", current_path)
      page.should_not have_css("a[href='/schools/1/new_year_rollover']")
    else
      assert_not_equal("/subjects", current_path)
    end
  end # no_rollover_model_school_year

  def no_rollover_school_year_yet(school)
    visit schools_path()
    assert_equal("/schools", current_path)
    page.should have_css("a[id='rollover-#{school.id}']")
    page.should have_css("a.dim[id='rollover-#{school.id}']")
    page.should_not have_css("a[href='/schools/#{school.id}/new_year_rollover']")

    visit subjects_path()
    assert_equal("/subjects", current_path)
    page.should have_css("a[id='rollover-#{school.id}']")
    page.should have_css("a.deactivated[id='rollover-#{school.id}']")
    page.should_not have_css("a[href='/schools/#{school.id}/new_year_rollover']")
  end # def no_rollover_school_year_yet

  def rollover_school_year(school)
    visit subjects_path()
    assert_equal("/subjects", current_path)
    page.should have_css("a[id='rollover-#{school.id}']")
    page.should_not have_css("a.deactivated[id='rollover-#{school.id}']")
    page.should have_css("a[href='/schools/#{school.id}/new_year_rollover']")

    visit schools_path()
    assert_equal("/schools", current_path)
    page.should have_css("a[id='rollover-#{school.id}']")
    page.should_not have_css("a.dim[id='rollover-#{school.id}']")
    page.should have_css("a[href='/schools/#{school.id}/new_year_rollover']")

    # confirm only one school (and hence school year) is listed
    page.all('td.school-year').count.should == 1

    valid_school_year_rollover(school)

  end # def rollover_school_year

  def valid_sys_admin_school_listing(school_no_rollover, school_rollover)
    visit schools_path()
    assert_equal("/schools", current_path)

    save_and_open_page

    # no rollover school is inactive
    page.should have_css("a[id='rollover-#{school_no_rollover.id}']")
    page.should have_css("a.dim[id='rollover-#{school_no_rollover.id}']")
    page.should_not have_css("a[href='/schools/#{school_no_rollover.id}/new_year_rollover']")

    # rollover school is active
    page.should have_css("a[id='rollover-#{school_rollover.id}']")
    page.should_not have_css("a.dim[id='rollover-#{school_rollover.id}']")
    page.should have_css("a[href='/schools/#{school_rollover.id}/new_year_rollover']")
    page.should have_css("a[id='rollover-1']")

    # model school should always be active
    page.should_not have_css("a.dim[id='rollover-1']")
    page.should have_css("a[href='/schools/1/new_year_rollover']")

    # bulk upload should be available
    page.should have_css("a[href='/subject_outcomes/upload_lo_file']")

    valid_school_year_rollover(school_rollover)

  end

  def valid_school_year_rollover(school)
    save_and_open_page

    # confirm on prior year
    within("tr#school-#{school.id} td.school-year") do
      page.should have_content(get_std_prior_school_year_name)
    end

    find("a[id='rollover-#{school.id}']").click
    # click OK in javascript confirmation popup
    page.driver.browser.switch_to.alert.accept
    save_and_open_page

    # confirm on next year
    within("tr#school-#{school.id} td.school-year") do
      page.should have_content(get_std_current_school_year_name)
    end
  end

end
