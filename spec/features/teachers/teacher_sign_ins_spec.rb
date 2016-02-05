require 'spec_helper'

describe "TeacherSignIns" do
  before do
    @teacher = create :teacher
    visit root_path
  end

  subject { page }

  context "allows teachers to sign in" do
    before do
      sign_in @teacher
    end
    it do
      should have_content "Currently logged in as "
      should have_content "Teacher Dashboard "
    end
  end

  context "rejects invalid sign_ins" do
    before { sign_in @teacher, 'fake+password' }
    it { should have_content "Invalid username or password." }
  end
end
