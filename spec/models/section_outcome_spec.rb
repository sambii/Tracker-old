require 'spec_helper'

describe SectionOutcome do
	before do
		@school = create :school, marking_periods: 5
		@subject = create :subject,school: @school
		@subject_outcome = create :subject_outcome, subject: @subject
		@section = create :section, subject: @subject, school_year: @school.current_school_year
		@section_outcome = build :section_outcome, subject_outcome: @subject_outcome, section: @section, marking_period: 31
	end

	subject { @section_outcome }

	it { should be_valid }

	#relationships
	relationships = [:subject_outcome, :section, :section_outcome_ratings, :evidence_section_outcomes, 
		  			:evidences, :inactive_evidences, :evidence_section_outcome_ratings, :section_outcome_attachments]
	test_has_relationships relationships

    #fields
    fields = [:position]
    test_has_fields fields
   
    #methods
    methods= [:consistent_subject_id, :essential, :hash_of_evidence_ratings, :hash_of_ratings, :name,
    			:shortened_name, :marking_period_array, :marking_period_bitmask!, :count_ratings, :students_by_rating]
    test_responds_to_methods methods

	#validation tests
	describe "when marking period bitmask is too small" do
		before { @section_outcome.marking_period=0 }
		it { should_not be_valid }
	end 

	describe "when marking period bitmask is too large" do
		before { @section_outcome.marking_period = 64 }
		it { should_not be_valid }
	end

	describe "when marking period bitmask is within acceptable range" do
		before { @section_outcome.marking_period = 29 } 
		it { should be_valid }
	end	

	describe "section outcome must be unique in a section" do
		before do
			@section_outcome.save
			@section_outcome_dup = build :section_outcome, subject_outcome: @subject_outcome, section: @section, marking_period: 31 
		end
		it { @section_outcome_dup.should_not be_valid }	
	end	

end