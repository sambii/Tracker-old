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
      @home_page = "/teachers/#{@teacher1.id}"
    end
    it { no_nav_to_schools_page }
    it { has_no_schools_summary }
    it { only_list_one_school }
    it { no_rollover_school_year }
    it { no_new_year_rollover }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { no_nav_to_schools_page }
    it { has_valid_schools_summary }
    it { only_list_one_school }
    it { has_rollover_school_year }
    it { no_new_year_rollover }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { has_nav_to_schools_page(true) }
    it { has_valid_schools_summary }
    it { lists_all_schools(false, true) }
    it { no_rollover_school_year }
    it { no_new_year_rollover }
  end

  describe "as researcher with no school selected" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { has_nav_to_schools_page(false) }
    # it { lists_all_schools(false, false) }
    # it { no_rollover_school_year }
    # it { no_new_year_rollover }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { has_nav_to_schools_page(true) }
    it { has_valid_schools_summary }
    it { lists_all_schools(true, true) }
    it { has_rollover_school_year }
    it { has_new_year_rollover }
  end

  describe "as system administrator with no school selected" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { has_nav_to_schools_page(false) }
    # it { lists_all_schools(true, false) }
    # it { has_rollover_school_year }
    # it { has_new_year_rollover }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { no_nav_to_schools_page }
    it { has_no_schools_summary }
    it { no_school_listing }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { no_nav_to_schools_page }
    it { has_no_schools_summary }
    it { no_school_listing }
  end

  ##################################################
  # test methods

  def has_nav_to_schools_page(school_assigned)
    if !school_assigned
      # confirm school is not assigned
      within("#head-current-school") do
        page.should have_content("Select a School")
        page.should_not have_content("Switch School")
      end
    end
    page.should have_css("li#side-schools")
    find('li#side-schools a').click
    page.should have_css("a[href='/schools/#{@school2.id}']")
    find("a[href='/schools/#{@school2.id}']").click

    # confirm school is set
    within("#head-current-school") do
      page.should_not have_content("Select a School")
      within("span[title='Current School']") do
        page.should have_content(@school2.name)
      end
    end

    # has valid school summary page
    assert_equal("/schools/#{@school2.id}", current_path)
    within("h2") do
      page.should have_content(@school2.name)
    end
    page.should have_css("#overall")
    page.should have_css("#summary")

  end # has_nav_to_schools_page

  def has_valid_schools_summary(role)
    # access to school listing and school summary page in header

    # has link to school listing page in header
    if role == 'school_administrator'
      page.should_not have_css("#head-current-school a[href='/schools']")
    else
      page.should have_css("#head-current-school a[href='/schools']")
    end
    
    # has valid school summary page accessible from header
    within("#head-current-school") do
      find("a[href='/schools/#{@school2.id}']").click
    end
    assert_equal("/schools/#{@school2.id}", current_path)
    within("header-block h2") do
      page.should have_content(@school2.name)
    end
    within("#overall #school-acronym") do
      page.should have_content(@school2.acronym)
    end
    within("#summary") do
      page.should have_css("/schools/#{@school1.id}/dashboard")
      page.should have_css("/teachers/tracker_usage")
      page.should have_css("/subjects/progress_meters")
      page.should have_css("/subjects/proficiency_bars")
      if role == 'researcher'
        page.should_not have_css("/students/reports/proficiency_bar_chart")
        page.should_not have_css("/users/account_activity_report")
        page.should_not have_css("/users/staff_activity_report")
      else
        page.should have_css("/students/reports/proficiency_bar_chart")
        page.should_not have_css("/users/account_activity_report")
        page.should have_css("/users/staff_activity_report")
      end
    end

  end # has_valid_schools_summary

  def has_no_schools_summary
    # no access to school listing and school summary page in header
    page.should_not have_css("#head-current-school a[href='/schools']")
    page.should_not have_css("#head-current-school a[href='/schools/#{@school1.id}']")
    visit("/schools/#{@school1.id}")
    assert_equal(current_path, "/schools/#{@school1.id}")
    within("#summary") do
      page.should_not have_css("/schools/#{@school1.id}/dashboard")
      page.should_not have_css("/teachers/tracker_usage")
      page.should_not have_css("/subjects/progress_meters")
      page.should_not have_css("/subjects/proficiency_bars")
      page.should_not have_css("/students/reports/proficiency_bar_chart")
      page.should_not have_css("/users/account_activity_report")
    end
    # to do - shut down school summary listing page to all except admins and researcher
    assert_not_equal(current_path, "/schools/#{@school1.id}")
    assert_equal(current_path, @home_page)
  end

  def no_nav_to_schools_page
    page.should_not have_css("li#side-schools")
  end # no_nav_to_schools_page

  def no_school_listing
    # should not allow user to go directly to schools page
    visit schools_path
    assert_not_equal("/schools", current_path)
    assert_equal(current_path, @home_page)
  end # no_school_listing

  def only_list_one_school
    # if going directly to schools page, should only show one school
    visit schools_path
    assert_equal("/schools", current_path)
    page.should have_css("tr#school-#{@school1.id}")
    page.all("tr td.school-acronym").count.should == 1
  end # only_list_one_school

  def lists_all_schools(sys_admin, school_assigned)
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

    # confirm school is set after going to school dashboard
    if !school_assigned
      # confirm school is not assigned
      within("#head-current-school") do
        page.should have_content("Select a School")
        page.should_not have_content("Switch School")
      end
    end

    visit schools_path()
    page.should have_css("a[href='/schools/#{@school2.id}/dashboard']")
    find("a[href='/schools/#{@school2.id}/dashboard']").click
    assert_equal("/schools/#{@school2.id}/dashboard", current_path)
    page.should have_content("School: #{@school2.name}")
    within("div#overall") do
      page.should have_content('0 - High Performance')
      page.should have_content('0 - Proficient')
      page.should have_content('0 - Not Yet Proficient')
      page.should have_content('0 - Unrated')
    end

    # confirm school is set
    within("#head-current-school") do
      page.should_not have_content("Select a School")
      within("span[title='Current School']") do
        page.should have_content(@school2.name)
      end
    end

    visit schools_path()
    page.should have_css("a[href='/schools/#{@school1.id}/dashboard']")
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
