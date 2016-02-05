require 'spec_helper'

describe 'SubjectOutcomeContext' do
  before do
    @sys_admin = create :system_administrator

    @school = create :school
    @subject = create :subject, school: @school
    @subject_outcome = create :subject_outcome, subject: @subject

    @other_so = create :subject_outcome
  end

  it "doesn't filter subject outcomes when no context is established" do
    [nil, 0].each do |zero|
      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @subject_outcome).should eq(true)
      current_ability.can?(:manage, @other_so).should eq(true)
    end
  end

  it "does filter subject outcomes when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_so).should eq(false)
    current_ability.can?(:manage, @subject_outcome).should eq(true)
  end
end