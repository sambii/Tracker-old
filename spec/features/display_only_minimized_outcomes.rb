require 'spec_helper'
# To Improve performance, we will render only the evidence for maximized
# section outcomes.

shared_examples "section" do
	 before do 
		sign_in user
		visit section_path(@section)
	 end
	 
	 it "render child evidences in the DOM only if learning outcome is maximized" do
		# It is my desire that the selector be defined once, to ensure we are reusing the same
		# selector to confirm that the element is there and NOT there.
		# This pattern stores the selector lazily then calls eval when we have the variables it needs.
		selector_left  = '#section_outcome_table_left_#{id} #evidence_left_row_#{evidence.id}'
		selector_right = '#section_outcome_table_right_#{id} #evidence_right_row_#{evidence.id}'

		@section.section_outcomes.each do |section_outcome|
			id = section_outcome.id
			minimized = section_outcome.minimized?

			if minimized
				# check that no evidences render under this minimized section outcome
				section_outcome.evidence_section_outcomes.each do |evidence|
					page.should_not have_selector eval %Q|"#{selector_left}"|
					page.should_not have_selector eval %Q|"#{selector_right}"|
					
					# safeguard: only 1 element should exist under the evidence, in case the match above is no longer valid
					# this singular element is the placeholder element used later to load the evidence on demand
					page.should have_selector "#section_outcome_table_left_#{id} .evidence tr", count: 1
					page.should have_selector "#section_outcome_table_right_#{id} .evidence tr", count: 1
				end
			else 
				# check that all evidences are rendered for maximized section outcomes
				section_outcome.evidence_section_outcomes.each do |evidence|
					
					page.should have_selector eval %Q|"#{selector_left}"|
					page.should have_selector eval %Q|"#{selector_right}"|
				end
			end
		end
	end

	it "get children evidences after clicking minimized learning outcome" do
		selector_left = '#section_outcome_table_left_#{id} #evidence_left_row_#{evidence.id}'
		selector_right = '#section_outcome_table_right_#{id} #evidence_right_row_#{evidence.id}'
		@section.section_outcomes.each do |section_outcome|
			id = section_outcome.id
			minimized = section_outcome.minimized?
			if minimized
				find("#section_outcome_table_left_#{id} .section_outcome_toggle").click
				section_outcome.evidence_section_outcomes.each do |evidence|	
					page.should have_selector eval %Q|"#{selector_left}"|
					page.should have_selector eval %Q|"#{selector_right}"|
				end
			end
		end
	end
end

describe "Section outcomes", js:true do 
	before do

		@section 	= create :section
		subject 	= @section.subject
		school 		= @section.school
		
		@teacher 	= create :teacher, school: school
		create :teaching_assignment, teacher: @teacher, section: @section
		
		@school_administrator = create :school_administrator, school: school

		# @researcher = create :researcher
		
		student 	= create :student, school: school
		create :enrollment, section: @section, student: student
	    
		#additional data setup
		subject_outcomes = []
		4.times do
			subject_outcomes << create(:subject_outcome, subject: subject)
	    end

	    section_outcomes = []  
	    subject_outcomes.each do |subject_outcome|
	    	Random.rand(1000) % 2 == 0 ? m = true : m = false #random minimization algorithim
	    	section_outcomes << create(:section_outcome, section: @section, 
	    		subject_outcome: subject_outcome, minimized: m)
	    end

	    evidences = []
	    3.times do
	    	evidences << create(:evidence, section: @section)
	    end

	    section_outcomes.each do |section_outcome|
	    	evidences.each do |evidence|
	    		create :evidence_section_outcome, section_outcome: section_outcome, evidence: evidence
	    	end
	    end
	end
	
    describe "as teacher" do
    	let(:user) { @teacher }
    	it_behaves_like "section" 
    end

    describe "as school administrator" do
    	let(:user) { @school_administrator }
    	it_behaves_like "section"
    end

    pending "test researchers can minimize/maximize LOs without db update."
    # cant do this test, tests for the value in the record
    # which is not updated by researchers.
    # do manual test for now, till test is modified, or custom test for researcher
    # describe "as researcher" do
    # 	let(:user) { @researcher }
    # 	it_behaves_like "section"
    # end   
end

