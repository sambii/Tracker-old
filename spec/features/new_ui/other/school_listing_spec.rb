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
    it { has_valid_school_navigations(:teacher) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { has_valid_schools_summary(:school_administrator) }
    it { has_valid_school_navigations(:school_administrator) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { has_nav_to_schools_page(true) }
    it { has_valid_schools_summary(:researcher) }
    it { has_valid_school_navigations(:researcher) }
  end

  describe "as researcher with no school selected" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { has_nav_to_schools_page(false) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { has_nav_to_schools_page(true) }
    it { has_valid_schools_summary(:system_administrator)}
    it { has_valid_school_navigations(:system_administrator) }
  end

  describe "as system administrator with no school selected" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { has_nav_to_schools_page(false) }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { has_valid_school_navigations(:student) }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { has_valid_school_navigations(:parent) }
  end

  ##################################################
  # test methods

  def has_nav_to_schools_page(school_assigned)
    # only for system_administrators and researchers
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
      page.should have_css("a[href='/schools'] i.fa-list-ul")
      page.should have_css("a[href='/schools/#{@school2.id}'] i.fa-building-o")
      page.should have_css("a[href='/schools/#{@school2.id}/dashboard'] i.fa-dashboard")
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
    # to be run only for ('system_administrator' || 'researcher' || 'school_administrator')

    # has link to school listing page in header
    if (role == :system_administrator || role == :researcher)
      # note: this is called only after school has been assigned
      page.should have_css("#head-current-school a[href='/schools']")
    elsif (role == :school_administrator)
      page.should_not have_css("#head-current-school a[href='/schools']")
      # if going directly to schools page, should only show one school
      visit schools_path
      assert_equal("/schools", current_path)
      page.should have_css("tr#school-#{@school1.id}")
      page.all("tr td.school-acronym").count.should == 1
    else
      # should not be run for other roles
      assert_equal(false, true)
    end

    # has valid school summary page accessible from header
    within("#head-current-school") do
      find("a[href='/schools/#{@school1.id}']").click
    end

    # validate the school summary page
    assert_equal("/schools/#{@school1.id}", current_path)
    within(".header-block h2") do
      page.should have_content(@school1.name)
    end
    within("#overall #school-acronym") do
      page.should have_content(@school1.acronym)
    end
    within("#summary") do
      page.should have_css("a[href='/schools/#{@school1.id}/dashboard']")
      page.should have_css("a[href='/teachers/tracker_usage']")
      page.should have_css("a[href='/subjects/progress_meters']")
      page.should have_css("a[href='/subjects/proficiency_bars']")
      # to do - create staff activity report as in school dashboard page, except more/all? recent activity
      # page.should have_css("a[href='/users/staff_activity_report']")
      if role == :researcher
        page.should_not have_css("a[href='/students/reports/proficiency_bar_chart']")
        page.should_not have_css("a[href='/users/account_activity_report']")
      else
        page.should have_css("a[href='/students/reports/proficiency_bar_chart']")
        page.should have_css("a[href='/users/account_activity_report']")
      end
    end

  end # has_valid_schools_summary

  def has_valid_school_navigations(role)

    # confirm sidebar only shows the school listing toolkit item if allowed
    if (role == :system_administrator || role == :researcher)
      page.should have_css("li#side-schools a[href='/schools']")
    else
      page.should_not have_css("li#side-schools")
      page.should_not have_css("a[href='/schools']")
    end

    # confirm header has correct icons and links for current school.
    within("#head-current-school") do
      page.should_not have_content("Select a School")
      within("span[title='Current School']") do
        page.should have_content(@school1.name)
      end
      if (role == :system_administrator || role == :researcher)
        page.should have_css("a[href='/schools'] i.fa-list-ul")
      else
        page.should_not have_css("a[href='/schools']")
        page.should_not have_css("a[href='/schools'] i.fa-list-ul")
      end
      if (role == :system_administrator || role == :researcher || role == :school_administrator)
        page.should have_css("a[href='/schools/#{@school1.id}'] i.fa-building-o")
        page.should have_css("a[href='/schools/#{@school1.id}/dashboard'] i.fa-dashboard")
      else
        page.should_not have_css("a[href='/schools/#{@school1.id}']")
        page.should_not have_css("a[href='/schools/#{@school1.id}'] i.fa-building-o")
        page.should_not have_css("a[href='/schools/#{@school1.id}/dashboard']")
        page.should_not have_css("a[href='/schools/#{@school1.id}/dashboard'] i.fa-dashboard")
      end
    end

    # Check go to school listing via navigation if available, else visit via URL
    if (role == :system_administrator || role == :researcher)
      within("#head-current-school") do
        find("a[href='/schools'] i.fa-list-ul").click
      end
    else
      visit(schools_path)
    end

    # validate the school listing page (if available)
    if (role == :student || role == :parent)
      assert_equal(current_path, @home_page)
    else
      assert_equal(current_path, schools_path)

      # ensure only valid links are displayed for school 1 based upon role.
      if (role == :teacher || role == :school_administrator || role == :system_administrator || role == :researcher)
        within("tr#school-#{@school1.id}") do
          if (role == :teacher)
            page.should_not have_css("a[href='/schools/#{@school1.id}'] i.fa-building-o")
            page.should_not have_css("a[href='/schools/#{@school1.id}/dashboard'] i.fa-dashboard")
            page.should_not have_css("a[data-url='/schools/#{@school1.id}/edit.js']")
            page.should_not have_css("a[data-url='/schools/#{@school1.id}/edit.js'] i.fa-edit")
            page.should_not have_css("a[href='/schools/#{@school1.id}/new_year_rollover']")
            page.should_not have_css("a[href='/schools/#{@school1.id}/new_year_rollover'] i.fa-forward")
            page.should_not have_css("a[id='rollover-#{@school1.id}']")
          elsif (role == :researcher)
            page.should have_css("a[href='/schools/#{@school1.id}'] i.fa-building-o")
            page.should have_css("a[href='/schools/#{@school1.id}/dashboard'] i.fa-dashboard")
            page.should_not have_css("a[data-url='/schools/#{@school1.id}/edit.js']")
            page.should_not have_css("a[data-url='/schools/#{@school1.id}/edit.js'] i.fa-edit")
            page.should_not have_css("a[href='/schools/#{@school1.id}/new_year_rollover']")
            page.should_not have_css("a[href='/schools/#{@school1.id}/new_year_rollover'] i.fa-forward")
            page.should_not have_css("a[id='rollover-#{@school1.id}']")
          elsif (role == :school_administrator || role == :system_administrator)
            page.should have_css("a[href='/schools/#{@school1.id}'] i.fa-building-o")
            page.should have_css("a[href='/schools/#{@school1.id}/dashboard'] i.fa-dashboard")
            page.should have_css("a[data-url='/schools/#{@school1.id}/edit.js'] i.fa-edit")
            page.should_not have_css("a[href='/schools/#{@school1.id}/new_year_rollover'] i.fa-forward")
            page.should_not have_css("a[id='rollover-#{@school1.id}'][href='/schools/#{@school1.id}/new_year_rollover'] i.fa-forward")
            page.should have_css("a.dim[id='rollover-#{@school1.id}'][href='javascript:void(0)'] i.fa-forward")
          end
        end

        # validate only/all other schools are listed
        if (role == :teacher || role == :school_administrator)
          page.should have_css("tr#school-#{@school1.id}")
          page.all("tr td.school-acronym").count.should == 1
        elsif (role == :system_administrator || role == :researcher)
          page.should have_css("tr#school-#{@school1.id}")
          page.should have_css("tr#school-#{@school2.id}")
          page.should have_css("tr#school-#{@model_school.id}")
          page.should have_css("tr#school-#{@training_school.id}")
          page.all("tr td.school-acronym").count.should == 4
          if (role == :system_administrator)
            page.should have_css("a[href='/schools/#{@school2.id}'] i.fa-building-o")
            page.should have_css("a[href='/schools/#{@school2.id}/dashboard'] i.fa-dashboard")
            page.should have_css("a[data-url='/schools/#{@school2.id}/edit.js'] i.fa-edit")
            page.should have_css("a[id='rollover-#{@school2.id}'][href='/schools/#{@school2.id}/new_year_rollover'] i.fa-forward")
            page.should have_css("a[href='/schools/#{@model_school.id}'] i.fa-building-o")
            page.should have_css("a[href='/schools/#{@model_school.id}/dashboard'] i.fa-dashboard")
            page.should have_css("a[data-url='/schools/#{@model_school.id}/edit.js'] i.fa-edit")
            page.should have_css("a[id='rollover-#{@model_school.id}'][href='/schools/#{@model_school.id}/new_year_rollover'] i.fa-forward")
            page.should have_css("a[href='/schools/#{@training_school.id}'] i.fa-building-o")
            page.should have_css("a[href='/schools/#{@training_school.id}/dashboard'] i.fa-dashboard")
            page.should have_css("a[data-url='/schools/#{@training_school.id}/edit.js'] i.fa-edit")
            page.should have_css("a.dim[id='rollover-#{@training_school.id}'][href='javascript:void(0)'] i.fa-forward")
            page.should have_css("a[href='/subject_outcomes/upload_lo_file'] i.fa-lightbulb-o")
          elsif (role == :researcher)
            page.should have_css("a[href='/schools/#{@school2.id}'] i.fa-building-o")
            page.should have_css("a[href='/schools/#{@school2.id}/dashboard'] i.fa-dashboard")
            page.should_not have_css("a[data-url='/schools/#{@school2.id}/edit.js']")
            page.should_not have_css("a[href='/schools/#{@school2.id}/new_year_rollover']")
            page.should_not have_css("a[id='rollover-#{@school2.id}']")
            page.should have_css("a[href='/schools/#{@model_school.id}'] i.fa-building-o")
            page.should have_css("a[href='/schools/#{@model_school.id}/dashboard'] i.fa-dashboard")
            page.should_not have_css("a[data-url='/schools/#{@model_school.id}/edit.js']")
            page.should_not have_css("a[href='/schools/#{@model_school.id}/new_year_rollover']")
            page.should_not have_css("a[id='rollover-#{@model_school.id}']")
            page.should have_css("a[href='/schools/#{@training_school.id}'] i.fa-building-o")
            page.should have_css("a[href='/schools/#{@training_school.id}/dashboard'] i.fa-dashboard")
            page.should_not have_css("a[data-url='/schools/#{@training_school.id}/edit.js']")
            page.should_not have_css("a[href='/schools/#{@training_school.id}/new_year_rollover']")
            page.should_not have_css("a[id='rollover-#{@training_school.id}']")
            page.should_not have_css("a[href='/subject_outcomes/upload_lo_file'] i.fa-lightbulb-o")
          end
        end
      else
        # no tests for these roles yet
      end
    end

  end # has_valid_school_navigations

end
