require 'spec_helper'

describe "UpdateSubjectOutcomes" do
  before  do
    @school = create :school

    @teacher = create :teacher, school: @school

    @subject = create :subject, subject_manager: @teacher
    @section = create :section, school: @school, subject: @subject
    
    create :teaching_assignment, teacher: @teacher, section: @section
  end

  context "displays edit link to subject manager", js: true do
    before do
      sign_in @teacher
      visit section_path(@section)
    end
    it do
      find("#tools").click
      find("#tools_new_section_outcome").click
      find("div#popup_form").should have_link 'edit'
    end
  end

  context "does not display edit link to non-subject manager", js: true do
    before do
      @teacher2 = create :teacher, school: @school
      create :teaching_assignment, teacher: @teacher2, section: @section
      sign_in @teacher2
      visit section_path @section
    end
    it do
      find("#tools").click
      find("#tools_new_section_outcome").click
      find("div#popup_form").should_not have_link 'edit'
    end
  end

  context "updates subject outcomes", js: true do
    let(:lo_name) { Faker::Company.name }
    before do
      sign_in @teacher
      visit edit_subject_outcomes_subject_path @subject

      fill_in 'subject_subject_outcomes_attributes_0_name', with: lo_name
      click_button("Add Learning Outcome")
      click_button "Update Subject"

      visit section_path @section
    end
    it do
      find("#tools").click
      find("#tools_new_section_outcome").click
      # right now the element is in a SPAN if there is only one but a li if there are
      # more than one learning outcomes. This should change with the UI redesign
      find('div#popup_form').should have_selector 'span', text: lo_name
    end
  end
end