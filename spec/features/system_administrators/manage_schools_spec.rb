require 'spec_helper'

describe "ManageSchools" do
  before do
    sys_amin = create :system_administrator
    sign_in sys_amin
  end

  subject { page }

  context "creates a new school" do
    before { visit new_school_path }
    it do
      school_name = Faker::Company.name
      fill_in "school_name",            with: school_name
      fill_in "school_acronym",         with: Faker::Lorem.characters(4).upcase
      fill_in "school_street_address",  with: Faker::Address.street_address
      fill_in "school_city",            with: Faker::Address.city
      fill_in "school_state",           with: Faker::Address.state
      fill_in "school_zip_code",        with: Faker::Address.zip
      fill_in "school_marking_periods", with: "4"
      click_button "Create School"

      visit schools_path
      should have_selector 'a', text: school_name
    end
  end

  context "edits an existing school" do
    before do
     school = create :school
     visit edit_school_path(school)
   end
    subject { page }
    it do
      new_name = "Qern et #{ Time.now.to_s(:number) }"
      fill_in "school_name", with: new_name
      fill_in "school_acronym", with: Faker::Lorem.characters(4).upcase
      click_button "Update School"

      visit schools_path
      should have_selector 'a', text: new_name
    end
  end
end