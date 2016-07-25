# school_year_rollover_spec.rb

# this tests the school year rollover processes
# Note: The learning outcome upload and rollover process is tested in subject_outcomes_upload_lo_file_spec.rb

require 'spec_helper'


describe "Rollover School Year", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    # two subjects in @school1
    @school1 = FactoryGirl.create :school_current_year, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    @section1_2 = FactoryGirl.create :section, subject: @subject1
    @section1_3 = FactoryGirl.create :section, subject: @subject1
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
    @school2 = FactoryGirl.create :school_prior_year, :arabic
    @teacher2_1 = FactoryGirl.create :teacher, school: @school2
    @subject2_1 = FactoryGirl.create :subject, school: @school2, subject_manager: @teacher2_1
    @section2_1_1 = FactoryGirl.create :section, subject: @subject2_1
    @section2_1_2 = FactoryGirl.create :section, subject: @subject2_1
    @section2_1_3 = FactoryGirl.create :section, subject: @subject2_1

    # students in @school2 in various grade levels and active status values
    @student2_1   = FactoryGirl.create :student, school: @school2, first_name: 'Student1', last_name: 'Grade1', grade_level: 1
    @enrollment2_1 = FactoryGirl.create :enrollment, section: @section2_1_1, student: @student2_1, student_grade_level: 1
    @student2_2   = FactoryGirl.create :student, school: @school2, first_name: 'Student2', last_name: 'Grade2', grade_level: 2
    @enrollment2_2 = FactoryGirl.create :enrollment, section: @section2_1_1, student: @student2_2, student_grade_level: 2
    @student2_3   = FactoryGirl.create :student, school: @school2, first_name: 'Student3', last_name: 'Grade3', grade_level: 3
    @enrollment2_3 = FactoryGirl.create :enrollment, section: @section2_1_1, student: @student2_3, student_grade_level: 3
    @student2_4   = FactoryGirl.create :student, school: @school2, first_name: 'Student4', last_name: 'Grade1', grade_level: 1, active: false
    @enrollment2_4 = FactoryGirl.create :enrollment, section: @section2_1_1, student: @student2_4, student_grade_level: 1
    @student2_5   = FactoryGirl.create :student, school: @school2, first_name: 'Student5', last_name: 'Grade1', grade_level: 1
    @enrollment2_5 = FactoryGirl.create :enrollment, section: @section2_1_1, student: @student2_5, student_grade_level: 1, active: false

    # Put learning outcomes new year rollover
    # original subject (not in model school) should be removed
    @s2_so2_1_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @subject2_1, lo_code: 'SO.1.01', description: 'Original LO 01', marking_period: '1&2'
    @s2_so2_1_02 = FactoryGirl.create :subject_outcome, :arabic, subject: @subject2_1, lo_code: 'SO.1.02', description: 'Original LO 02', marking_period: '1&2'
    @s2_so2_1_03 = FactoryGirl.create :subject_outcome, :arabic, subject: @subject2_1, lo_code: 'SO.1.03', description: 'Original LO 03', marking_period: '1&2'
    @s2_so2_1_04 = FactoryGirl.create :subject_outcome, :arabic, subject: @subject2_1, lo_code: 'SO.1.04', description: 'Original LO 04', marking_period: '1&2'

    # different from model school before rollover, same afterwards (see model_school_subjects_outcomes in load_section_helper.rb)
    @s2_subj_art_2 = FactoryGirl.create :subject, name: 'Art 2', school: @school2, subject_manager: @teacher2_1
    @s2_so_at_2_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_art_2, lo_code: 'AT.2.01', description: 'Old School Info 01', marking_period: '1'
    @s2_so_at_2_02 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_art_2, lo_code: 'AT.2.02', description: 'Old School Info 02', marking_period: '1'
    @s2_so_at_2_03 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_art_2, lo_code: 'AT.2.03', description: 'Old School Info 03', marking_period: '2'
    @s2_so_at_2_04 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_art_2, lo_code: 'AT.2.04', description: 'Old School Info 04', marking_period: '2'

    # same as model school before rollover, changed only for sys admin afterwards (see model_school_subjects_outcomes in load_section_helper.rb)
    @s2_subj_math_1 = FactoryGirl.create :subject, name: 'Math 1', school: @school2, subject_manager: @teacher2_1
    @s2_ma_1_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.01', description: 'Will be changed significantly. Create, interpret and analyze trigonometric ratios that model real-world situations.', marking_period: '1'
    @s2_ma_1_02 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.02', description: 'Will be deleted. Apply the relationships between 2-D and 3-D objects in modeling situations.', marking_period: '1'
    @s2_ma_1_03 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.03', description: 'Will have the MA.1.03 code without the period. Understand similarity and use the concept for scaling to solve problems.', marking_period: '1'
    @s2_ma_1_04 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.04', description: 'will be switched with 08. Apply volume formulas (pyramid, cones, spheres, prisms).', marking_period: '1'
    @s2_ma_1_05 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.05', description: 'Will be switched to semester 1&2. Create, interpret and analyze functions, particularly linear and step functions that model real-world situations.', marking_period: '1'
    @s2_ma_1_06 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.06', description: 'Will be unchanged. Analyze, display and describe quantitative data with a focus on standard deviation.', marking_period: '1&2'
    @s2_ma_1_07 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.07', description: 'Will be switched to semester 2. Create, interpret and analyze quadratic functions that model real-world situations.', marking_period: '1&2'
    @s2_ma_1_08 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.08', description: 'Will be switched with 04. Create, interpret and analyze exponential and logarithmic functions that model real-world situations.', marking_period: '2'
    @s2_ma_1_09 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.09', description: 'Will have a description that is very similar to 10.', marking_period: '2'
    @s2_ma_1_10 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.10', description: 'Will have a description that is very similar to 09.', marking_period: '2'
    @s2_ma_1_11 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.11', description: 'Will have period removed from description. Create, interpret and analyze systems of linear functions that model real-world situations.', marking_period: '2'
    @s2_ma_1_12 = FactoryGirl.create :subject_outcome, :arabic, subject: @s2_subj_math_1, lo_code: 'MA.1.12', description: 'Will be reactivated. Apply determinants and their properties in real-world situations.', marking_period: '2', active: false


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
    # school admin rollover tests
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

    # school year rollover as system admin - no extra tests
    valid_school_year_rollover(false)

  end # def rollover_school_year

  def valid_sys_admin_school_listing(school_no_rollover, school_rollover)
    # sys admin school year rollover tests
    visit schools_path()
    assert_equal("/schools", current_path)

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

    # school year rollover as system admin - extra tests
    valid_school_year_rollover(true)

  end

  def valid_school_year_rollover(sys_admin)

    #########################################################
    # Pre rollover checks
    # note this is for @school2 (whose school year is prior to the model school's school year)
    #########################################################

    if sys_admin

      find("a[href='/schools']").click
      assert_equal("/schools", current_path)
      page.should have_css("tr#school-#{@school1.id}")
      find("a[href='/schools/1']").click
      assert_equal("/schools/1", current_path)
      page.should have_content("School: Model School")
      visit subjects_path()
      assert_equal("/subjects", current_path)
      page.should have_content("Subjects / Sections Listing")
      page.all("tbody.tbody-subject").count.should == 4

      # add new subject to model school
      find("a[data-url='/subjects/new.js']").click
      page.select(@subject2_1.discipline.name, from: "subject-discipline-id")
      page.fill_in 'subject-name', :with => 'New Subject'
      page.click_button('Save')
      assert_equal("/subjects", current_path)

      # confirm new subject is in model school
      page.should have_content("#{@subject2_1.discipline.name} : New Subject")
      page.all("tbody.tbody-subject").count.should == 5

      # go to @school2
      find("a[href='/schools']").click
      find("a[href='/schools/#{@school2.id}']").click
      find("a[href='/subjects']").click

      # confirm new subject is not in @school2
      page.should_not have_content("#{@subject2_1.discipline.name} : New Subject")
    end

    visit subjects_path()

    # confirm @subject2_1 exists and has sections
    page.should have_css("tbody#subj_header_#{@subject2_1.id}")
    within("tbody#subj_header_#{@subject2_1.id}") do
      page.should have_content(@subject2_1.name)
    end
    page.should have_css("tbody#subj_body_#{@subject2_1.id}")
    within("tbody#subj_body_#{@subject2_1.id}") do
      page.should have_content(@section2_1_1.line_number)
      page.should have_content(@section2_1_2.line_number)
      page.should have_content(@section2_1_3.line_number)
    end

    # confirm @subject2_1 exists and has learning outcomes
    visit subjects_path()
    page.should have_css("tbody#subj_header_#{@subject2_1.id}")
    within("tbody#subj_header_#{@subject2_1.id}") do
      page.should have_content(@subject2_1.name)
    end

    within("tbody#subj_header_#{@subject2_1.id}") do
      find("a[href='/subjects/#{@subject2_1.id}/edit_subject_outcomes']").click
    end
    assert_equal("/subjects/#{@subject2_1.id}/edit_subject_outcomes", current_path)
    within('h1') do
      page.should have_content("View Learning Outcomes for:")
      page.should have_css("a[href='/subjects/#{@subject2_1.id}']")
    end
    within('table#current_los') do
      page.should have_content("Original LO 01")
      page.should have_content("Original LO 02")
      page.should have_content("Original LO 03")
      page.should have_content("Original LO 04")
    end

    # confirm @s2_subj_art_2 exists and has sections
    visit subjects_path()
    page.should have_css("tbody#subj_header_#{@s2_subj_art_2.id}")
    within("tbody#subj_header_#{@s2_subj_art_2.id}") do
      page.should have_content(@s2_subj_art_2.name)
    end

    within("tbody#subj_header_#{@s2_subj_art_2.id}") do
      find("a[href='/subjects/#{@s2_subj_art_2.id}/edit_subject_outcomes']").click
    end
    assert_equal("/subjects/#{@s2_subj_art_2.id}/edit_subject_outcomes", current_path)
    within('h1') do
      page.should have_content("View Learning Outcomes for:")
      page.should have_css("a[href='/subjects/#{@s2_subj_art_2.id}']")
    end
    within('table#current_los') do
      page.should have_content("Old School Info 01")
      page.should have_content("Old School Info 02")
      page.should have_content("Old School Info 03")
      page.should have_content("Old School Info 04")
    end

    # confirm @s2_subj_math_1 exists and has sections
    visit subjects_path()
    page.should have_css("tbody#subj_header_#{@s2_subj_math_1.id}")
    within("tbody#subj_header_#{@s2_subj_math_1.id}") do
      page.should have_content(@s2_subj_math_1.name)
    end

    within("tbody#subj_header_#{@s2_subj_math_1.id}") do
      find("a[href='/subjects/#{@s2_subj_math_1.id}/edit_subject_outcomes']").click
    end
    assert_equal("/subjects/#{@s2_subj_math_1.id}/edit_subject_outcomes", current_path)
    within('h1') do
      page.should have_content("View Learning Outcomes for:")
      page.should have_css("a[href='/subjects/#{@s2_subj_math_1.id}']")
    end
    within('table#current_los') do
      page.should have_content('Will be changed significantly. Create, interpret and analyze trigonometric ratios that model real-world situations.')
      page.should have_content('Will be deleted. Apply the relationships between 2-D and 3-D objects in modeling situations.')
      page.should have_content('Will have the MA.1.03 code without the period. Understand similarity and use the concept for scaling to solve problems.')
      page.should have_content('will be switched with 08. Apply volume formulas (pyramid, cones, spheres, prisms).')
      page.should have_content('Will be switched to semester 1&2. Create, interpret and analyze functions, particularly linear and step functions that model real-world situations.')
      page.should have_content('Will be unchanged. Analyze, display and describe quantitative data with a focus on standard deviation.')
      page.should have_content('Will be switched to semester 2. Create, interpret and analyze quadratic functions that model real-world situations.')
      page.should have_content('Will be switched with 04. Create, interpret and analyze exponential and logarithmic functions that model real-world situations.')
      page.should have_content('Will have a description that is very similar to 10.')
      page.should have_content('Will have a description that is very similar to 09.')
      page.should have_content('Will have period removed from description. Create, interpret and analyze systems of linear functions that model real-world situations.')
      page.should_not have_content('Will be reactivated. Apply determinants and their properties in real-world situations.')
    end

    # confirm students are in original grade level
    visit students_path()
    within("tr#student_#{@student2_1.id}") do
      page.should have_content(@student2_1.last_name)
      page.should have_content(@student2_1.first_name)
      page.should have_css('td.user-grade-level', text: @student2_1.grade_level.to_s)
      page.should have_css('td.user-grade-level', text: '1')
    end
    within("tr#student_#{@student2_2.id}") do
      page.should have_content(@student2_2.last_name)
      page.should have_content(@student2_2.first_name)
      page.should have_css('td.user-grade-level', text: @student2_2.grade_level.to_s)
      page.should have_css('td.user-grade-level', text: '2')
    end
    within("tr#student_#{@student2_3.id}") do
      page.should have_content(@student2_3.last_name)
      page.should have_content(@student2_3.first_name)
      page.should have_css('td.user-grade-level', text: @student2_3.grade_level.to_s)
      page.should have_css('td.user-grade-level', text: '3')
    end
    page.should have_css("tr#student_#{@student2_4.id}.deactivated")
    within("tr#student_#{@student2_4.id}") do
      page.should have_content(@student2_4.last_name)
      page.should have_content(@student2_4.first_name)
      page.should have_css('td.user-grade-level', text: @student2_4.grade_level.to_s)
      page.should have_css('td.user-grade-level', text: '1')
    end

    # confirm students have with sections under current year

    # confirm on prior year
    visit schools_path()
    within("tr#school-#{@school2.id} td.school-year") do
      page.should have_content(get_std_prior_school_year_name)
    end

    if sys_admin
      # LO Updates in Model School
      # Note: only math LOs changed in model school
      bulk_upload_all_los

      # go to @school2
      find("a[href='/schools']").click
      find("a[href='/schools/#{@school2.id}']").click
      find("a[href='/subjects']").click

    end

    #########################################################
    # Rollover school year
    #########################################################
    visit schools_path()
    find("a[id='rollover-#{@school2.id}']").click
    # click OK in javascript confirmation popup
    page.driver.browser.switch_to.alert.accept

    sleep 20

    #########################################################
    # Post rollover checks
    #########################################################

    assert_equal("/schools", current_path)
    page.should have_css("tr#school-#{@school2.id}")

    # confirm on next year
    within("tr#school-#{@school2.id} td.school-year") do
      page.should have_content(get_std_current_school_year_name)
    end

    visit subjects_path()

    # confirm all model school subjects exist in school and are not duplicated
    page.all('tbody.tbody-header strong', text: "#{@subj_art_1.discipline.name} : #{@subj_art_1.name}").count.should == 1
    # should not have copied the Art 2 subject from the model school
    page.all('tbody.tbody-header strong', text: "#{@subj_art_2.discipline.name} : #{@subj_art_2.name}").count.should == 0
    page.all('tbody.tbody-header strong', text: "#{@s2_subj_art_2.discipline.name} : #{@s2_subj_art_2.name}").count.should == 1
    # page.all('tbody.tbody-header strong', text: "#{@subj_art_3.discipline.name} : #{@subj_art_3.name}").count.should == 1
    # page.all('tbody.tbody-header strong', text: "#{@subj_capstone_1s1.discipline.name} : #{@subj_capstone_1s1.name}").count.should == 1
    # page.all('tbody.tbody-header strong', text: "#{@subj_capstone_1s2.discipline.name} : #{@subj_capstone_1s2.name}").count.should == 1
    page.all('tbody.tbody-header strong', text: "#{@subj_capstone_3s1.discipline.name} : #{@subj_capstone_3s1.name}").count.should == 1
    # should not have copied the Math 1 subject from the model school
    page.all('tbody.tbody-header strong', text: "#{@subj_math_1.discipline.name} : #{@subj_math_1.name}").count.should == 0
    page.all('tbody.tbody-header strong', text: "#{@s2_subj_math_1.discipline.name} : #{@s2_subj_math_1.name}").count.should == 1


    ##### todo #####
    # do programming to deactivate subjects that are no longer in model school
    #####
    # # confirm @subject2_1 no longer exists and is not duplicated
    # page.should_not have_css("tbody#subj_header_#{@subject2_1.id}")
    # page.all('tbody.tbody-header strong', text: "#{@subject2_1.discipline.name} : #{@subject2_1.name}").count.should == 0
    # # confirm there are no sections under @subject2_1
    # within("tbody#subj_body_#{@subject2_1.id}") do
    #   page.should_not have_content(@section2_1_1.line_number)
    #   page.should_not have_content(@section2_1_2.line_number)
    #   page.should_not have_content(@section2_1_3.line_number)
    # end

    if sys_admin
      # confirm new subject got copied over from model school
      page.should have_content("#{@subject2_1.discipline.name} : New Subject")
      # do programming to deactivate subjects that are no longer in model school
      page.all("tbody.tbody-subject").count.should == 6
    end

    # confirm @subject2_1 exists and has learning outcomes
    # Note: this should eventually be deactivated
    visit subjects_path()
    page.should have_css("tbody#subj_header_#{@subject2_1.id}")
    within("tbody#subj_header_#{@subject2_1.id}") do
      page.should have_content(@subject2_1.name)
    end

    # confirm that lo update has taken place
    within("tbody#subj_header_#{@subject2_1.id}") do
      find("a[href='/subjects/#{@subject2_1.id}/edit_subject_outcomes']").click
    end
    assert_equal("/subjects/#{@subject2_1.id}/edit_subject_outcomes", current_path)
    within('h1') do
      page.should have_content("View Learning Outcomes for:")
      page.should have_css("a[href='/subjects/#{@subject2_1.id}']")
    end
    within('table#current_los') do
      page.should_not have_content("Original LO 01")
      page.should_not have_content("Original LO 02")
      page.should_not have_content("Original LO 03")
      page.should_not have_content("Original LO 04")
    end

    # confirm @s2_subj_art_2 exists and has sections
    visit subjects_path()
    page.should have_css("tbody#subj_header_#{@s2_subj_art_2.id}")
    within("tbody#subj_header_#{@s2_subj_art_2.id}") do
      page.should have_content(@s2_subj_art_2.name)
    end

    within("tbody#subj_header_#{@s2_subj_art_2.id}") do
      find("a[href='/subjects/#{@s2_subj_art_2.id}/edit_subject_outcomes']").click
    end
    assert_equal("/subjects/#{@s2_subj_art_2.id}/edit_subject_outcomes", current_path)
    within('h1') do
      page.should have_content("View Learning Outcomes for:")
      page.should have_css("a[href='/subjects/#{@s2_subj_art_2.id}']")
    end
    within('table#current_los') do
      page.should_not have_content("Old School Info 01")
      page.should_not have_content("Old School Info 02")
      page.should_not have_content("Old School Info 03")
      page.should_not have_content("Old School Info 04")
      page.should have_content('AT.2.01 Original')
      page.should have_content('AT.2.02 Original')
      page.should have_content('AT.2.03 Original')
      page.should have_content('AT.2.04 Original')
    end

    # confirm @s2_subj_math_1 exists and has sections
    visit subjects_path()
    page.should have_css("tbody#subj_header_#{@s2_subj_math_1.id}")
    within("tbody#subj_header_#{@s2_subj_math_1.id}") do
      page.should have_content(@s2_subj_math_1.name)
    end

    within("tbody#subj_header_#{@s2_subj_math_1.id}") do
      find("a[href='/subjects/#{@s2_subj_math_1.id}/edit_subject_outcomes']").click
    end
    assert_equal("/subjects/#{@s2_subj_math_1.id}/edit_subject_outcomes", current_path)
    within('h1') do
      page.should have_content("View Learning Outcomes for:")
      page.should have_css("a[href='/subjects/#{@s2_subj_math_1.id}']")
    end
    if sys_admin
      # confirm the LOs from the Sys Admin's Bulk Upload are displayed
      within('table#current_los') do
        page.should have_content('Will be changed significantly. Create, interpret and analyze trigonometric ratios that model real-world situations.')
        page.should have_content('Will be deleted. Apply the relationships between 2-D and 3-D objects in modeling situations.')
        page.should have_content('Will have the MA.1.03 code without the period. Understand similarity and use the concept for scaling to solve problems.')
        page.should have_content('will be switched with 08. Apply volume formulas (pyramid, cones, spheres, prisms).')
        page.should have_content('Will be switched to semester 1&2. Create, interpret and analyze functions, particularly linear and step functions that model real-world situations.')
        page.should have_content('Will be unchanged. Analyze, display and describe quantitative data with a focus on standard deviation.')
        page.should have_content('Will be switched to semester 2. Create, interpret and analyze quadratic functions that model real-world situations.')
        page.should have_content('Will be switched with 04. Create, interpret and analyze exponential and logarithmic functions that model real-world situations.')
        page.should have_content('Will have a description that is very similar to 10.')
        page.should have_content('Will have a description that is very similar to 09.')
        page.should have_content('Will have period removed from description. Create, interpret and analyze systems of linear functions that model real-world situations.')
        page.should_not have_content('Will be reactivated. Apply determinants and their properties in real-world situations.')
      end
    else
      # confirm are the same for school admins
      within('table#current_los') do
        page.should have_content('Will be changed significantly. Create, interpret and analyze trigonometric ratios that model real-world situations.')
        page.should have_content('Will be deleted. Apply the relationships between 2-D and 3-D objects in modeling situations.')
        page.should have_content('Will have the MA.1.03 code without the period. Understand similarity and use the concept for scaling to solve problems.')
        page.should have_content('will be switched with 08. Apply volume formulas (pyramid, cones, spheres, prisms).')
        page.should have_content('Will be switched to semester 1&2. Create, interpret and analyze functions, particularly linear and step functions that model real-world situations.')
        page.should have_content('Will be unchanged. Analyze, display and describe quantitative data with a focus on standard deviation.')
        page.should have_content('Will be switched to semester 2. Create, interpret and analyze quadratic functions that model real-world situations.')
        page.should have_content('Will be switched with 04. Create, interpret and analyze exponential and logarithmic functions that model real-world situations.')
        page.should have_content('Will have a description that is very similar to 10.')
        page.should have_content('Will have a description that is very similar to 09.')
        page.should have_content('Will have period removed from description. Create, interpret and analyze systems of linear functions that model real-world situations.')
        page.should_not have_content('Will be reactivated. Apply determinants and their properties in real-world situations.')
      end
    end

    # confirm student grade levels are incremented properly
    visit students_path()
    within("tr#student_#{@student2_1.id}") do
      page.should have_content(@student2_1.last_name)
      page.should have_content(@student2_1.first_name)
      page.should_not have_css('td.user-grade-level', text: @student2_1.grade_level.to_s)
      page.should have_css('td.user-grade-level', text: '2')
    end
    within("tr#student_#{@student2_2.id}") do
      page.should have_content(@student2_2.last_name)
      page.should have_content(@student2_2.first_name)
      page.should_not have_css('td.user-grade-level', text: @student2_2.grade_level.to_s)
      page.should have_css('td.user-grade-level', text: '3')
    end
    # student > grade level 3 is not listed on the student listing
    page.should_not have_css("tr#student_#{@student2_3.id}")

    page.should have_css("tr#student_#{@student2_4.id}.deactivated")
    within("tr#student_#{@student2_4.id}") do
      page.should have_content(@student2_4.last_name)
      page.should have_content(@student2_4.first_name)
      page.should_not have_css('td.user-grade-level', text: @student2_4.grade_level.to_s)
      page.should have_css('td.user-grade-level', text: '2')
    end


  end


  def bulk_upload_all_los
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_only_math_chg.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click

      page.should have_content("Processing #{@subj_art_1.name} of All Subjects")
      find("input#selections_0_#{@so_at_1_01.id}").should be_checked
      find("input#selections_1_#{@so_at_1_02.id}").should be_checked
      find("input#selections_2_#{@so_at_1_03.id}").should be_checked
      find("input#selections_3_#{@so_at_1_04.id}").should be_checked
      find('#save_matches').click

      # Art 2 with all preselected identical pairs
      page.should have_content("Processing #{@subj_art_2.name} of All Subjects")
      find("input#selections_4_#{@so_at_2_01.id}").should be_checked
      find("input#selections_5_#{@so_at_2_02.id}").should be_checked
      find("input#selections_6_#{@so_at_2_03.id}").should be_checked
      find("input#selections_7_#{@so_at_2_04.id}").should be_checked
      find('#save_matches').click

      # Capstone 3s1 with all preselected identical pairs
      page.should have_content("Processing #{@subj_capstone_3s1.name} of All Subjects")
      find("input#selections_8_#{@cp_3_01.id}").should be_checked
      find("input#selections_9_#{@cp_3_02.id}").should be_checked
      find("input#selections_10_#{@cp_3_03.id}").should be_checked
      find("input#selections_11_#{@cp_3_04.id}").should be_checked
      find('#save_matches').click

      # Math 1 with all preselected identical pairs
      page.should have_content("Processing #{@subj_math_1.name} of All Subjects")
      find("input#selections_12_#{@ma_1_01.id}").should_not be_checked
      find("input#selections__#{@ma_1_01.id}").should_not be_checked
      find("input#selections__#{@ma_1_02.id}").should_not be_checked
      find("input#selections__#{@ma_1_03.id}").should_not be_checked
      find("input#selections_18_#{@ma_1_08.id}").should_not be_checked
      find("input#selections_18_#{@ma_1_04.id}").should_not be_checked
      find("input#selections__#{@ma_1_04.id}").should_not be_checked
      find("input#selections_15_#{@ma_1_05.id}").should be_checked
      find("input#selections_16_#{@ma_1_06.id}").should be_checked
      find("input#selections_17_#{@ma_1_07.id}").should be_checked
      find("input#selections_14_#{@ma_1_04.id}").should_not be_checked
      find("input#selections_14_#{@ma_1_08.id}").should_not be_checked
      find("input#selections__#{@ma_1_08.id}").should_not be_checked
      find("input#selections_19_#{@ma_1_09.id}").should be_checked
      find("input#selections_20_#{@ma_1_10.id}").should be_checked
      find("input#selections_21_#{@ma_1_11.id}").should_not be_checked
      find("input#selections__#{@ma_1_11.id}").should_not be_checked
      find("input#selections_13_#{@ma_1_03.id}").should_not be_checked

      # select records for good update
      find("input#selections_12_#{@ma_1_01.id}").click
      find("input#selections__#{@ma_1_02.id}").click
      find("input#selections_18_#{@ma_1_04.id}").click
      find("input#selections_14_#{@ma_1_08.id}").click
      find("input#selections_21_#{@ma_1_11.id}").click
      find("input#selections_13_#{@ma_1_03.id}").click

      find('#save_matches').click
      # sleep 30
      # save_and_open_page

      page.should have_content("Processing New Subject of All Subjects")

      find('#save_matches').click
      # sleep 30
      # save_and_open_page

      # Confirm Report is properly generated
      page.should have_content("Processing All Subjects")
      page.should_not have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}__#{@ma_1_02.id}']")

    end # within #page-content
  end # def bulk_upload_all_los

end
