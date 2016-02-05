require 'spec_helper'

describe "SchoolAdministratorSignIns" do
  let (:password) { '33f35443F24' }
  before do
    @school_administrator = create :school_administrator, 
        password: password, password_confirmation: password
    visit root_path
  end

  subject { page }

  it "allows school administrators to sign in" do
    sign_in @school_administrator
    should have_content "Currently logged in as "
    should have_content "Administrator Dashboard "
  end

  it "rejects invalid sign_ins" do
    sign_in @school_administrator, 'wrong_passwd'
    should have_content "Invalid username or password."
  end
end
