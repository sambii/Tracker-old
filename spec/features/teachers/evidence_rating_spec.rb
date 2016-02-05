require 'spec_helper'

describe 'EvidenceRatings', js:true do
	before do

		@section = create :section
		@school =  @section.school
		@subject = @section.subject
        
        #additional data setup
		subject_outcomes = []
		1.times do
			subject_outcomes << FactoryGirl.create(:subject_outcome, 
				subject: @subject)
	    end

	    @section_outcomes = []  
	    subject_outcomes.each do |subject_outcome|
	    	@section_outcomes << FactoryGirl.create(:section_outcome, section: @section,
	    	            subject_outcome:subject_outcome, minimized: true)
	    end

	    evidences = []
	    1.times do
	    	evidences << FactoryGirl.create(:evidence, section: @section)
	    end

	    @section_outcomes.each do |section_outcome|
	    	evidences.each do |evidence|
	    		FactoryGirl.create(:evidence_section_outcome, section_outcome:section_outcome,
	    		evidence:evidence)
	    	end
	    end

	    teacher = create :teacher, school: @school
	    create :teaching_assignment, teacher: teacher, section: @section

	    student = create :student, school: @school
	    create :enrollment, student: student, section: @section

	    sign_in teacher
		visit section_path(@section)
	end

	context "singular rating" do
		before do
			lo =  @section_outcomes.first
			lo_id = lo.id
			#maximize
			find("#section_outcome_table_left_#{lo_id} .section_outcome_toggle").click
			#get evidence for this lo
			e_id = lo.evidence_section_outcomes.first.id
			#click the evidence
			@evidence_rating = find("#evidence_right_row_#{e_id} .r.e_r")
			@evidence_rating.click
			#rate it
			@rating = 'B'
			find("#evidence_section_outcome_rating_rating").set @rating
			#add a comment
			find("#evidence_section_outcome_rating_comment").set 'c'
			#save
			find("input[value='Rate']").click
		end

		it "should get saved" do
			@evidence_rating.should have_content(@rating)
			#refresh page
			visit current_path
			#rating should still be the same
			@evidence_rating.should have_content(@rating)
		end

	end
end