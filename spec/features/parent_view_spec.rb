require 'spec_helper'

describe 'ParentView' do
  before do
    section = create :section
    school = section.school
    student = create :student, school: school
    create :enrollment, section: section, student: student
    
    @parent = student.parent
    @parent.temporary_password = nil
    @parent.password = 'password'
    @parent.password_confirmation = 'password'
    @parent.save

    sign_in @parent
  end

  subject { page }

  context "shows their child's dashboard" do
    it { should have_content(@parent.child.first_name) }
    it { should have_content(@parent.child.last_name) }
    it do
      @parent.child.enrollments.each do |enrollment|
        page.should have_content(enrollment.section.name)
      end
    end
  end

  context "shows their child's enrollments details" do
    before do
      @section = @parent.child.enrollments.first.section
      page.find("#current_sections").click_link @section.name
    end

    it do
      page.should have_content @section.name
      @section.section_outcomes.each do |section_outcome|
        page.should have_content section_outcome.shortened_name
        section_outcome.evidence_section_outcomes.each do |evidence_section_outcome|
          page.should have_content(evidence_section_outcome.name)
        end
      end
    end
  end
end