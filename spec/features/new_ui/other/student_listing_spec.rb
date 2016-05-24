# staff_listing_spec.rb
require 'spec_helper'


describe "Student Listing", js:true do
  before (:each) do
    @section = FactoryGirl.create :section
    @school = @section.school
    @teacher = FactoryGirl.create :teacher, school: @school
    @teacher_deact = FactoryGirl.create :teacher, school: @school, active: false
    load_test_section(@section, @teacher)

  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    it { has_valid_student_listing(true, false) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school
      sign_in(@school_administrator)
    end
    it { has_valid_student_listing(true, true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school)
    end
    it { has_valid_student_listing(false, false) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school)
    end
    it { has_valid_student_listing(true, true) }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { has_no_student_listing }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { has_no_student_listing }
  end

  ##################################################
  # test methods

  def has_no_student_listing
    visit students_path
    assert_not_equal("/students", current_path)
  end

  def has_valid_student_listing(can_create, can_deactivate)
    visit students_path
    assert_equal("/students", current_path)
    within("#page-content") do
      page.should have_content("All Students for: #{@school.name}")
      page.should have_css("tr#student_#{@student.id}")
      page.should_not have_css("tr#student_#{@student.id}.deactivated")
      within("tr#student_#{@student.id}") do
        page.should have_content("#{@student.last_name}") if can_create
        page.should_not have_content("#{@student.last_name}") if !can_create
        page.should have_content("#{@student.first_name}") if can_create
        page.should_not have_content("#{@student.first_name}") if !can_create
        page.should have_content("#{@student.email}") if can_create
        page.should_not have_content("#{@student.email}") if !can_create
        page.should have_css("i.fa-dashboard")
        page.should have_css("i.fa-check")
        page.should have_css("i.fa-ellipsis-h")
        page.should have_css("i.fa-edit") if can_create
        page.should_not have_css("i.fa-edit") if !can_create
        page.should have_css("i.fa-unlock") if can_create
        page.should_not have_css("i.fa-unlock") if !can_create
        page.should have_css("i.fa-times-circle") if can_deactivate && @teacher.active == true
        page.should_not have_css("i.fa-times-circle") if !can_deactivate && @teacher.active == true
      end
      page.should have_css("tr#student_#{@student_transferred.id}")
      page.should have_css("tr#student_#{@student_transferred.id}.deactivated")
      within("tr#student_#{@student_transferred.id}") do
        page.should have_content("#{@student_transferred.last_name}") if can_create
        page.should_not have_content("#{@student_transferred.last_name}") if !can_create
        page.should have_content("#{@student_transferred.first_name}") if can_create
        page.should_not have_content("#{@student_transferred.first_name}") if !can_create
        page.should have_content("#{@student_transferred.email}") if can_create
        page.should_not have_content("#{@student_transferred.email}") if !can_create
        page.should have_css("i.fa-undo") if can_create && @student_transferred.active == false
        page.should_not have_css("i.fa-undo") if !can_create && @student_transferred.active == false
      end
    end # within("#page-content") do
  end # def has_valid_subjects_listing


end
