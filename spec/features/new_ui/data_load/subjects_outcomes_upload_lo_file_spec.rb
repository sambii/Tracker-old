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
      sleep 20
      save_and_open_page
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
      find('#save_all').click
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
      find('#save_all').click
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
      find('#save_all').click
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
      page.should_not have_css("#save_all")
      page.should_not have_button("SAVE ALL")
      # find('#save_all').click
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

      page.should have_content('Match Old LOs to New LOs')
      within('thead.table-title') do
        page.should have_content("Processing #{@subj_art_1.name} of All Subjects")
      end
      # confirm current subject los are displayed and others are not
      within('form table') do
        page.should_not have_content("AD.1.01")
        page.should_not have_content("MA.1.12")
      end

      within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_0_#{@so_at_1_01.id}']") do
        page.should have_content("AT.1.01")
        page.should have_content("=")
        page.should have_css("input#selections_0_#{@so_at_1_01.id}")
        find("input#selections_0_#{@so_at_1_01.id}").should be_checked
      end
      # within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_0_']") do
      #   page.should have_content("AT.1.01")
      #   page.should have_content("x")
      #   page.should have_css("input#selections_0_")
      #   find("input#selections_0_").should_not be_checked
      # end
      within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_1_#{@so_at_1_02.id}']") do
        page.should have_content("AT.1.02")
        page.should have_content("=")
        page.should have_css("input#selections_1_#{@so_at_1_02.id}")
        find("input#selections_1_#{@so_at_1_02.id}").should be_checked
      end
      # within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_1_']") do
      #   page.should have_content("AT.1.02")
      #   page.should have_content("x")
      #   page.should have_css("input#selections_1_")
      #   find("input#selections_1_").should_not be_checked
      # end
      within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_2_#{@so_at_1_03.id}']") do
        page.should have_content("AT.1.03")
        page.should have_content("=")
        page.should have_css("input#selections_2_#{@so_at_1_03.id}")
        find("input#selections_2_#{@so_at_1_03.id}").should be_checked
      end
      # within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_2_']") do
      #   page.should have_content("AT.1.03")
      #   page.should have_content("x")
      #   page.should have_css("input#selections_2_")
      #   find("input#selections_2_").should_not be_checked
      # end
      within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_3_#{@so_at_1_04.id}']") do
        page.should have_content("AT.1.04")
        page.should have_content("=")
        page.should have_css("input#selections_3_#{@so_at_1_04.id}")
        find("input#selections_3_#{@so_at_1_04.id}").should be_checked
      end
      # within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_3_']") do
      #   page.should have_content("AT.1.04")
      #   page.should have_content("x")
      #   page.should have_css("input#selections_3_")
      #   find("input#selections_3_").should_not be_checked
      # end
      page.should_not have_css("tr[data-displayed-pair='pair_#{@subj_art_2.id}_2_']")

      find('#save_matches').click
      sleep 20
      save_and_open_page

      page.should have_content('Match Old LOs to New LOs')
      within('thead.table-title') do
        page.should have_content("Processing #{@subj_art_2.name} of All Subjects")
      end
      # confirm current subject los are displayed and others are not
      within('form table') do
        page.should_not have_content("AT.1.01")
        page.should_not have_content("MA.1.12")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_4_']") do
        page.should have_content("AT.2.01")
        page.should have_content("+")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_5_#{@so_at_2_02.id}']") do
        page.should have_content("AT.2.02")
        page.should have_content("=")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_6_#{@so_at_2_03.id}']") do
        page.should have_content("AT.2.03")
        page.should have_content("=")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_7_']") do
        page.should have_content("AT.2.04")
        page.should have_content("+")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}__#{@so_at_2_01.id}']") do
        page.should have_content("AT.2.01")
        page.should have_content("-")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}__#{@so_at_2_04.id}']") do
        page.should have_content("AT.2.04")
        page.should have_content("-")
      end

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
