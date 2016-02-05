require 'spec_helper'

describe "SectionEditsSpec" do
  before  do
    section = create :section
    school = section.school
    
    school.subsection = true
    school.save

    student = create :student, school: school
    create :enrollment, student: student, section: section

    teacher = create :teacher, school: school
    create :teaching_assignment, teacher: teacher, section: section
    sign_in teacher
    visit section_path(section)

    find("#edit_subsections").click
  end

  subject { page }

  describe "content check" do
    it { should have_content "Edit Student Subsections" }
  end

  describe "edits enrollment subsections" do
    before do
 
      fill_in "section_enrollments_attributes_0_subsection", with: 1
      click_button "Update Section"
      #Go back to view the subsection assignment
      find("#edit_subsections").click
    end
    it do
      field = find("#section_enrollments_attributes_0_subsection")
      field.value.should == "1"
    end
  end
end