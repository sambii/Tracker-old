require 'spec_helper'

describe "SectionShows" do
  before (:each) do
    @school  = create :school
    @student = create :student, school: @school
    @school_admin = create :school_administrator, school: @school
  end

  subject { page }

  context "School Admin can remove a student", js: true do
    # Valid school administrator sign in, visit page.
    before do 
      sign_in @school_admin
      visit students_path

      # Fill out the form to remove the student
      find("#student_#{@student.id}").find(".remove_student").click
      find("div#popup_form").should have_content("Are you sure you want to remove #{@student.first_name} #{@student.last_name}")
      find("div#popup_form").find("button[type=submit]").click
    end
    
    # Confirm the student is not on the page.
    it { should_not have_content(@student.last_name) }
  end

  pending "confirm we are not on an error page, or confirm another student is displayed"
end