require 'spec_helper'

describe 'EnforcesEvidenceContext' do
   before do

    @sys_admin = create :system_administrator

    @section = create :section
    @school = @section.school

    @section_outcome = create :section_outcome, section: @section
    @evidence = create :evidence, section: @section

    # belongs to a differnt school by default
    @other_evidence = create :evidence
    
  end

  it "doesn't filter evidences when no context is established" do
    [nil, 0].each do |zero|
      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @evidence).should eq(true)
      current_ability.can?(:manage, @other_evidence).should eq(true)
    end
  end

  it "does filter evidences when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_evidence).should eq(false)
    current_ability.can?(:manage, @evidence).should eq(true)
  end


end