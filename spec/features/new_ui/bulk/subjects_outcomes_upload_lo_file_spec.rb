# subject_outcomes_upload_lo_file_spec.rb
require 'spec_helper'


describe "Subject Outcomes Bulk Upload LOs", js:true do
  before (:each) do

    create_and_load_model_school

    # two subjects in @school1
    @section1_1 = FactoryGirl.create :section
    @subject1 = @section1_1.subject
    @school1 = @section1_1.school
    @teacher1 = @subject1.subject_manager
    @discipline = @subject1.discipline

    load_test_section(@section1_1, @teacher1)

    @section1_2 = FactoryGirl.create :section, subject: @subject1
    ta1 = FactoryGirl.create :teaching_assignment, teacher: @teacher1, section: @section1_2
    @section1_3 = FactoryGirl.create :section, subject: @subject1
    ta2 = FactoryGirl.create :teaching_assignment, teacher: @teacher1, section: @section1_3

    @subject2 = FactoryGirl.create :subject, subject_manager: @teacher1
    @section2_1 = FactoryGirl.create :section, subject: @subject2
    @section2_2 = FactoryGirl.create :section, subject: @subject2
    @section2_3 = FactoryGirl.create :section, subject: @subject2
    @discipline2 = @subject2.discipline

    # another subject in @school2
    @section3_1 = FactoryGirl.create :section
    @subject3 = @section3_1.subject
    @school2 = @section3_1.school
    @teacher2 = @subject1.subject_manager
    @section3_2 = FactoryGirl.create :section, subject: @subject3
    @section3_3 = FactoryGirl.create :section, subject: @subject3

    # @file = fixture_file_upload('files/bulk_upload_los_initial.csv', 'text/csv')
    @file = Rack::Test::UploadedFile.new(
      Rails.root.join('spec/fixtures/files/bulk_upload_los_initial.csv'),
      'text/csv'
    )

  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    it { has_no_bulk_upload_los }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { has_no_bulk_upload_los(true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { has_no_bulk_upload_los }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { has_bulk_upload_los }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { has_no_bulk_upload_los }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { has_no_bulk_upload_los }
  end

  ##################################################
  # test methods

  def has_no_bulk_upload_los
    visit upload_lo_file_subject_outcomes_path()
    assert_not_equal("/subject_outcomes/upload_lo_file", current_path)
  end

  def has_bulk_upload_los
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        # page.should have_content("No File Chosen")
        # page.attach_file('#file', @file)
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_initial.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        # page.should have_content("bulk_upload_los_initial.csv")
        # page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click

      find("#save")
      page.should have_content('Match Old LOs to New LOs')
      page.should have_button("SAVE ALL")
      click_button '#save'
    end # within #page-content
    sleep 20


  end # def has_bulk_upload_los


end
