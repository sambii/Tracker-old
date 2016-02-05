require 'spec_helper'

describe 'SchoolAdministratorAssignsSubsections' do
  before do
    @school = create :school
    @school_administrator = create :school_administrator, school: @school
  end

  subject { page }

  it "doesn't show the option to assign students to subsections if not flagged" do
    sign_in @school_administrator
    should_not have_content("Assign Students to Subsections")
  end

  context 'assigns students to subsections if flagged' do
    before do
      @school.subsection = true
      @school.save

      @section = create :section, school: @school, school_year: @school.current_school_year
      @student = create :student, school: @school

      create :enrollment, student: @student, section: @section
      sign_in @school_administrator
    end

    it do
      click_link "Assign Students to Subsections"
      fill_in "school_students_attributes_0_subsection", with: "A"
      click_button "Update Subsections"

      visit section_path @section
      select 'A', from: 'subsections_select'

      should have_selector 'div', text: @student.first_name
      should have_selector 'div', text: @student.last_name
    end
  end
end