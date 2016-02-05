require 'spec_helper'

describe EvidenceSectionOutcomeRating do

  before do
    @school   = create :school
    @student  = create :student, school: @school
    @eso      = create :evidence_section_outcome
    @esor     = create :evidence_section_outcome_rating, rating: 'Y', student: @student, 
                evidence_section_outcome: @eso   
  end
  subject { @esor }
  
  it { should be_valid }

  context "should remove duplicate ratings when created" do
  # via uniquify before_validation filter
    before do 
      @duplicate = create :evidence_section_outcome_rating, rating: 'G', student: @student,
                evidence_section_outcome: @eso
    end
    it do
      @eso.evidence_section_outcome_ratings.count.should == 1
    end
  end

  context "it has no effect during creation or update if there are no duplicate ratings" do
    before { @esor.update_attributes(rating: "B") }
    it do
      @esor.reload.rating.should eq("B")
      @esor.persisted?.should eq(true)
    end
  end
end