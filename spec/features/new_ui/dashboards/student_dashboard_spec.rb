# student_dashboard_spec.rb
require 'spec_helper'


describe "Student Dashboard", js:true do
  before (:each) do
    @section1_1 = FactoryGirl.create :section
    @subject1 = @section1_1.subject
    @school1 = @section1_1.school
    @teacher1 = @subject1.subject_manager
    @discipline = @subject1.discipline

    load_test_section(@section1_1, @teacher1)

    # add unenrolled section to student (inactive enrollment)
    @subject2 = FactoryGirl.create :subject, subject_manager: @teacher1
    @section2_1 = FactoryGirl.create :section, subject: @subject2
    @enrollment2_1 = FactoryGirl.create :enrollment, section: @section2_1, student: @student, active: false
    @subjo2_1 = FactoryGirl.create(:subject_outcome, subject: @subject2)
    @secto2_1 = FactoryGirl.create(:section_outcome, section: @section2_1, subject_outcome: @subjo2_1, minimized: false)
    @sor2_1 = FactoryGirl.create :section_outcome_rating, section_outcome: @secto2_1, student: @student, rating: 'H'
    @ev2_1 = FactoryGirl.create(:evidence, section: @section2_1)
    @eso2_1 = FactoryGirl.create :evidence_section_outcome, section_outcome: @secto2_1, evidence: @ev2_1
    @esor2_1 = FactoryGirl.create :evidence_section_outcome_rating, evidence_section_outcome: @eso2_1, student: @student, rating: 'B'

    @subject3 = FactoryGirl.create :subject, subject_manager: @teacher1
    @section3_1 = FactoryGirl.create :section, subject: @subject3




    # todo - add prior/next year section

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
    end
    # it { student_dashboard_is_valid } # student active and enrolled.
    # it { unenrolled_student_dashboard_is_valid } # student active, but unenrolled.
    # it { transferred_student_dashboard_is_valid } # student deactivated, but still enrolled.
    # it { out_student_dashboard_is_valid } # student deactivated, and unenrolled.
    # it { new_student_dashboard_is_valid } # student active and enrolled with no ratings.
    it { all_student_dashboards_are_valid(false) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @section1_1.school
      sign_in(@school_administrator)
    end
    it { student_dashboard_is_valid(true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@section1_1.school)
    end
    it { student_dashboard_is_valid(true) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section1_1.school)
    end
    it { student_dashboard_is_valid(true) }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { student_dashboard_is_valid(true) }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { student_dashboard_is_valid(true) }
  end

  ##################################################
  # test methods

  # def can_see_student_dashboard
  #   visit student_path(@student.id)
  #   assert_equal("/students/#{@student.id}", current_path)
  # end

  def all_student_dashboards_are_valid(can_see_all_sections)
    # run all students under one test, to prevent reloading test data repeatedly.
    # can_see_student_dashboard
    student_dashboard_is_valid(can_see_all_sections)
    unenrolled_student_dashboard_is_valid
    transferred_student_dashboard_is_valid
    out_student_dashboard_is_valid
    new_student_dashboard_is_valid
  end

  def student_dashboard_is_valid(can_see_all_sections)
    visit student_path(@student.id)
    assert_equal("/students/#{@student.id}", current_path)
    within("#evidence-stats-overall h4.text-success") do
      page.should have_content('12/24')
    end
    within("#evidence-stats-overall h4.text-danger") do
      page.should have_content('12/24')
    end
    # within("#evidence-stats-last7 h4.text-success") do
    #   page.should have_content('0/0')
    # end
    # within("#evidence-stats-last7 h4.text-danger") do
    #   page.should have_content('0/0')
    # end
    within("#lo-pie") do
      page.should have_content('1 - High Performance')
      page.should have_content('1 - Proficient')
      page.should have_content('1 - Not Yet Proficient')
      page.should have_content('1 - Unrated')
    end

    # no tests for Missing Evidence yet - #missing-evid
    # within("#missing-evidd") do
    #   page.should have_content('????')
    # end

    # ensure deactivated enrollment doesn't show on page
    page.should have_selector("#lo-progress tr[data-lo-prog-id='#{@section1_1.id}']")
    within("tr[data-lo-prog-id='#{@section1_1.id}']") do
      page.should have_content("#{@section1_1.name} | #{@teacher1.last_name}")
      page.should have_content("2/3")
      page.should have_content("of 4")
    end
    page.should_not have_css("tr[data-lo-prog-id='#{@section2_1.id}']")
    page.should_not have_css("tr[data-lo-prog-id='#{@section3_1.id}']")

    if can_see_all_sections
      # confirm deactivated enrollment Student Tracker page indicates unenrolled
      visit enrollment_path(@enrollment2_1)
      assert_equal("/enrollments/#{@enrollment2_1.id}", current_path)
      within('.header-block h2') do
        page.should have_content("Student has been unenrolled from this class!")
      end
    else
      # cannot see student sections not assigned to
      visit enrollment_path(@enrollment2_1)
      assert_equal("/teachers/#{@teacher1.id}", current_path)
    end

    # confirm active enrollment Student Tracker page does not indicate unenrolled
    visit enrollment_path(@enrollment)
    assert_equal("/enrollments/#{@enrollment.id}", current_path)
    within('.header-block h2') do
      page.should_not have_content("Student has been unenrolled from this class!")
    end

  end

  def unenrolled_student_dashboard_is_valid
    visit student_path(@enrollment_unenrolled.student.id)
    assert_equal("/students/#{@enrollment_unenrolled.student.id}", current_path)
    within("h2.h1.page-title") do
      page.should have_content('Student: Student Unenrolled')
    end

    within("#evidence-stats-overall h4.text-success") do
      page.should have_content('0/0')
    end
    within("#evidence-stats-overall h4.text-danger") do
      page.should have_content('0/0')
    end
    # within("#evidence-stats-last7 h4.text-success") do
    #   page.should have_content('0/0')
    # end
    # within("#evidence-stats-last7 h4.text-danger") do
    #   page.should have_content('0/0')
    # end
    within("#lo-pie") do
      page.should have_content('0 - High Performance')
      page.should have_content('0 - Proficient')
      page.should have_content('0 - Not Yet Proficient')
      page.should have_content('0 - Unrated')
    end

    # no tests for Missing Evidence yet - #missing-evid
    # within("#missing-evidd") do
    #   page.should have_content('????')
    # end

    # ensure deactivated enrollment doesn't show on page
    page.should_not have_selector("#lo-progress tr[data-lo-prog-id='#{@section1_1.id}']")
  end

  def transferred_student_dashboard_is_valid
    visit student_path(@enrollment_transferred.student.id)
    assert_equal("/students/#{@enrollment_transferred.student.id}", current_path)
    within("h2.h1.page-title") do
      page.should have_content('Student: Student Transferred')
    end

    within("#evidence-stats-overall h4.text-success") do
      page.should have_content('12/24')
    end
    within("#evidence-stats-overall h4.text-danger") do
      page.should have_content('12/24')
    end
    # within("#evidence-stats-last7 h4.text-success") do
    #   page.should have_content('12/24')
    # end
    # within("#evidence-stats-last7 h4.text-danger") do
    #   page.should have_content('12/24')
    # end
    within("#lo-pie") do
      page.should have_content('1 - High Performance')
      page.should have_content('1 - Proficient')
      page.should have_content('1 - Not Yet Proficient')
      page.should have_content('1 - Unrated')
    end
    # no tests for Missing Evidence yet - #missing-evid
    # within("#missing-evidd") do
    #   page.should have_content('????')
    # end
    # page.should have_selector("#lo-progress")
    # within("#lo-progress") do
    #   page.should_not have_css("tr[data-lo-prog-id='#{@section.id}']")
    # end
    page.should have_selector("#lo-progress tr[data-lo-prog-id='#{@section1_1.id}']")
    within("tr[data-lo-prog-id='#{@section1_1.id}']") do
      page.should have_content("#{@section1_1.name} | #{@teacher1.last_name}")
      page.should have_content("2/3")
      page.should have_content("of 4")
    end
  end


  def out_student_dashboard_is_valid
    visit student_path(@enrollment_out.student.id)
    assert_equal("/students/#{@enrollment_out.student.id}", current_path)
    within("h2.h1.page-title") do
      page.should have_content('Student: Student Out')
    end

    within("#evidence-stats-overall h4.text-success") do
      page.should have_content('0/0')
    end
    within("#evidence-stats-overall h4.text-danger") do
      page.should have_content('0/0')
    end
    # within("#evidence-stats-last7 h4.text-success") do
    #   page.should have_content('0/0')
    # end
    # within("#evidence-stats-last7 h4.text-danger") do
    #   page.should have_content('0/0')
    # end
    within("#lo-pie") do
      page.should have_content('0 - High Performance')
      page.should have_content('0 - Proficient')
      page.should have_content('0 - Not Yet Proficient')
      page.should have_content('0 - Unrated')
    end
    # no tests for Missing Evidence yet - #missing-evid
    # within("#missing-evidd") do
    #   page.should have_content('????')
    # end

    # ensure deactivated enrollment doesn't show on page
    page.should_not have_selector("#lo-progress tr[data-lo-prog-id='#{@section1_1.id}']")
  end


  def new_student_dashboard_is_valid
    visit student_path(@enrollment_new.student.id)
    assert_equal("/students/#{@enrollment_new.student.id}", current_path)
    within("h2.h1.page-title") do
      page.should have_content('Student: Student New')
    end

    within("#evidence-stats-overall h4.text-success") do
      page.should have_content('0/0')
    end
    within("#evidence-stats-overall h4.text-danger") do
      page.should have_content('0/0')
    end
    # within("#evidence-stats-last7 h4.text-success") do
    #   page.should have_content('0/0')
    # end
    # within("#evidence-stats-last7 h4.text-danger") do
    #   page.should have_content('0/0')
    # end
    within("#lo-pie") do
      page.should have_content('0 - High Performance')
      page.should have_content('0 - Proficient')
      page.should have_content('0 - Not Yet Proficient')
      page.should have_content('0 - Unrated')
    end
    # no tests for Missing Evidence yet - #missing-evid
    # within("#missing-evidd") do
    #   page.should have_content('????')
    # end
    page.should have_selector("#lo-progress tr[data-lo-prog-id='#{@section1_1.id}']")
    within("tr[data-lo-prog-id='#{@section1_1.id}']") do
      page.should have_content("#{@section1_1.name} | #{@teacher1.last_name}")
      page.should_not have_content("0/0")
      page.should have_content("of 4")
    end
  end


end
