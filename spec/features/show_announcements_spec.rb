require 'spec_helper'

describe 'ShowAnnouncements' do
  
  subject { page }

  context 'only shows current system-wide announcements' do
    before do
      create :announcement, content: "This is my current announcement!", start_at: 1.hour.ago, end_at: 1.hour.from_now
      create :announcement, content: "This is my upcoming announcement!", start_at: 10.minutes.from_now, end_at: 1.hour.from_now
      create :announcement, content: "This is my past announcement!", start_at: 1.hour.ago, end_at: 10.minutes.ago
      visit root_path
    end
    it do
      find("#announcements").should have_content("This is my current announcement!")
      find("#announcements").should_not have_content("This is my upcoming announcement!")
      find("#announcements").should_not have_content("This is my past announcement!")
    end
  end

  context "does not show restricted announcements to users who are not logged in" do
    before do
      create :announcement, content: "This is my restricted announcement!", start_at: 1.hour.ago, end_at: 1.hour.from_now, restrict_to_staff: true
      visit root_path
    end
    it { should_not have_content("This is my restricted announcement!") }
  end

  context 'hides announcements when hide is clicked using javascript', js: true do
    before do
      create :announcement, content: "This is my current announcement!", start_at: 1.hour.ago, end_at: 1.hour.from_now
      visit root_path
      click_link "hide"
    end
    it { should_not have_content("This is my current announcement!") }
  end
end