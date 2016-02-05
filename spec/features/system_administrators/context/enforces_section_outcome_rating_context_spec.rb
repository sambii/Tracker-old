require 'spec_helper'

describe 'SectionOutcomeRatingContext' do
  before do
    @sys_admin = create :system_administrator

    @section = create :section
    @school = @section.school

    @student = create :student, school: @school
    create :enrollment, student: @student, section: @section

    @section_outcome = create :section_outcome, section: @section
    @section_outcome_rating = create :section_outcome_rating, section_outcome: @section_outcome, student: @student
    
    # belongs to a diffrent school by default
    @other_sor = create :section_outcome_rating
  end

  it "doesn't filter section outcomes when no context is established" do
    [nil, 0].each do |zero|
      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @section_outcome_rating).should eq(true)
      current_ability.can?(:manage, @other_so).should eq(true)
    end
  end

  it "does filter section outcomes when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_sor).should eq(false)
    current_ability.can?(:manage, @section_outcome_rating).should eq(true)
  end
end