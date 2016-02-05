require "spec_helper"

describe "TeacherShows" do
  let (:section) { create :section } # Use let for local variables we need in multiple scopes
  before do
    school = section.school
    school.subsection = true
    school.save

    @teacher = create :teacher, school: school
    create :teaching_assignment, teacher: @teacher, section: section
    
    @student = create :student, school: school

    
  end

  subject { page }

  context "displays subsections if school is flagged" do 
    before do
      create :enrollment, student: @student, section: section, subsection: "1"
      sign_in @teacher
    end

    it do
      page.should have_content section.name
      find("#section_#{section.id}").find(".subsections").should have_content("A")
    end
  end

  context "does not display an error if school is flagged but no students are assigned to subsections" do
    before { sign_in @teacher }
    it do
      should have_content(section.name)
      should_not have_selector(".subsections")
    end
  end

  context "allows teachers to go directly to subsections" do
    before do
      create :enrollment, student: @student, section: section, subsection: "1"
      sign_in @teacher
    end

    it do
      find("#section_#{section.id}").find(".subsections").click_link "A"
      find("#subsections_select").value.should eq("1")
      page.should have_content(@student.last_name)
    end
  end
end

describe "doesn't display subsections if school not flagged" do
    let (:section) { create :section } 
    subject { page }
    before do
      school = section.school

      teacher = create :teacher, school: school
      create :teaching_assignment, teacher: teacher, section: section
    
      student = create :student, school: school
      create :enrollment, student: student, section: section, subsection: "1"

      sign_in teacher 
    end
    it do
      should have_content(section.name)
      should_not have_selector(".subsections")
    end
end