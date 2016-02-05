require 'spec_helper'

describe "AnnouncementModifies" do
  before do
    @system_administrator = create :system_administrator
  end

  subject { page }

  context "creates a new announcement" do
    before do
      sign_in @system_administrator
      visit announcements_path
      click_link "Add Announcement"
      fill_in "announcement_start_at", with: 2.days.ago
      fill_in "announcement_end_at", with: 2.days.from_now
      @string = "This is a brand new test announcement! Check it out!"
      fill_in "announcement_content", with: @string
      click_button "Create Announcement"
    end
    it { should have_selector '.announcement', text: @string }
  end

  context "updates an existing announcement" do
    before do
      @annc = create :announcement, start_at: 2.days.ago, end_at: 2.days.from_now, content: "Sample Announcement"
      
      sign_in @system_administrator
      visit announcements_path
      click_link "edit"
      fill_in "announcement_start_at", with: 5.days.ago
      @string = "Updated Announcement"
      fill_in "announcement_content", with: @string
      click_button "Update Announcement"
    end
    it { should have_selector '.announcement', text: @string }
  end
end