require 'spec_helper'

describe "SchoolYearManagementSpec" do
  before :each do
    @section = create :section
    #setup a section in the same school as @section, but with different school years
    #@old_section automatically got a different school_year on creation
    @old_section = create :section
    @old_section.school = @section.school
    @old_section.save

    @student = create :student, school: @section.school
    @old_enrollment = create :enrollment, student: @student, section: @old_section
    @enrollment = create :enrollment, student: @student, section: @section
  end
  
  context "displays the correct sections on a student's dashboard" do
    before do
      sign_in @student
      visit user_path @student
    end
    it do
      page.find("#current_sections").should have_selector("a[href='#{enrollment_path(@enrollment)}']")
      page.find("#current_sections").should_not have_selector("a[href='#{enrollment_path(@old_enrollment)}']")
      page.find("#old_sections").should_not have_selector("a[href='#{enrollment_path(@enrollment)}']")
      page.find("#old_sections").should have_selector("a[href='#{enrollment_path(@old_enrollment)}']")
    end
  end

  describe "Teacher" do
    before do
      @teacher = create :teacher, school: @section.school
      create :teaching_assignment, section: @old_section, teacher: @teacher
      create :teaching_assignment, section: @section, teacher: @teacher
    end

    context "displays the correct sections on a teacher's dashboard" do
      before do
        sign_in @teacher, @teacher.password
        visit user_path @teacher
      end
      it do
        page.find("#active_sections").should have_selector("a[href='#{section_path(@section)}']")
        page.find("#active_sections").should_not have_selector("a[href='#{section_path(@old_section)}']")
        page.find("#inactive_sections").should_not have_selector("a[href='#{section_path(@section)}']")
        page.find("#inactive_sections").should have_selector("a[href='#{section_path(@old_section)}']")
      end
    end
  end

  describe 'Parent' do

    before do
      @parent = @student.parents.first
      @parent.password = "password"
      @parent.password_confirmation = "password"
      @parent.temporary_password = nil
      @parent.save
      sign_in @parent
      visit user_path @parent
    end

    it "displays the correct sections on a parent's dashboard" do
      page.find("#current_sections").should have_selector("a[href='#{enrollment_path(@enrollment)}']")
      page.find("#current_sections").should_not have_selector("a[href='#{enrollment_path(@old_enrollment)}']")
      page.find("#old_sections").should_not have_selector("a[href='#{enrollment_path(@enrollment)}']")
      page.find("#old_sections").should have_selector("a[href='#{enrollment_path(@old_enrollment)}']")
    end
  end
end