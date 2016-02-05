require 'spec_helper'

describe SectionOutcomeRating do

  before do
    @student = create :student
    @section_outcome = create :section_outcome
    @section_outcome_rating = create :section_outcome_rating, section_outcome: @section_outcome, rating: "N", student: @student
  end

  subject { @section_outcome_rating }

  it { should be_valid }

  context "it removes duplicate ratings when created" do
  # via uniquify before_validation filter
    before { @duplicate = create :section_outcome_rating, section_outcome: @section_outcome, rating: "P", student: @student }
    it do
      @section_outcome.section_outcome_ratings.count.should == 1
    end
  end

  context "it removes duplicate ratings when updated" do
  # works via uniquify before_validation filter

     # Set up two evidence section outcome ratings with the same section_outcome_id
     # and student_id (skipping validation!)
     before do
       @duplicate = build :section_outcome_rating, section_outcome: @section_outcome, rating: "H", student: @student
       @duplicate.save(validate: false)
     end
     it do
      # Verify that the invalid entries were created.
      @section_outcome.section_outcome_ratings.count.should == 2
      # Update one of the ratings.
      @duplicate.update_attributes rating: 'P'
      # Ensure that the model erased the other entry(s) with the same section_outcome_id
      # and student_id.
      @section_outcome.section_outcome_ratings.count.should == 1
      @duplicate.reload.rating.should == 'P'
     end
  end

  context "it has no effect during creation or update if there are no duplicate ratings" do
    before { @section_outcome_rating.update_attributes(rating: "H") }
    it do
      @section_outcome_rating.reload.rating.should eq("H") 
      @section_outcome_rating.persisted?.should eq(true)
    end
  end
end