require 'spec_helper'

describe School do

   before { @school = build :school, marking_periods:"4" }

   subject { @school }

   it { should be_valid }
   
   relationships = [:teachers, :counselors, :subjects, :sections, :students, :school_years]
   test_has_relationships relationships

   required_fields = [:marking_periods, :name, :acronym ]
   test_has_fields required_fields

   test_responds_to_methods [:current_school_year,:current_school_year=]

   required_fields.each do |field|
	   describe "when #{field} is not present" do
	     before { @school.send("#{field}=", " ") }
	     it { should_not be_valid }
	   end
	end

	describe "when marking period is too small" do
		before { @school.marking_periods=0 }
		it { should_not be_valid }
	end

	describe "when marking period is too big" do
		before { @school.marking_periods=7 }
	    it { should_not be_valid }
	end

	describe "when marking period is negative" do
		before { @school.marking_periods= -4 }
	    it { should_not be_valid }
	end

	describe "when marking period is a float" do
		before { @school.marking_periods= 3.1423232424 }
	    it { should_not be_valid }
	end

	describe "allow blank school year" do
		before { @school.school_year_id = " " }
		it { should be_valid }
	end

	describe "don't allow school year if it's school is not our school" do
		before do
			@other_school = School.create(name:"LapaxHigh", acronym:"LVDH",marking_periods:"4")
			@other_school_year  = SchoolYear.create(name:"UberSchoolYear", school_id: @other_school.id,
    							starts_at: Date.parse("2012-09-01"),
    							ends_at: Date.parse("2013-06-20"))
			@school.current_school_year = @other_school_year
		end

		it { should_not be_valid }
	end

	describe "allow school year if it is in our school" do
		before do
			@school_year  = SchoolYear.create(name:"UberSchoolYear", school_id: @school.id,
    							starts_at: Date.parse("2012-09-01"),
    							ends_at: Date.parse("2013-06-20"))
		end

		it do 
			@school.current_school_year = @school_year
			@school.should be_valid
		end
	end

end