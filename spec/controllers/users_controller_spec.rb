require 'spec_helper'

describe UsersController do
  before(:each) do
    @system_administrator = FactoryGirl.create(:system_administrator)
    @school = create :school
  end

  describe "GET index" do
    it "lists users in alphabetical order" do
      sign_in @system_administrator
      get :index

      users = controller.instance_variable_get(:@users)
      names = users.pluck(:last_name)
      names.should eq(names.sort)
    end
  end

  describe "GET show" do
    it "removes school context for a system administrator" do
      sign_in @system_administrator
      session[:school_context] = @school.id
      get :show, id: @system_administrator.id
      session[:school_context].to_i.should eq(0)
    end
  end
end