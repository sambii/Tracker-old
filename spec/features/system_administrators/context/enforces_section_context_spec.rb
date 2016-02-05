require 'spec_helper'

describe 'EnforcesSectionContext' do
  before do
    @sys_admin = create :system_administrator

    @section = create :section
    @school = @section.school
    @other_section = create :section
  end

  it "doesn't filter sections when no context is established" do
    [nil, 0].each do |zero|

      session = {}
      session[:school_context] = zero
      current_ability = Ability.new(@sys_admin, session)

      current_ability.can?(:manage, @section).should eq(true)
      current_ability.can?(:manage, @other_section).should eq(true)
    end
  end

  it "does filter sections when context is established" do
    session = {}
    session[:school_context] = @school.id
    current_ability = Ability.new(@sys_admin, session)

    current_ability.can?(:show, @other_section).should eq(false)
    current_ability.can?(:manage, @section).should eq(true)
  end


end