require 'spec_helper'

describe 'EnforcesEvidenceSectionOutcomeRatingContext' do
  before do
    @sys_admin = create :system_administrator

    @section = create :section
    @school = @section.school

    @student = create :student
    create :enrollment, student: @student, section: @section

    @section_outcome = create :section_outcome, section: @section
    @evidence = create :evidence, section: @section
    @evidence_section_outcome = create :evidence_section_outcome, 
        evidence: @evidence, section_outcome: @section_outcome
    @esor = create :evidence_section_outcome_rating,
        evidence_section_outcome: @evidence_section_outcome, student: @student

    # belongs to a differnt school by default
    @other_esor = create :evidence_section_outcome_rating
  end

  it "doesn't filter evidence section outcome ratings when no context is established" do
    [nil, 0].each do |zero|

      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @esor).should eq(true)
      current_ability.can?(:manage, @other_esor).should eq(true)
    end
  end

  it "does filter evidence section outcome ratings when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_esor).should eq(false)
    current_ability.can?(:manage, @esor).should eq(true)
  end
end