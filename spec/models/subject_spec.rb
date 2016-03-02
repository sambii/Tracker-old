require 'spec_helper'

describe Subject do

  before do
    @school = FactoryGirl.build :school, :arabic, marking_periods:"2", name: 'Arabic School', acronym: 'AS'
    @subject_manager = FactoryGirl.build :teacher, school: @school
    @subject = FactoryGirl.build :subject, name: 'Model Subject', subject_manager: @subject_manager, school: @school
  end

  describe "school should be set up with arabic flags" do
    it do
      @school.should be_valid
      @school.has_flag?(School::USE_FAMILY_NAME).should be_true
      @school.has_flag?(School::USER_BY_FIRST_LAST).should be_true
      @school.has_flag?(School::GRADE_IN_SUBJECT_NAME).should be_true
    end
  end

  subject { @subject }
  it { should be_valid }
   
  relationships = [:sections, :teachers, :subject_outcomes, :all_subject_outcomes]
  test_has_relationships relationships

  # required_fields = [:school, :discipline, :name ]
  required_fields = [:name ]
  test_has_fields required_fields

  test_responds_to_methods [:count_ratings_plus, :count_section_ratings_plus, :count_ratings_by_outcome, :subject_name_without_grade, :grade_from_subject_name]

  required_fields.each do |field|
	  describe "when #{field} is not present" do
	  before { @subject.send("#{field}=", " ") }
	    it { should_not be_valid }
	  end
	end

  describe "when subject name is single word without grade" do
    before { @subject.name = 'single' }
    it { @subject.subject_name_without_grade.should == 'single' }
    it { @subject.grade_from_subject_name.should == ''}
  end

  describe "when subject name is single word with a grade" do
    before { @subject.name = 'single 1' }
    it { @subject.subject_name_without_grade.should == 'single' }
    it { @subject.grade_from_subject_name.should == '1'}
  end

  describe "when subject name is multiple words with a grade" do
    before { @subject.name = 'multiple word name 1' }
    it { @subject.subject_name_without_grade.should == 'multiple word name' }
    it { @subject.grade_from_subject_name.should == '1'}
  end

  describe "when subject name is single word with a grade and semester" do
    before { @subject.name = 'single 1s2' }
    it { @subject.subject_name_without_grade.should == 'single' }
    it { @subject.grade_from_subject_name.should == '1'}
  end

  describe "when subject name is multiple words with a grade and semester" do
    before { @subject.name = 'multiple word name 1s2' }
    it { @subject.subject_name_without_grade.should == 'multiple word name' }
    it { @subject.grade_from_subject_name.should == '1'}
  end

  describe "when subject name is single word with a grade and extra semester characters" do
    before { @subject.name = 'single 1sem2' }
    it { @subject.subject_name_without_grade.should == 'single' }
    it { @subject.grade_from_subject_name.should == '1'}
  end

  describe "when subject name is multiple words with a grade and extra semester characters" do
    before { @subject.name = 'multiple word name 1sem2' }
    it { @subject.subject_name_without_grade.should == 'multiple word name' }
    it { @subject.grade_from_subject_name.should == '1'}
  end


end