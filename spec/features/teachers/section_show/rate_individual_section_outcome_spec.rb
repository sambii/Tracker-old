require 'spec_helper'

describe "SectionShows", js: true do
  before do
    @section_outcome = create :section_outcome
    @section = @section_outcome.section
    school = @section.school

    @teacher = create :teacher, school: school
    create :teaching_assignment, teacher: @teacher, section: @section
    @student = create :student, school: school
    create :enrollment, student: @student, section: @section

    
  end
  subject { page }

  context "updates a valid evidence rating" do
    before do
        @sor = create :section_outcome_rating, section_outcome: @section_outcome, rating: "P", student: @student
        sign_in @teacher
        visit section_path(@section)
    end
    it do
        
        find("#s_o_r_#{@sor.id}").click
        
        find("#popup_form").should have_content("Rate #{@student.first_name} #{@student.last_name} on #{@section_outcome.name}")
        
        select("Not Yet Proficient", from: "section_outcome_rating_rating")
        click_button "Rate"
        should have_selector "#s_o_r_#{@sor.id}", text: "N"
    end
  end

  context "creates a valid evidence rating" do
    before do
        sign_in @teacher
        visit section_path(@section)
    end
    it do
        should have_selector "#s_o_r_0", text: 'U'
        
        find("#s_o_r_0").click

        should have_selector "#popup_form",
            text: "Rate #{@student.first_name} #{@student.last_name} on #{@section_outcome.name}"
        should have_selector("select#section_outcome_rating_rating")
        
        select("Proficient", from: "section_outcome_rating_rating")
        click_button "Rate"
        
        should have_selector ".r.s_o_r", text: "P"
    end
  end
end