require 'spec_helper'

describe 'EvidenceMovements', js:true do
	before do
		
		@section = create :section
		@school =  @section.school
		@subject = @section.subject
        
        #additional data setup
		subject_outcomes = create_list :subject_outcome, 1, subject: @subject
	  
	    @section_outcomes = []  
	    subject_outcomes.each do |subject_outcome|
	    	@section_outcomes << FactoryGirl.create(:section_outcome, section:@section,
	    	            subject_outcome:subject_outcome, minimized: true)
	    end

	    evidences = create_list :evidence, 3, section:@section
	   
	    @section_outcomes.each do |section_outcome|
	    	evidences.each do |evidence|
	    		FactoryGirl.create(:evidence_section_outcome, section_outcome:section_outcome,
	    		evidence:evidence)
	    	end
	    end

	    @teacher = create :teacher, school: @school
	    create :teaching_assignment, teacher: @teacher, section: @section

		sign_in @teacher
		visit section_path(@section)	
	end

	context "drag and drop" do
		before do 
			#get the first minimized lo
			lo = @section_outcomes.first
			id = lo.id
		
			#get the proper order of evidences from db
			initial_evidences_ordered = get_evidences_by_order lo
			last_id  = initial_evidences_ordered[2].id
			first_id = initial_evidences_ordered[0].id
	
			#maximize
			find("#section_outcome_table_left_#{id} .section_outcome_toggle").click

			#drag and drop : last to first?
			dragable   = find("#evidence_left_row_#{last_id}")
			dropable   = find("#evidence_left_row_#{first_id}")
			dragable.drag_to(dropable)

			#refresh
			visit current_path

			#get all evidences in UI for this LO, in order
			@actual_evidences = all("#section_outcome_table_left_#{id} .evidence.left")
			
			#for each returned element, get it's id string, then split that by '_'. 
			#The last element split returns is the numeric id of the evidence
			@actual_evidences.map! { |e| e[:id].split('_').last.to_i }

			#get expected order in db
			@expected_evidences = get_evidences_by_order lo
			@expected_evidences.map!(&:id) #return the id's of all the expected evidences
		end

		pending { @actual_evidences.should == @expected_evidences }
	end

	context "deleted evidence" do
		before do 
			#get the first minimized lo
			lo = @section_outcomes.first
			id = lo.id
		
			# get the evidences of this from db
			@evidences = get_evidences_by_order lo
			@evidences.map!(&:id) #return the id's of all the expected evidences
			e_id = @evidences.last # to be deleted

			# maximize the lo
			find("#section_outcome_table_left_#{id} .section_outcome_toggle").click
		
			# delete one of the evidences of the learning outcome
			@selector = "#evidence_left_row_#{e_id} .evidence_x"
			find(@selector).click
			page.driver.browser.switch_to.alert.accept
        end

        it "should not display" do 
			# verify that it is no longer on the screen
			page.should have_no_selector @selector
			# refresh the page
			visit current_path
			# verify that the evidence is still not under this lo
			page.should have_no_selector @selector
		end
	end

	def get_evidences_by_order learning_outcome
		EvidenceSectionOutcome.unscoped.includes(:evidence).where(section_outcome_id:learning_outcome.id, evidences: { active: true }).order("evidence_section_outcomes.position ASC")
	end
end