require 'spec_helper'

describe "ManageSubjects" do
  before do
    @system_administrator = create :system_administrator
  end

  subject { page }

  context "displays appropriate links on subject show" do
    before do
      @subject = create :subject
      sign_in @system_administrator
      visit subject_path(@subject)
    end
    it do
      # Test for link to edit this subject.
      should have_link 'edit', href: "#{edit_subject_path(@subject)}"
      # Test for link to all subjects.
      should have_link 'All Subjects', href: "#{subjects_path}"
    end
  end

  context "displays appropriate link on subjects index" do
    before do
      sign_in @system_administrator
      visit subjects_path
    end
    it do
      # Link back to dashboard (within scrolling body to differentiate from the username link in the header)
      page.find("#scrolling_body").should have_selector("a[href='#{user_path(id: @system_administrator.id)}']")
    end
  end

  context "creates a new subject", js: true do
    let (:subj_name) { Faker::Company.name } 
    before do
      school = create :school
      discipline = create :discipline

      teacher = create :teacher, school: school

      sign_in @system_administrator
      visit new_subject_path

      select school.name, from: "subject_school_id"
      select discipline.name, from: "subject_discipline_id"
      fill_in "subject_name", with: subj_name
      select "Teacher", from: "subject_manager_type"
      select teacher.last_name_first, from: "subject_subject_manager_id"
      click_button "Create Subject"
    end
    it do
      should have_link subj_name
    end
  end

  context "edits an existing subject", js: true do
    before do
      @subject = create :subject
      sign_in @system_administrator
    end
    let (:new_subj_name) { Faker::Company.name }
    it do
      old_name = @subject.name
      
      visit edit_subject_path(@subject)
      fill_in "subject_name", with: new_subj_name
      click_button("Update Subject")

      should have_selector 'h3', text: new_subj_name
      should_not have_selector 'h3', text: @subject.name
    end
  end
end