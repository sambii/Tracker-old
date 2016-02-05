require 'spec_helper'

describe SchoolYear do
  

  it "Properly validates school year dates" do
    [nil, DateTime.parse("2013-01-01")].each do |end_date|
      school_year = build :school_year,starts_at: Date.parse("2013-09-01"), ends_at: end_date
      school_year.valid?.should eq(false)
    end
  end

  context 'general model tests'  do
    before do
      @year_start = Date.new(1983,9,1)
      @year_end = Date.new(1984,8,31)
      @school = create :school_without_schoolyear
      @school_year = build :school_year, starts_at: @year_start, ends_at: @year_end
      @school_year.school = @school
    end

    subject { @school_year }

    it { should be_valid }

    # check relationships
    test_has_relationships [:school, :sections]

    # check customized instance methods
    test_responds_to_methods [:date_in_school_year?]

    # check fields
    test_has_fields [:name, :starts_at, :ends_at]

    # check required fields
    [:school, :name, :starts_at, :ends_at].each do |field|
      describe "when #{field} is not present" do
        before { @school_year.send("#{field}=", nil) }
        it { should_not be_valid }
      end
    end

    it "date_in_school_year? should allow the first date of the school year" do
      in_year = @school_year.date_in_school_year?(@year_start)
      @school_year.errors.count.should == 0
      in_year.should be_true
    end

    it "date_in_school_year? should allow the last date of the school year" do
      in_year = @school_year.date_in_school_year?(@year_end)
      @school_year.errors.count.should == 0
      in_year.should be_true
    end

    it "date_in_school_year? should not allow the day before the first date of the school year" do
      in_year = @school_year.date_in_school_year?(@year_start - 1.day)
      in_year.should be_false
    end

    it "date_in_school_year? should not allow the day after the last date of the school year" do

      in_year = @school_year.date_in_school_year?(@year_end + 1.day)
      in_year.should be_false
    end

  end

  describe 'Relationships' do
    before do
      @section = create :section
      #setup a section in the same school as @section, but with different school years
      #@old_section automatically got a different school_year on creation
      @old_section = create :section
      @old_section.school = @section.school
      @old_section.save

      @student = create :student, school: @section.school
      
      @enrollment = create :enrollment, student: @student, section: @section
    end

    context "correctly determines current sections for students" do
      it do     
        @student.sections.current.count.should eq(1)
        @student.sections.current.first.id.should eq(@section.id)
      end
    end

    context "correctly determines old sections for students" do
      before { create :enrollment, student: @student, section: @old_section }
      it do
        @student.sections.old.count.should eq(1)
        @student.sections.old.first.id.should eq(@old_section.id)
      end
    end

    describe "Teacher" do
      before do
        @teacher = create :teacher, school: @section.school
        create :teaching_assignment, section: @section, teacher: @teacher
      end

      context "correctly determines current sections for teachers" do
        it do
          @teacher.sections.current.count.should eq(1)
          @teacher.sections.current.first.should eq(@section)
        end
      end

      context "correctly determines old sections for teachers" do
        before { create :teaching_assignment, section: @old_section, teacher: @teacher }
        it do
          @teacher.sections.old.count.should eq(1)
          @teacher.sections.old.first.should eq(@old_section)
        end
      end
    end
  end





end
