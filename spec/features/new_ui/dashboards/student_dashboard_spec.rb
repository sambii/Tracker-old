# student_dashboard_spec.rb
require 'spec_helper'


describe "Student Dashboard", js:true do
  before (:each) do
    @section = FactoryGirl.create :section
    @teacher = FactoryGirl.create :teacher, school: @section.school
    load_test_section(@section, @teacher)
    # todo - add prior/next year section
  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    # it { student_dashboard_is_valid } # student active and enrolled.
    # it { unenrolled_student_dashboard_is_valid } # student active, but unenrolled.
    # it { transferred_student_dashboard_is_valid } # student deactivated, but still enrolled.
    # it { out_student_dashboard_is_valid } # student deactivated, and unenrolled.
    # it { new_student_dashboard_is_valid } # student active and enrolled with no ratings.
    it { all_student_dashboards_are_valid }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @section.school
      sign_in(@school_administrator)
    end
    it { student_dashboard_is_valid }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@section.school)
    end
    it { student_dashboard_is_valid }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section.school)
    end
    it { student_dashboard_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { student_dashboard_is_valid }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { student_dashboard_is_valid }
  end

  ##################################################
  # test methods

  # def can_see_student_dashboard
  #   visit student_path(@student.id)
  #   assert_equal("/students/#{@student.id}", current_path)
  # end

  def all_student_dashboards_are_valid
    # run all students under one test, to prevent reloading test data repeatedly.
    # can_see_student_dashboard
    student_dashboard_is_valid
    unenrolled_student_dashboard_is_valid
    transferred_student_dashboard_is_valid
    out_student_dashboard_is_valid
    new_student_dashboard_is_valid
  end

  def student_dashboard_is_valid
    visit student_path(@student.id)
    assert_equal("/students/#{@student.id}", current_path)
    within("#evidence-stats-overall h4.text-success") do
      page.should have_content('12/24')
    end
    within("#evidence-stats-overall h4.text-danger") do
      page.should have_content('12/24')
    end
    within("#evidence-stats-last7 h4.text-success") do
      page.should have_content('0/0')
    end
    within("#evidence-stats-last7 h4.text-danger") do
      page.should have_content('0/0')
    end
    within("#lo-pie") do
      page.should have_content('1 - High Performance')
      page.should have_content('1 - Proficient')
      page.should have_content('1 - Not Yet Proficient')
      page.should have_content('1 - Unrated')
    end

    # ensure deactivated enrollment doesn't show on page
    page.should_not have_content('Deactivated')

    # no tests for Missing Evidence yet - #missing-evid
    # within("#missing-evidd") do
    #   page.should have_content('????')
    # end
    page.should have_selector("#lo-progress tr[data-lo-prog-id='#{@section.id}']")
    within("tr[data-lo-prog-id='#{@section.id}']") do
      page.should have_content("#{@section.name} | #{@teacher.last_name}")
      page.should have_content("2/3")
      page.should have_content("of 4")
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
    within("#evidence-stats-last7 h4.text-success") do
      page.should have_content('0/0')
    end
    within("#evidence-stats-last7 h4.text-danger") do
      page.should have_content('0/0')
    end
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
    #   page.should_not have_css("tr[data-prof-bar-so-id='#{@section.id}']")
    # end
    page.should have_selector("#lo-progress tr[data-lo-prog-id='#{@section.id}']")
    within("tr[data-lo-prog-id='#{@section.id}']") do
      page.should have_content("#{@section.name} | #{@teacher.last_name}")
      page.should have_content("2/3")
      page.should have_content("of 4")
    end
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
    within("#evidence-stats-last7 h4.text-success") do
      page.should have_content('12/24')
    end
    within("#evidence-stats-last7 h4.text-danger") do
      page.should have_content('12/24')
    end
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
    page.should have_selector("#lo-progress tr[data-lo-prog-id='#{@section.id}']")
    within("tr[data-lo-prog-id='#{@section.id}']") do
      page.should have_content("#{@section.name} | #{@teacher.last_name}")
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
    within("#evidence-stats-last7 h4.text-success") do
      page.should have_content('0/0')
    end
    within("#evidence-stats-last7 h4.text-danger") do
      page.should have_content('0/0')
    end
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
    #   page.should_not have_css("tr[data-prof-bar-so-id='#{@section.id}']")
    # end
    page.should have_selector("#lo-progress tr[data-lo-prog-id='#{@section.id}']")
    within("tr[data-lo-prog-id='#{@section.id}']") do
      page.should have_content("#{@section.name} | #{@teacher.last_name}")
      page.should have_content("2/3")
      page.should have_content("of 4")
    end
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
    within("#evidence-stats-last7 h4.text-success") do
      page.should have_content('0/0')
    end
    within("#evidence-stats-last7 h4.text-danger") do
      page.should have_content('0/0')
    end
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
    page.should have_selector("#lo-progress tr[data-lo-prog-id='#{@section.id}']")
    within("tr[data-lo-prog-id='#{@section.id}']") do
      page.should have_content("#{@section.name} | #{@teacher.last_name}")
      page.should_not have_content("0/0")
      page.should have_content("of 4")
    end
  end


end
