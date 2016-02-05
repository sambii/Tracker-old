require 'spec_helper'

describe 'EnforcesEnrollmentContext' do
  before do
    @school = create :school  
    @sys_admin = create :system_administrator

    # enrollment creates a different school by default, so it is not in the
    # same school as above, which is what we want.
    @enrollment = create :enrollment 
    @student = @enrollment.student
  end

  it "doesn't filter schools when no context is established" do
    [nil, 0].each do |zero|
      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @enrollment).should eq(true)
      current_ability.can?(:manage, @student).should eq(true)
    end
  end

  it "does filter schools when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @student).should eq(false)
  end


end