require 'spec_helper'

describe 'EnforcesEvidenceSectionOutcomeContext' do
  before do
    @sys_admin = create :system_administrator

    @section = create :section
    @school = @section.school

    @section_outcome = create :section_outcome, section: @section
    @evidence = create :evidence, section: @section
    @evidence_section_outcome = create :evidence_section_outcome, 
        evidence: @evidence, section_outcome: @section_outcome

    # belongs to a differnt school by default
    @other_eso = create :evidence_section_outcome 
  end

  it "doesn't filter evidence section outcomes when no context is established" do
    [nil, 0].each do |zero|

      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @evidence_section_outcome).should eq(true)
      current_ability.can?(:manage, @other_eso).should eq(true)
    end
  end

  it "does filter evidence section outcomes when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_eso).should eq(false)
    current_ability.can?(:manage, @evidence_section_outcome).should eq(true)
  end
end