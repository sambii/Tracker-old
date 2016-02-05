require 'spec_helper'

describe 'ListStudentSections', js: true do
  before do
    @section = create :section
    @school = @section.school

    @teacher = create :teacher, school: @school
    @student = create :student, school: @school

    create :teaching_assignment, teacher: @teacher, section: @section
    create :enrollment, student: @student, section: @section
  end

  context "lists current sections when clicking on a student" do
    before do
      sign_in @teacher
      visit section_path @section
    end
    it do
      find("div#student_#{@student.id}").click
      find("#popup_form").find("#current_sections").should have_content(@section.subject.name)
    end
  end

  context "lists old sections when clicking on a student" do
    before do
      @old_section = create :section, school: @school, school_year: @section.school_year
      #change the school year to an older school year
      @old_section.school_year = create :school_year, school: @school
      @old_section.save
      #assign teacher and student to old section
      create :teaching_assignment, teacher: @teacher, section: @old_section
      create :enrollment, student: @student, section: @old_section

      sign_in @teacher
      visit section_path @section
    end
    it do
      find("div#student_#{@student.id}").click
      find("#popup_form").find("#old_sections").should have_content(@old_section.subject.name)
    end
  end
end