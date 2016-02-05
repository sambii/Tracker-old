require 'spec_helper'

describe 'SectionOutcomeContext' do
  before do
    @sys_admin = create :system_administrator

    @section = create :section
    @school = @section.school

    @section_outcome = create :section_outcome, section: @section
    
    # belongs to a diffrent school by default
    @other_so = create :section_outcome 
  end

  it "doesn't filter section outcomes when no context is established" do
    [nil, 0].each do |zero|
      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @section_outcome).should eq(true)
      current_ability.can?(:manage, @other_so).should eq(true)
    end
  end

  it "does filter section outcomes when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_so).should eq(false)
    current_ability.can?(:manage, @section_outcome).should eq(true)
  end
end