require 'spec_helper'

describe 'EnforcesTeacherContext' do
  before do
    @sys_admin = create :system_administrator

    @school = create :school
    @teacher = create :teacher, school: @school

    @other_teacher = create :teacher
  end

  it "doesn't filter teachers when no context is established" do
    [nil, 0].each do |zero|
      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?([:edit, :update, :read], @teacher).should eq(true)
      current_ability.can?([:edit, :update, :read], @other_teacher).should eq(true)
    end
  end

  it "does filter teachers when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_teacher).should eq(false)
    [:edit, :update, :read].each do |action|
      current_ability.can?(action, @teacher).should eq(true)
    end
  end
end