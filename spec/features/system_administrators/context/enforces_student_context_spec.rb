require 'spec_helper'

describe 'EnforcesStudentContext' do
  before do
    @sys_admin = create :system_administrator

    @section = create :section
    @school = @section.school

    @student = create :student, school: @school
    create :enrollment, student: @student, section: @section

    # by default factory girl will assign this student to a new school
    @other_student = create :student
  end

  it "doesn't filter students when no context is established" do
    [nil, 0].each do |zero|
      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?([:edit, :update, :read], @student).should eq(true)
      current_ability.can?([:edit, :update, :read], @other_student).should eq(true)
    end
  end

  it "does filter students when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_student).should eq(false)
    [:edit, :update, :read].each do |action|
      current_ability.can?(action, @student).should eq(true)
    end
  end
end