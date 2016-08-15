# school_listing_spec.rb
require 'spec_helper'


describe "School Listing", js:true do
  before (:each) do
    # @section = FactoryGirl.create :section
    # @school = @section.school
    # @teacher = FactoryGirl.create :teacher, school: @school
    # @teacher_deact = FactoryGirl.create :teacher, school: @school, active: false
    # load_test_section(@section, @teacher)

    create_and_load_arabic_model_school

    # @school1
    @school1 = FactoryGirl.create :school_current_year, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    @section1_2 = FactoryGirl.create :section, subject: @subject1
    @section1_3 = FactoryGirl.create :section, subject: @subject1
    @discipline = @subject1.discipline
    load_test_section(@section1_1, @teacher1)

    # @school2
    @school2 = FactoryGirl.create :school_prior_year, :arabic
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
    it { only_list_one_school }
    it { no_rollover_school_year }
    it { no_new_year_rollover }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { no_nav_to_schools_page }
    it { only_list_one_school }
    it { has_rollover_school_year }
    it { no_new_year_rollover }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { has_nav_to_schools_page }
    it { lists_all_schools(false) }
    it { no_rollover_school_year }
    it { no_new_year_rollover }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { has_nav_to_schools_page }
    it { lists_all_schools(true) }
    it { has_rollover_school_year }
    it { has_new_year_rollover }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { no_nav_to_schools_page }
    it { no_school_listing }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { no_nav_to_schools_page }
    it { no_school_listing }
  end

  ##################################################
  # test methods

  def has_nav_to_schools_page
    page.should have_css("li#side-schools")
  end # has_nav_to_schools_page

  def no_nav_to_schools_page
    page.should_not have_css("li#side-schools")
  end # no_nav_to_schools_page

  def no_school_listing
    # should not allow user to go directly to schools page
    visit schools_path
    assert_not_equal("/schools", current_path)
  end # no_school_listing

  def only_list_one_school
    # if going directly to schools page, should only show one school
    visit schools_path
    assert_equal("/schools", current_path)
    page.should have_css("tr#school-#{@school1.id}")
    page.all("tr td.school-acronym").count.should == 1
  end # only_list_one_school

  def lists_all_schools(sys_admin)
    visit schools_path()
    assert_equal("/schools", current_path)
    page.should have_css("tr#school-1")
    within("tr#school-1") do
      page.should have_css("a[href='/schools/1'] i.fa-building-o")
      page.should have_css("a[href='/schools/1/dashboard'] i.fa-dashboard")
      if sys_admin
        page.should have_css("a[data-url='/schools/1/edit.js'] i.fa-edit")
        page.should have_css("a#rollover-1 i.fa-forward")
      end
    end
    page.should have_css("tr#school-2")
    within("tr#school-2") do
      page.should have_css("a[href='/schools/2'] i.fa-building-o")
      page.should have_css("a[href='/schools/2/dashboard'] i.fa-dashboard")
      if sys_admin
        page.should have_css("a[data-url='/schools/2/edit.js'] i.fa-edit")
        page.should have_css("a#rollover-2.dim i.fa-forward")
      end
    end
    page.should have_css("tr#school-#{@school1.id}")
    within("tr#school-#{@school1.id}") do
      page.should have_css("a[href='/schools/#{@school1.id}'] i.fa-building-o")
      page.should have_css("a[href='/schools/#{@school1.id}/dashboard'] i.fa-dashboard")
      if sys_admin
        page.should have_css("a[data-url='/schools/#{@school1.id}/edit.js'] i.fa-edit")
        page.should have_css("a#rollover-#{@school1.id}.dim i.fa-forward")
      end
    end
    page.should have_css("tr#school-#{@school2.id}")
    within("tr#school-#{@school2.id}") do
      page.should have_css("a[href='/schools/#{@school2.id}'] i.fa-building-o")
      page.should have_css("a[href='/schools/#{@school2.id}/dashboard'] i.fa-dashboard")
      if sys_admin
        page.should have_css("a[data-url='/schools/#{@school2.id}/edit.js'] i.fa-edit")
        page.should have_css("a#rollover-#{@school2.id}[href='/schools/#{@school2.id}/new_year_rollover'] i.fa-forward")
      end
    end

    visit schools_path()
    find("a[href='/schools/#{@school1.id}']").click
    assert_equal("/schools/#{@school1.id}", current_path)
    page.should have_content("School: #{@school1.name}")
    within("div.show-label-value #school-acronym") do
      page.should have_content(@school1.acronym)
    end

    visit schools_path()
    find("a[href='/schools/#{@school1.id}/dashboard']").click
    assert_equal("/schools/#{@school1.id}/dashboard", current_path)
    page.should have_content("School: #{@school1.name}")
    within("div#overall") do
      page.should have_content('9 - High Performance')
      page.should have_content('9 - Proficient')
      page.should have_content('9 - Not Yet Proficient')
      page.should have_content('9 - Unrated')
    end

  end # def lists_all_schools

  def no_rollover_school_year
    visit schools_path()
    assert_equal("/schools", current_path)
    page.should_not have_css("a[id='rollover-#{@school1.id}']")
  end # def no_rollover_school_year

  def has_rollover_school_year
    visit schools_path()
    assert_equal("/schools", current_path)
    page.should have_css("a[id='rollover-#{@school1.id}']")
    page.should have_css("a.dim[id='rollover-#{@school1.id}']")
  end # def has_rollover_school_year

  def no_new_year_rollover
    visit schools_path()
    assert_equal("/schools", current_path)
    page.should_not have_css("a[href='/schools/#{@school1.id}/new_year_rollover']")
  end # def no_new_year_rollover

  def has_new_year_rollover
    visit schools_path()
    assert_equal("/schools", current_path)
    page.should have_css("a[href='/schools/#{@school2.id}/new_year_rollover']")
  end # def has_new_year_rollover

end
