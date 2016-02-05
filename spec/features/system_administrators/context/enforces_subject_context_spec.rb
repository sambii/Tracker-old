require 'spec_helper'

describe 'SubjectContext' do
  before do
    @sys_admin = create :system_administrator

    @school = create :school
    @subject = create :subject, school: @school

    @other_subject = create :subject
  end

  it "doesn't filter subjects when no context is established" do
    [nil, 0].each do |zero|
      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @subject).should eq(true)
      current_ability.can?(:manage, @other_subject).should eq(true)
    end
  end

  it "does filter subjects when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_subject).should eq(false)
    current_ability.can?(:manage, @subject).should eq(true)
  end
end