require 'spec_helper'

describe Enrollment do
	before do
		@section = create :section
		@student = create :student, school: @section.school	
		@enrollment = create :enrollment, student: @student, section: @section, student_grade_level: @student.grade_level
	end

	subject { @enrollment }

	it { should be_valid }

	test_has_relationships [:student,:section]

	test_has_fields [:student_id,:section_id,:student_grade_level,:active,:subsection]

	# validations
	describe "when student_grade_level is not set" do
		before { @enrollment.student_grade_level="" }
		it { should_not be_valid }
	end

	describe "when this student already exist in the section" do
		before do
			@other_enrollment = @enrollment = build :enrollment, student: @student, section: @section, student_grade_level: @student.grade_level
		end

		it { @other_enrollment.should_not be_valid }
	end

	describe "when subsection is string" do
		before do
		 @enrollment.subsection = "b"
		end
		it { should_not be_valid }
	end

	describe "when subsection is set to integer" do
		before do
		 @enrollment.subsection = 5
		end
		it { should be_valid }
	end

	describe "when subsection value is changed to blank" do
		before do
		 @enrollment.subsection = 5
		 @enrollment.save
		 @enrollment.subsection = ""
		 @enrollment.save
		end
		it do
			@enrollment.subsection.should == 0 
			@enrollment.should be_valid
		end

	end

	describe "when subsection value is set to nil" do
		before do
		 @enrollment.subsection = nil
		 @enrollment.save
		end
		it do
			@enrollment.subsection.should == 0
			@enrollment.should be_valid
		end
	end
end