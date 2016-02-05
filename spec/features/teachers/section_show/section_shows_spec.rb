require 'spec_helper'

describe "SectionShows" do
  before do
    @section = create :section
    @school = @section.school

    @teacher = @section.subject.subject_manager #set teacher to subjects' manager
    create :teaching_assignment, teacher: @teacher, section: @section
  end

  subject { page }

  context "does not show inactive students" do
    before do
      @student = create :student, school: @school, active: false
      create :enrollment, student: @student, section: @section

      sign_in @teacher
      visit section_path(@section)
    end
    it { should_not have_content(@student.first_name) }
  end


  context "shows the section to a signed in teacher" do
    before do
      sign_in @teacher
      visit section_path(@section)
    end
    it { should have_content(@section.name + ": " + @section.line_number) }
  end

  context "creates a student", js: true do
    let (:first_name) { Faker::Name.first_name }
    let (:last_name) { Faker::Name.last_name }
    before do
      sign_in @teacher
      visit section_path(@section)

      find("#tools").click
      find("#tools_new_enrollment").click
      click_button "Create Student in School"
      fill_in "student_xid", with: "ID5412"
      fill_in "student_first_name", with: first_name
      fill_in "student_last_name", with:  last_name
      select "Male", from: "student_gender"
      select "9", from: "student_grade_level"
      click_button "Add Student"

      # removed because of timing problem
      # visit section_path(@section)

      find("#tools").click
      find("#tools_new_enrollment").click
      click_button "Enroll Student in Section"
    end
    it do
      should have_selector ".student > div", text: first_name
      should have_selector ".student > div", text: last_name
    end
  end

  # TODO Finish this test.
  context "rates a section outcome", js: true do
    before do
      @section_outcome = create :section_outcome, section: @section
      sign_in @teacher
      visit section_path(@section)
    end
    it do 
      should have_content(@section_outcome.name)
      find("#section_outcome_1").click
      should have_content("Rate #{@section_outcome.name}")
    end
  end

  context "rates an evidence", js: true do
   before do
      @section_outcome = create :section_outcome, section: @section
      @evidence = create :evidence, section: @section
      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence
      @id = @evidence.id
      
      student = create :student, school: @school
      create :enrollment, student: student, section: @section

      sign_in @teacher
      visit section_path(@section)
    end
    it do
      should have_content(@eso.name)
      
      find("#evidence_#{@id}").find(".evidence_name").click
      should have_content("Rate #{@evidence.name}")

      fill_in 'rating_0', with: "G"
      fill_in 'comment_0', with: "Good work."
      click_button 'Rate Evidence'
    
      find(".r.e_r").should have_content("G")
    end
  end

  context "updates an evidence section outcome", js: true do
    before do
      @first_outcome = create :section_outcome, section: @section
      @second_outcome = create :section_outcome, section: @section
      @name = @second_outcome.name

      @eso = create :evidence_section_outcome, section_outcome: @first_outcome
      @id = @eso.id

      sign_in @teacher
      visit section_path(@section)

      # Fill out the form to move the section outcome.
      find("#evidence_#{@id}").find(".evidence_section_outcome").click
      find("#popup_form").should have_content("Edit #{@eso.name} Learning Outcome")
      select @name, from: "evidence_section_outcome_section_outcome_id"
      find("#popup_form").find("button[type=submit]").click
    end

    it "should move the evidence section outcome on the section#show"  do
      should_not have_selector "#section_outcome_evidences_left_#{@first_outcome.id} #evidence_#{@id}"
      should have_selector "#section_outcome_evidences_left_#{@second_outcome.id} #evidence_#{@id}"
    end
  end

  context "updates an evidence type", js: true do
    before do
      @e_type_2 = create :evidence_type

      @evidence = create :evidence, section: @section
      section_outcome = create :section_outcome, section: @section
      @eso = create :evidence_section_outcome, section_outcome: section_outcome, evidence: @evidence
      @eso_type_name = @eso.evidence.evidence_type.name

      sign_in @teacher
      visit section_path(@section)
    end
    it do
      should have_selector "#evidence_#{@eso.id} .evidence_type", text: @eso_type_name
      find("#evidence_#{@eso.id} .evidence_type").click
      
      should have_content("Evidence Type")

      find_field("evidence_evidence_type_id").value.should eq(@eso.evidence.evidence_type.id.to_s)
      select @e_type_2.name, from: "evidence_evidence_type_id"
      click_button "Update Evidence"
    
      should have_selector "#evidence_#{@eso.id} .evidence_type", text: @e_type_2.name
    end
  end

  context "updates a valid evidence rating", js: true do
    before do
      @section_outcome = create :section_outcome, section: @section
      @evidence = create :evidence, section: @section

      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence
      
      @student = create :student, school: @school
      create :enrollment, student: @student, section: @section

      @esor = create :evidence_section_outcome_rating, evidence_section_outcome: @eso, rating: "Y", comment: "Mediocre", student: @student
      @id = @esor.id

      sign_in @teacher
      visit section_path(@section)
    end
    
    it do
      find("#e_r_#{@id}").should have_content("Y")
      find("#e_r_#{@id}").click
     
      find("#popup_form").should have_content("Rate #{@student.first_name} #{@student.last_name} on #{@eso.shortened_name}, #{@section_outcome.shortened_name}")
      should have_selector("input[type=text][value=Y]")
      find("#popup_form").should have_content "Mediocre"
      
      #change rating
      comment = "Great work! Much improved."
      fill_in "evidence_section_outcome_rating_rating", with: "B"
      fill_in "evidence_section_outcome_rating_comment", with: comment
      click_button "Rate"

      find("#e_r_#{@id}").click
      should have_selector("input[type=text][value=B]")
      find("#popup_form").should have_content comment
    end
  end

  context "updates an invalid evidence rating", js: true do
    before do
      @section_outcome = create :section_outcome, section: @section
      @evidence = create :evidence, section: @section
      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence
      
      @student = create :student, school: @school
      create :enrollment, student: @student, section: @section

      @esor = create :evidence_section_outcome_rating, evidence_section_outcome: @eso, rating: "Y", comment: "Mediocre", student: @student
      
      #Invalid rating (duplicate student)
      @invalid = build :evidence_section_outcome_rating, evidence_section_outcome: @eso, rating: "G", comment: "Bad Rating", student: @student
      @invalid.save(validate: false)
      @id = @invalid.id

      sign_in @teacher
      visit section_path(@section)
    end

    # Update the evidence rating by filling out the AJAX form for a single rating.
    it do
      find("#e_r_#{@id}").should have_content("G")
      find("#e_r_#{@id}").click
      should have_selector("input[type=text][value=G]")
      find("#popup_form").should have_content "Bad Rating"

      new_comment = "Go Home Now"
      fill_in "evidence_section_outcome_rating_rating", with: "B"
      fill_in "evidence_section_outcome_rating_comment", with: new_comment
      click_button "Rate"

      find("#e_r_#{@id}").click
      should have_selector("input[type=text][value=B]")
      find("#popup_form").should have_content new_comment

    end
  end

  context "properly displays the attachment / hyperlink count", js: true do
    before do
      @section_outcome = create :section_outcome, section: @section
      @evidence = create :evidence, section: @section
      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence
      @id = @eso.id

      @student = create :student, school: @school
      create :enrollment, student: @student, section: @section
      
      create :evidence_attachment, evidence: @evidence

      sign_in @teacher
      visit section_path(@section)
    end
    it { should have_selector "td#evidence_#{@id} .evidence_attachments", text: '1' }
  end

  context "creates hyperlinks", js: true do
    before do
      @section_outcome = create :section_outcome, section: @section  
      @evidence = create :evidence, section: @section
      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence
      @id = @eso.id

      @student = create :student, school: @school
      create :enrollment, student: @student, section: @section
      
      sign_in @teacher
      visit section_path(@section)
    end
    it do
      find("td#evidence_#{@id}").find(".evidence_attachments").click
      should have_content("Current Hyperlinks")
      should have_content("Add Hyperlinks")
      fill_in "evidence_evidence_hyperlinks_attributes_30_hyperlink", with: "economist.com"
      fill_in "evidence_evidence_hyperlinks_attributes_30_title", with: "Economist"
      click_button "Add Another Hyperlink"
      fill_in "evidence_evidence_hyperlinks_attributes_31_hyperlink", with: "wsj.com"
      fill_in "evidence_evidence_hyperlinks_attributes_31_title", with: "Wall Street Journal"
      click_button "Update Evidence"

      find("td#evidence_#{@id}").find(".evidence_attachments").click
      #should have_selector '.report td', text: 'http://economist.com'
      should have_selector '.report td', text: 'Economist'
      #should have_selector '.report td', text: 'http://wsj.com'
      should have_selector '.report td', text: 'Wall Street Journal'
      should have_selector "td#evidence_#{@id} .evidence_attachments", text: '2'
    end
  end

  context "removes hyperlinks", js: true do
    before do
      @section_outcome = create :section_outcome, section: @section
      @evidence = create :evidence, section: @section
      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence
      @id = @eso.id

      @student = create :student, school: @school
      create :enrollment, student: @student, section: @section
      
      att = create :evidence_hyperlink, evidence: @evidence
      @att_id = att.id

      sign_in @teacher
      visit section_path(@section)
    end
    it do
      find("td#evidence_#{@id}").find(".evidence_attachments").click
      
      check "evidence_hyperlink_#{@att_id}_remove"
      click_button "Update Evidence"
      should have_selector "td#evidence_#{@id} .evidence_attachments", text: '0'
    end
  end

  context "sets the section message", js: true do
     before do
      sign_in @teacher
      visit section_path(@section)
    end
    it do
      find("#edit_section_message").click
      find("#popup_form").should have_content("Edit Section Message")
      m = "Good Class"
      fill_in "section_message", with: m
      click_button "Update Section Message"
      should have_selector "div#section_message", text: m
    end
  end

  context "shows a quote bubble if the evidence section outcome rating has a comment", js: true do
     before do
      @section_outcome = create :section_outcome, section: @section
      @evidence = create :evidence, section: @section
      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence

      @student = create :student, school: @school
      create :enrollment, student: @student, section: @section

      @esor = create :evidence_section_outcome_rating, evidence_section_outcome: @eso, rating: "Y", comment: "Mediocre", student: @student
      
      sign_in @teacher
      visit section_path(@section)
    end
    it do
      find("td#e_r_#{@esor.id}")['c'].should eq("t")
      page.execute_script("return $('td#e_r_#{@esor.id}').css('background-image');").should include("comment.png")
    end
  end

  context "toggles a quote bubble when the comment stage is changed via evidence rating", js: true do
    before do
      @section_outcome = create :section_outcome, section: @section
      @evidence = create :evidence, section: @section
      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence

      @student = create :student, school: @school
      create :enrollment, student: @student, section: @section

      @esor = create :evidence_section_outcome_rating, evidence_section_outcome: @eso, rating: "Y", comment: "Mediocre", student: @student
      
      sign_in @teacher
      visit section_path(@section)
    end
    
    it do
      # Remove the comment from the rating and check to see that the bubble disappeared.
      find("td#e_r_#{@esor.id}").click
      fill_in "evidence_section_outcome_rating_rating", with: "G"
      fill_in "evidence_section_outcome_rating_comment", with: ""
      click_button "Rate"
      find("td#e_r_#{@esor.id}")['c'].should eq("f")
      page.execute_script("return $('td#e_r_#{@esor.id}').css('background-image');").should eq("none")

      # Add comment again
      find("td#e_r_#{@esor.id}").click
      fill_in "evidence_section_outcome_rating_rating", with: "B"
      fill_in "evidence_section_outcome_rating_comment", with: "Yak yak"
      click_button "Rate"
      find("td#e_r_#{@esor.id}")['c'].should eq("t")
      page.execute_script("return $('td#e_r_#{@esor.id}').css('background-image');").should include("comment.png")
    end
  end

  context "toggles a quote bubble when rating state is changed via evidence section outcome", js: true do
    before do
      @section_outcome = create :section_outcome, section: @section
      @evidence = create :evidence, section: @section
      
      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence
     
      @student = create :student, school: @school
      create :enrollment, student: @student, section: @section

      @esor = create :evidence_section_outcome_rating, evidence_section_outcome: @eso, rating: "Y", comment: "Mediocre", student: @student
      
      sign_in @teacher
      visit section_path(@section)
    end
    it do
      find("#evidence_#{@eso.id} .evidence_name").click
      
      #change exitsing
      fill_in 'rating_0', with: "G" 
      fill_in 'comment_0', with: "" 
     
      click_button 'Rate Evidence'
      
      should have_selector ".r.e_r", text: "G"  
    end
  end

  context "unrates all students in a given learning outcome", js: true do
    before do
      @section_outcome = create :section_outcome, section: @section
      @evidence = create :evidence, section: @section
      
      @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence
     
      @student = create :student, school: @school
      create :enrollment, student: @student, section: @section
      @student2 = create :student, school: @school
      create :enrollment, student: @student2, section: @section

      @esor = create :evidence_section_outcome_rating, evidence_section_outcome: @eso, rating: "Y", student: @student
      @esor = create :evidence_section_outcome_rating, evidence_section_outcome: @eso, rating: "Y", student: @student2
      
      sign_in @teacher
      visit section_path(@section)
    end
    it do
      find("#section_outcome_#{@section_outcome.id}").click
      select "Unrate All Students", from: "batch_rating"
      click_button "Apply"
      page.all(:css, "select.section_outcome_rating").each do |element|
        element.value.should eq("U")
      end
    end
  end
  pending "missing the test for the quote bubble. Will test for class in New UI Code"
end