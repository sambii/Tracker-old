require 'spec_helper'

describe Section do
	before do
		@section = create :section
	end

	subject { @section }

	it { should be_valid }
	
	test_has_relationships [:teaching_assignments, :teachers, :subject, 
		:school, :enrollments, :students, :section_outcomes, :section_outcome_ratings, 
		:evidences, :inactive_evidences, :evidence_section_outcomes, :evidence_section_outcome_ratings, 
		:school_year]

	test_has_fields [:line_number, :subject_id, :message, :position, :selected_marking_period, :school_year_id]

	test_responds_to_methods [:active_evidences, :active_students, :subsections, 
		:hash_of_section_outcome_ratings, :hash_of_evidence_ratings, :name, 
		:full_name, :teacher_names, :count_ratings_by_outcome, :count_ratings, 
		:count_of_rated_evidence_section_outcomes, :grading_algorithm, :grading_scale, 
		:array_of_evidence_section_outcome_ratings ]

	#validations

	context "when line number is not present" do
		before { @section.line_number = " "}
		it { should_not be_valid }
	end

	context "when subject is not present" do
		before { @section.subject = nil }
		it { should_not be_valid }
	end

	context "when school_year is not present" do
		before { @section.school_year = nil }
		it { should_not be_valid }
	end

	context "on create: when section.subject.school has a different school_year from us" do
		before do 
			@other_school = create :school # will get a different school year on creation
  			@other_subject = create :subject #will get a different school year on creation
  			school_year = create :school_year, school: @other_school
			@section = build :section, subject: @other_subject, school_year: school_year             
  		end

  		it { should_not be_valid }
    end

    context "on update: when section.subject.school has a different school_year from us" do
		before do 
			@other_school = create :school
  			@other_subject = create :subject, school: @other_school	
  			@other_school_year = create :school_year, school: @other_school	
  		end

  		describe "update school_year to be different from our school" do
  			before { @section.update_attributes(school_year: @other_school_year) }
  			it { should be_valid }
  		end

  		describe "update subject to be different from our school" do
  			before { @section.update_attributes(subject: @other_subject) }
  			it { should be_valid }
  		end
    end

end