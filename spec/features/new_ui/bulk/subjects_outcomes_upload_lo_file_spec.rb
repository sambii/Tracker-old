# subject_outcomes_upload_lo_file_spec.rb
require 'spec_helper'


describe "Subject Outcomes Bulk Upload LOs", js:true do
  before (:each) do

    create_and_load_arabic_model_school

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

    # # Subject 3 in School 2
    # @school2 = FactoryGirl.create :school, :arabic, marking_periods:"2", name: 'School 2', acronym: 'S2'
    # @subject3 = FactoryGirl.create :subject, school: @school2
    # @section3_1 = FactoryGirl.create :section, subject: @subject3
    # @school2 = @section3_1.school
    # @teacher2 = @subject1.subject_manager
    # @section3_2 = FactoryGirl.create :section, subject: @subject3
    # @section3_3 = FactoryGirl.create :section, subject: @subject3


    # # Subject 4 in School 3 (invalid for Bulk LO Uploads - no grade in subject)
    # @section4_1 = FactoryGirl.create :section
    # @subject4 = @section4_1.subject
    # @school3 = @section4_1.school
    # @teacher3 = @subject4.subject_manager
    # @section4_2 = FactoryGirl.create :section, subject: @subject4
    # @section4_3 = FactoryGirl.create :section, subject: @subject4


    # @file = fixture_file_upload('files/bulk_upload_los_initial.csv', 'text/csv')
    # @file = Rack::Test::UploadedFile.new(
    #   Rails.root.join('spec/fixtures/files/bulk_upload_los_initial.csv'),
    #   'text/csv'
    # )

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
    end
    it { cannot_bulk_upload_los }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { cannot_bulk_upload_los }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { cannot_bulk_upload_los }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { bulk_upload_all_same }
    it { bulk_upload_art_same }
    it { bulk_upload_advisory_add }
    it { bulk_upload_art_mismatches }
    it { bulk_upload_all_mismatches }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { cannot_bulk_upload_los }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { cannot_bulk_upload_los }
  end

  ##################################################
  # test methods

  def cannot_bulk_upload_los
    visit upload_lo_file_subject_outcomes_path()
    assert_not_equal("/subject_outcomes/upload_lo_file", current_path)
    # page.should have_content('Upload Curriculum / LOs File')
  end

  # test for all subjects bulk upload of Learning Outcomes into Model School
  # no mismatches (only adds) - can update all learning outcomes immediately without matching
  def bulk_upload_all_same
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_initial.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click
      # if no errors, then save button should be showing
      page.should have_css("#save")
      page.should have_content('Match Old LOs to New LOs')
      within("#old-lo-count") do
        page.should have_content('38')
      end
      within("#new-lo-count") do
        page.should have_content('38')
      end
      within("#add-count") do
        page.should have_content('0')
      end
      within("#do-nothing-count") do
        page.should have_content('38')
      end
      within("#reactivated-count") do
        page.should have_content('0')
      end
      within("#deactivated-count") do
        page.should have_content('0')
      end
      within("#error-count") do
        page.should have_content('0')
      end
      page.should have_button("SAVE ALL")
      find('#save').click
    end # within #page-content
  end # def bulk_upload_all_matching

  # test for single subject bulk upload of Learning Outcomes into Model School
  def bulk_upload_art_same
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_initial.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Art 1', from: "subject_id")
      end
      find('#upload').click
      # if no errors, then save button should be showing
      page.should have_css("#save")
      page.should have_content('Match Old LOs to New LOs')
      within("#old-lo-count") do
        page.should have_content('4')
      end
      within("#new-lo-count") do
        page.should have_content('4')
      end
      within("#add-count") do
        page.should have_content('0')
      end
      page.should have_button("SAVE ALL")
      find('#save').click
    end # within #page-content
  end # def bulk_upload_art_matching


  # test for single subject bulk upload of Learning Outcomes into Model School
  def bulk_upload_advisory_add
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Advisory 1', from: "subject_id")
      end
      find('#upload').click
      # if no errors, then save button should be showing
      page.should have_css("#save")
      page.should have_content('Match Old LOs to New LOs')
      within("#old-lo-count") do
        page.should have_content('1')
      end
      within("#new-lo-count") do
        page.should have_content('2')
      end
      within("#add-count") do
        page.should have_content('1')
      end
      page.should have_button("SAVE ALL")
      find('#save').click
    end # within #page-content
  end # def bulk_upload_art_matching

  # test for single subject bulk upload of Learning Outcomes into Model School
  def bulk_upload_art_mismatches
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      page.should have_content('Upload Curriculum / LOs File')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Art 2', from: "subject_id")
      end
      find('#upload').click
      page.should have_content('Match Old LOs to New LOs')
      within("#old-lo-count") do
        page.should have_content('4')
      end
      within("#new-lo-count") do
        page.should have_content('4')
      end
      within("#add-count") do
        page.should have_content('2')
      end
      within("#do-nothing-count") do
        page.should have_content('2')
      end
      # errors - save button should be showing
      page.should_not have_css("#save")
      page.should_not have_button("SAVE ALL")
      # find('#save').click
    end # within #page-content
  end # def bulk_upload_art_matching

  # test for all subjects bulk upload of Learning Outcomes into Model School
  # some mismatches (deactivates, reactivates or changes) - requires subject by subject matching
  def bulk_upload_all_mismatches
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click
      sleep 20
      save_and_open_page
      # test for lines displayed
      within('thead.table-title') do
        page.should have_content("Processing #{@subj_advisory_1.name} of All Subjects")
      end
      page.should have_content('Match Old LOs to New LOs')
      # using find text to ensure exact match, not if it contains the characters
      # page.should have_css("#old-lo-count", text: /\s*3\s*/)

      # confirm current subject los are displayed and others are not

      # accumulate counts in html, then display them????
      # find("#old-lo-count").text.should == "3"
      # find("#new-lo-count").text.should == "3"
      # find("#add-count").text.should == "0"
      # find("#do-nothing-count").text.should == "3"
      # find("#reactivated-count").text.should == "0"
      # find("#deactivated-count").text.should == "0"
      # find("#error-count").text.should == "0"
      
      # errors - save button should be showing
      page.should have_css("#save")
      page.should have_button("SAVE #{@subj_advisory_1.name} LOs")
      # find('#save').click
    end # within #page-content
  end # def bulk_upload_all_matching


end


describe "Subject Outcomes Bulk Upload LOs Invalid School", js:true do
  before (:each) do

    create_and_load_model_school
    create_school1

  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { cannot_see_bulk_upload_los }
  end

  ##################################################
  # test methods

  def cannot_see_bulk_upload_los
    visit upload_lo_file_subject_outcomes_path()
    assert_equal("/subject_outcomes/upload_lo_file", current_path)
    # page.should have_content('Upload Learning Outcomes from Curriculum')
    page.should have_content('This school is not configured for Bulk Uploading Learning Outcomes')
  end

end
