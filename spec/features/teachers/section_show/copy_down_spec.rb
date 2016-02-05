require 'spec_helper'

describe "CopyDown" do
  before do
    @section = create :section
    @school =  @section.school
    @subject = @section.subject

    @subject_outcome = create :subject_outcome, subject: @subject, position: 1
    @section_outcome = create :section_outcome, subject_outcome: @subject_outcome, 
        section: @section, position: 1
    evidence = create :evidence, section: @section
    @eso = create :evidence_section_outcome, evidence: evidence,
          section_outcome: @section_outcome, position: 1
    # repeat
    @subject_outcome2 = create :subject_outcome, subject: @subject, position: 2
    @section_outcome2 = create :section_outcome, subject_outcome: @subject_outcome2, 
        section: @section, position: 2
    create :evidence_section_outcome, evidence: evidence,
          section_outcome: @section_outcome2, position: 2

    teacher = create :teacher, school: @school
    create :teaching_assignment, teacher: teacher, section: @section
    student = create :student, school: @school
    create :enrollment, student: student, section: @section
    student2 = create :student, school: @school
    create :enrollment, student: student2, section: @section

    sign_in teacher
    visit section_path @section
  end

  it "copies an evidence's rating for one learning outcome into the outcomes below it when down is pressed", js: true do
    find("#evidence_#{@eso.id} .evidence_name").click
    fill_in "rating_0", with: "G"

    page.driver.browser.execute_script("
      var event = $.Event('keydown', {keyCode: 40});
      $('#rating_0').trigger(event);
    ")
    #sleep 0.1
    find("#rating_1").value.should eq("G")
    page.driver.browser.execute_script("
      return $(document.activeElement).attr('id')
     ").should eq("rating_2")
     
    fill_in "rating_2", with: "R"
     page.driver.browser.execute_script("
      var event = $.Event('keydown', {keyCode: 40});
      $('#rating_2').trigger(event);
     ")
    find("#rating_3").value.should eq("R")
  end
end