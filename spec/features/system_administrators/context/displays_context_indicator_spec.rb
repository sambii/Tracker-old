require 'spec_helper'

describe "DisplaysContextIndicator" do
  before do
    @school = create :school  
    @sys_admin = create :system_administrator
  end
  subject { page }

  it "displays a context indicator when context is being enforced" do
    sign_in @sys_admin
    should_not have_selector("#school_context")
  end

  it "doesn't display a context indicator when context is not being enforced" do
    sign_in @sys_admin
    visit school_path(@school)
    should have_selector("#school_context")
    find("#school_context").should have_content(@school.name)
  end
end