require 'spec_helper'

describe SchoolsController do
  before(:each) do
    @system_administrator = create :system_administrator
    @school = create :school
    @other_school = create :school
  end

  describe "GET show" do
    it "establishes school context for a system administrator" do
      sign_in @system_administrator
      session[:school_context].to_i.should eq(0)

      get :show, id: @other_school.id
      session[:school_context].should eq(@other_school.id)

      get :show, id: @school.id
      session[:school_context].should eq(@school.id)
    end
  end
end