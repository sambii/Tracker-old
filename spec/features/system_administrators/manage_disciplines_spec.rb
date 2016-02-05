require 'spec_helper'

describe "ManageDisciplines" do
  before do
    @system_administrator = create :system_administrator

    @discipline = create :discipline
    sign_in @system_administrator
  end

  subject { page }

  context "displays appropriate links on show" do
    before do
      visit discipline_path(@discipline)
    end
    it do
      # Test for link to edit this discipline
      should have_selector("a[href$='#{edit_discipline_path(@discipline)}']")
      # Test for link to add subject to this discipline
      should have_selector("a[href$='#{new_subject_path(discipline_id: @discipline.id)}']")
      # Test for link to all disciplines
      should have_selector("a[href$='#{disciplines_path}']")
    end
  end

  context "displays appropriate links on index" do
    before do
      visit disciplines_path
    end
    it do
      # Test for link to add a new discipline
      should have_selector("a[href$='#{new_discipline_path}']")
      # Test for link back to dashboard
      should have_selector("a[href$='#{user_path(id: @system_administrator.id)}']")
    end
  end

  context "creates a new discipline" do
    before do
      visit new_discipline_path
    end
    it do
      text = "Xtestn am Dis ec"
      fill_in "discipline_name", with: text
      click_button "Create Discipline"

      visit disciplines_path
      should have_selector 'td>a', text: text
    end
  end

  context "updates an existing discipline" do
    let (:old_discipline_name)  { @discipline.name }
    let (:new_discipline_name) { "Zombad #{Time.now.to_s(:number)}" }
    before do
      visit edit_discipline_path(@discipline)
    end
    it do
      fill_in "discipline_name", with: new_discipline_name
      click_button "Update Discipline"

      visit disciplines_path
      should_not have_selector 'td>a', text: old_discipline_name
      should have_selector 'td>a', text: new_discipline_name
    end
  end
end