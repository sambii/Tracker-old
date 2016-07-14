# bulk_enter_sections_spec.rb

require 'spec_helper'

describe "Bulk Enter Sections", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    # two subjects in @school1
    @school1 = FactoryGirl.create :school_prior_year, :arabic

    # @teacher1_1 = FactoryGirl.create :teacher, school: @school1

    # # @subject1 has sections assigned
    # @subject1_1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1_1
    # @discipline = @subject1_1.discipline

    # @section1_1_1 = FactoryGirl.create :section, subject: @subject1_1, line_number: 'a-b'
    # @ta1_1_1 = FactoryGirl.create :teaching_assignment, teacher: @teacher1_1, section: @section1_1_1
    # @section1_1_2 = FactoryGirl.create :section, subject: @subject1_1, line_number: 'c-d'
    # @ta1_1_2 = FactoryGirl.create :teaching_assignment, teacher: @teacher1_1, section: @section1_1_2
    # @section1_1_3 = FactoryGirl.create :section, subject: @subject1_1, line_number: 'e-f'
    # @ta1_1_3 = FactoryGirl.create :teaching_assignment, teacher: @teacher1_1, section: @section1_1_3

    # # @subject2 has no sections assigned
    # @teacher1_2 = FactoryGirl.create :teacher, school: @school1
    # @subject1_2 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1_2, discipline: @discipline

    @student   = FactoryGirl.create :student, school: @school1, first_name: 'Student', last_name: 'School1'
    set_parent_password(@student)

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1_1)
    end
    it { no_valid_bulk_enter_sections }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { valid_bulk_enter_sections(false) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { no_valid_bulk_enter_sections }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { valid_bulk_enter_sections(true) }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { no_valid_bulk_enter_sections }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { no_valid_bulk_enter_sections }
  end

  ##################################################
  # test methods

  def no_valid_bulk_enter_sections
    visit subjects_path
    page.should_not have_css("a[href='/sections/enter_bulk']")
  end

  def valid_bulk_enter_sections(sys_admin)

    # create subjects same as in model school
    # note the @model_ instance variables will now be co-opted by @school1
    model_school_subjects(@school1)
    model_school_subjects_outcomes(@school1)

    # enter sections in prior year
    visit subjects_path
    page.should have_css("a[href='/sections/enter_bulk']")
    find("a[href='/sections/enter_bulk']").click
    assert_equal("/sections/enter_bulk", current_path)

    page.should have_css("tr#subject_#{@subj_art_1.id}")
    within("tr#subject_#{@subj_art_1.id}") do
      page.fill_in "section_0_0_value", :with => 'a-b'
      page.fill_in "section_0_1_value", :with => 'c-d'
      page.fill_in "section_0_2_value", :with => 'e-f'
    end
    page.click_button('SAVE')

    page.should have_content("Total Sections Entered: 3")
    page.click_button('Show entered report')
    within('tbody#report') do
      page.should have_content 'a-b'
      page.should have_content 'c-d'
      page.should have_content 'e-f'
    end

    # confirm sections show up in subjects/sections listing
    visit subjects_path
    find('a#expand-all-tbodies').click
    within("tbody#subj_body_#{@subj_art_1.id}") do
      page.should have_css("td.sect-section", text: 'a-b')
      page.should have_css("td.sect-section", text: 'c-d')
      page.should have_css("td.sect-section", text: 'e-f')
    end

    # confirm on prior year
    visit schools_path()
    within("tr#school-#{@school1.id} td.school-year") do
      page.should have_content(get_std_prior_school_year_name)
    end

    # Rollover school year
    find("a[id='rollover-#{@school1.id}']").click
    # click OK in javascript confirmation popup
    page.driver.browser.switch_to.alert.accept

    # Post rollover checks

    # confirm on next year
    within("tr#school-#{@school1.id} td.school-year") do
      page.should have_content(get_std_current_school_year_name)
    end

    visit subjects_path
    page.should have_css("a[href='/sections/enter_bulk']")
    find("a[href='/sections/enter_bulk']").click

    assert_equal("/sections/enter_bulk", current_path)

    page.should have_css("tr#subject_#{@subj_art_1.id}")
    within("tr#subject_#{@subj_art_1.id}") do
      page.should have_css("input#section_0_0_value", value: 'a-b')
      page.should have_css("input#section_0_1_value", value: 'c-d')
      page.should have_css("input#section_0_2_value", value: 'e-f')
    end

    page.should have_css("tr#subject_#{@subj_art_2.id}")
    within("tr#subject_#{@subj_art_2.id}") do
      page.fill_in "section_1_0_value", :with => '1-2'
      page.fill_in "section_1_1_value", :with => '3-4'
      page.fill_in "section_1_2_value", :with => '5-6'
    end

    page.click_button('SAVE')

    page.should have_content("Total Sections Entered: 6")
    page.click_button('Show entered report')

    within('tbody#report') do
      page.should have_content 'a-b'
      page.should have_content 'c-d'
      page.should have_content 'e-f'
      page.should have_content '1-2'
      page.should have_content '3-4'
      page.should have_content '5-6'
    end

    # confirm new sections show up in subjects/sections listing
    visit subjects_path
    find('a#expand-all-tbodies').click
    within("tbody#subj_body_#{@subj_art_1.id}") do
      page.should have_css("td.sect-section", text: 'a-b')
      page.should have_css("td.sect-section", text: 'c-d')
      page.should have_css("td.sect-section", text: 'e-f')
    end
    within("tbody#subj_body_#{@subj_art_2.id}") do
      page.should have_css("td.sect-section", text: '1-2')
      page.should have_css("td.sect-section", text: '3-4')
      page.should have_css("td.sect-section", text: '5-6')
    end

    # confirm the subject is not listed in the bulk entry page / no subjects without sections
    page.should have_css("a[href='/sections/enter_bulk']")
    find("a[href='/sections/enter_bulk']").click
    # assert_not_equal("/sections/enter_bulk", current_path)
    # within('div#breadcrumb-flash-msgs') do
    #   page.should have_content("Cannot run Section Bulk Entry, all subjects have sections assigned")
    # end
    page.should_not have_css("tbody#subj_body_#{@subj_art_1.id}")
    page.should_not have_css("tbody#subj_body_#{@subj_art_2.id}")

  end

end
