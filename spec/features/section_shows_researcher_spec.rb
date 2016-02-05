require 'spec_helper'

describe "SectionShowsResearcher" do
  before (:each) do
    @section = create :section
    @school = @section.school
    @student = create :student, school: @school
    @researcher = create :researcher
    @teacher = create :teacher, school: @school
    create :enrollment, section: @section, student: @student
  end

  subject { page }

  context "hides student names from researchers" do
    before do
       sign_in(@researcher, @researcher.password)
       visit section_path(@section)
    end
   
    it do
      page.should have_selector("#student_#{@student.id}")
      find("#student_#{@student.id}").should_not have_content(@student.last_name)
      find("#student_#{@student.id}").should_not have_content(@student.first_name)
    end
  end

  context do
    before do
      create :teaching_assignment, section: @section, teacher: @teacher
      sign_in(@teacher, @teacher.password)
      visit section_path(@section)
    end

    it do
      page.should have_selector("#student_#{@student.id}")
      find("#student_#{@student.id}").should have_content(@student.last_name)
      find("#student_#{@student.id}").should have_content(@student.first_name)
    end
  end
end