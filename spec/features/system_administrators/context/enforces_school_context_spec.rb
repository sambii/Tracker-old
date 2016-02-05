require 'spec_helper'

describe 'EnforcesSchoolContext' do
  before do
    @sys_admin = create :system_administrator

    @school = create :school
    @other_school = create :school
  end

  it "doesn't filter schools when no context is established" do
    [nil, 0].each do |zero|

      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @school).should eq(true)
      current_ability.can?(:manage, @other_school).should eq(true)
    end
  end

  it "does filter schools when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_school).should eq(false)
    current_ability.can?(:manage, @school).should eq(true)
  end


end