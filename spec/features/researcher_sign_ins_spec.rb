require 'spec_helper'

describe "ResearcherSignIns" do
  before (:each) do
    @researcher = create :researcher
  end

  subject { page }

  context "allows researchers to sign in" do
    before { sign_in @researcher, @researcher.password }
   
    it { should have_content "Currently logged in as " }
    it { should have_content "Researcher Dashboard " }
  end

  context "rejects invalid sign_ins" do
    before { sign_in @researcher, "wrong_password" }
    it { should have_content "Invalid username or password." }
  end

  context "allows researcher to edit email and password" do
    before do
      sign_in @researcher
    end
    it js: true do
      visit edit_user_path(@researcher.id)
      assert_match(edit_user_path(@researcher.id), current_path)
      page.fill_in 'user_email', :with => 'test@testdomain.com'
      page.fill_in 'user_password', :with => 'passwd1'
      page.fill_in 'user_password_confirmation', :with => 'passwd1'
      page.click_button('Update Profile')
      assert_match('/', current_path)
      page.fill_in 'user_username', :with => @researcher.username
      page.fill_in 'user_password', :with => 'passwd1'
      page.click_button('Sign in')
      page.should have_content 'Signed in successfully.'
    end

  end
end
