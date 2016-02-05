require 'spec_helper'


describe "ManageTeachers" do
  before do
    @system_administrator = create :system_administrator
  end

  subject { page }

  context "creates a new teacher", js: true do
    let(:first) { Faker::Name.first_name }
    let(:last) { Faker::Name.last_name }
    let(:email) { Faker::Internet.safe_email } 

    before do
      school = create :school
      teacher = create :teacher, school: school

      sign_in @system_administrator
      visit new_teacher_path

      select  school.name, from: "teacher_school_id"
      fill_in "teacher_first_name", with: first
      fill_in "teacher_last_name",  with: last
      fill_in "teacher_email",      with: email
      click_button "Create Teacher"

      visit teachers_path
    end
    it do
      should have_link first
      should have_link last
    end
  end

  context "edits an existing teacher" do
    let (:new_last_name) { Faker::Name.last_name }
    before do
      @teacher = create :teacher

      sign_in @system_administrator
      visit edit_teacher_path(@teacher)
    end
    it do
      should have_content(@teacher.school.name)
      should_not have_selector("#teacher_school_id")
      
      fill_in "teacher_last_name", with: new_last_name
      click_button "Update Teacher"
      
      visit teachers_path

      should have_link new_last_name
      should_not have_link @teacher.last_name
    end
  end
end