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
    it { bulk_upload_all_new_subject }
    it { bulk_upload_all_mismatches }
    it { bulk_upload_art_same }
    it { bulk_upload_art_add_swap }
    it { bulk_upload_art_2_change }
    it { bulk_upload_art_2_add_delete }
    it { bulk_upload_math_1_change }
    it { bulk_upload_capstone_1s1_delete_all }
    it { bulk_upload_wrong_file }
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
      page.should have_content('Learning Outcomes Updated Matching Report')
      within('#count_updated_subjects') { page.should have_content('0')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('5')}
      within('#total_adds') { page.should have_content('0')}
      within('#total_deactivates') { page.should have_content('4')}
      within("#breadcrumb-flash") do
        page.should_not have_content("Errors exist:, Invalid subject(s):")
      end
    end # within #page-content
    within("#lower-flash-messages") do
      page.should_not have_content("Errors exist:, Invalid subject(s):")
    end
  end # def bulk_upload_all_matching

  # test for all subjects bulk upload of Learning Outcomes into Model School
  # no mismatches (only adds) - can update all learning outcomes immediately without matching
  def bulk_upload_all_new_subject
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_new_subject.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click
      page.should have_content('Learning Outcomes Updated Matching Report')
      within('#count_updated_subjects') { page.should have_content('0')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('5')}
      within('#total_adds') { page.should have_content('0')}
      within('#total_deactivates') { page.should have_content('4')}
      within("#breadcrumb-flash") do
        page.should have_content("Errors exist:, Invalid subject(s):")
      end
    end # within #page-content
    within("#lower-flash-messages") do
      page.should have_content("Errors exist:, Invalid subject(s):")
    end
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
      page.should have_css('#save_matches')
      find('#cancel').click
      within('#count_updated_subjects') { page.should have_content('0')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('0')}
      within('#total_adds') { page.should have_content('0')}
      within('#total_deactivates') { page.should have_content('0')}
    end # within #page-content
  end # def bulk_upload_art_matching


  # test for single subject bulk upload of Learning Outcomes into Model School
  def bulk_upload_art_add_swap

    # Test 1 (bulk_upload_los_rspec_updates.csv):
    #  - 3 Changes (updates) (AT.1.02, AT.1.03, AT.1.04)
    #  - 1 add (AT.1.05)
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Art 1', from: "subject_id")
      end
      find('#upload').click
      within('.block-title') do
        page.should have_content("Learning Outcomes Matching Process of Only #{@subj_art_1.name}")
      end
      page.should have_css('select#selections_4')
      find('#cancel').click
      page.should have_content('Learning Outcomes Updated Matching Report')
      page.should have_css("#prior_subj", text: 'Art 1')
      within('#count_updated_subjects') { page.should have_content('0')}
      within('#count_errors') { page.should have_content('0')}
      within('#count_updates') { page.should have_content('3')}
      within('#count_adds') { page.should have_content('1')}
      within('#count_deactivates') { page.should have_content('0')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('3')}
      within('#total_adds') { page.should have_content('1')}
      within('#total_deactivates') { page.should have_content('0')}
    end # within #page-content

    # Test 2 (bulk_upload_los_rspec_art1_deacts.csv):
    #  - 1 Change (updates) (AT.1.02 code to AT.1.03)
    #  - 3 Deactivates (AT.1.03, AT.1.04, AT.1.05)
    # note: AT.1.05 was created on Test 1
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_art1_deacts.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Art 1', from: "subject_id")
      end
      find('#upload').click
      within('.block-title') do
        page.should have_content("Learning Outcomes Matching Process of Only #{@subj_art_1.name}")
      end
      find('#save_matches').click
      page.should have_content('Learning Outcomes Updated Matching Report')
      page.should have_css("#prior_subj", text: 'Art 1')
      within('#count_updated_subjects') { page.should have_content('1')}
      within('#count_errors') { page.should have_content('0')}
      within('#count_updates') { page.should have_content('1')}
      within('#count_adds') { page.should have_content('0')}
      within('#count_deactivates') { page.should have_content('3')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('1')}
      within('#total_adds') { page.should have_content('0')}
      within('#total_deactivates') { page.should have_content('3')}
    end # within #page-content

    # Test 3 (bulk_upload_los_rspec_initial.csv):
    #  - 2 Reactivates (updates) (AT.1.03, AT.1.04)
    # note: AT.1.05 is left deactivated as it was not in the original LOs
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
      within('.block-title') do
        page.should have_content("Learning Outcomes Matching Process of Only #{@subj_art_1.name}")
      end
      find('#save_matches').click
      page.should have_content('Learning Outcomes Updated Matching Report')
      page.should have_css("#prior_subj", text: 'Art 1')
      within('#count_updated_subjects') { page.should have_content('1')}
      within('#count_errors') { page.should have_content('0')}
      within('#count_updates') { page.should have_content('2')}
      within('#count_adds') { page.should have_content('0')}
      within('#count_deactivates') { page.should have_content('0')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('2')}
      within('#total_adds') { page.should have_content('0')}
      within('#total_deactivates') { page.should have_content('0')}
    end # within #page-content

    # update the add and swap 3 and 4
    # note: cannot reproduce the duplicate record error, because the record reactivated is the last matching one.
    # error occurs when active record is not the last one, so the inactive record is chosen, leaving two active producing duplicate error.

    # Test 4 (bulk_upload_los_rspec_updates.csv):
    #  - 3 Changes (updates) (AT.1.02, AT.1.03, AT.1.04)
    #  - 1 Reactivate (updates) (AT.1.05)
    # Note: this is the same as test 1, except AT.1.05 is reactivated instead of added
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Art 1', from: "subject_id")
      end
      find('#upload').click
      within('.block-title') do
        page.should have_content("Learning Outcomes Matching Process of Only #{@subj_art_1.name}")
      end
      # page.should have_css('select#selections_4')
      find('#save_matches').click
      page.should have_content('Learning Outcomes Updated Matching Report')
      page.should have_css("#prior_subj", text: 'Art 1')
      within('#count_updated_subjects') { page.should have_content('1')}
      within('#count_errors') { page.should have_content('0')}
      within('#count_updates') { page.should have_content('4')}
      within('#count_adds') { page.should have_content('0')}
      within('#count_deactivates') { page.should have_content('0')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('4')}
      within('#total_adds') { page.should have_content('0')}
      within('#total_deactivates') { page.should have_content('0')}
    end # within #page-content

    # Test 5 (bulk_upload_los_rspec_updates.csv):
    #  - 0 updates
    #  - 0 reactivates
    #  - 0 adds
    # Note: confirm nothing to change
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Art 1', from: "subject_id")
      end
      find('#upload').click
      within('.block-title') do
        page.should have_content("Learning Outcomes Matching Process of Only #{@subj_art_1.name}")
      end
      page.should_not have_css('select#selections_4')
      page.should have_css('#save_matches')
      find('#cancel').click
      page.should have_content('Learning Outcomes Updated Matching Report')
      page.should have_css("#prior_subj", text: 'Art 1')
      within('#count_updated_subjects') { page.should have_content('0')}
      page.should have_css('#count_errors', text: '0')
      page.should have_css('#count_updates', text: '0')
      page.should have_css('#count_adds', text: '0')
      page.should have_css('#count_deactivates', text: '0')
      page.should have_css('#total_errors', text: '0')
      page.should have_css('#total_updates', text: '0')
      page.should have_css('#total_adds', text: '0')
      page.should have_css('#total_deactivates', text: '0')
    end # within #page-content

  end # def bulk_upload_art_matching

  def bulk_upload_art_2_change
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      page.should have_content('Upload Curriculum / LOs File')
      # sleep 20
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Art 2', from: "subject_id")
      end
      find('#upload').click
      page.should have_content('Match Old LOs to New LOs')
      # 'Save Matches' button should be showing
      page.should have_button("Reconcile Subject")
      page.should_not have_css("#save_all")
      # click the select box to match AT.2.01 to AT.2.01
      page.should have_css('select#selections_0')
      select('A-AT.2.01', from: "selections_0")
      page.should have_css('#save_matches')
      find('#save_matches').click
      page.should have_content('Learning Outcomes Updated Matching Report')
      page.should have_css("#prior_subj", text: 'Art 2')
      within('#count_updated_subjects') { page.should have_content('1')}
      within('#count_errors') { page.should have_content('0')}
      within('#count_updates') { page.should have_content('3')}
      within('#count_adds') { page.should have_content('1')}
      within('#count_deactivates') { page.should have_content('1')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('3')}
      within('#total_adds') { page.should have_content('1')}
      within('#total_deactivates') { page.should have_content('1')}
    end # within #page-content
  end # def bulk_upload_art_matching


  def bulk_upload_art_2_add_delete
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
      # 'Save Matches' button should be showing
      page.should have_button("Reconcile Subject")
      page.should_not have_css("#save_all")
      # don't click the select box to match AT.2.01 to AT.2.01
      page.should have_css('select#selections_0')
      # select('A-AT.2.01', from: "selections_0")
      page.should have_css('#save_matches')
      find('#save_matches').click
      page.should have_content('Learning Outcomes Updated Matching Report')
      within('#count_updated_subjects') { page.should have_content('1')}
      page.should have_css('#count_errors', text: '0')
      page.should have_css('#count_updates', text: '2')
      page.should have_css('#count_adds', text: '2')
      page.should have_css('#count_deactivates', text: '2')
    end # within #page-content
  end # def bulk_upload_art_matching

  def bulk_upload_math_1_change
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      page.should have_content('Upload Curriculum / LOs File')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Math 1', from: "subject_id")
      end
      find('#upload').click
      page.should have_content('Match Old LOs to New LOs')
      # 'Save Matches' button should be showing
      page.should have_button("Reconcile Subject")
      page.should_not have_css("#save_all")

      within('.block-title h3') do
        page.should have_content("Learning Outcomes Matching Process of Only #{@subj_math_1.name}")
      end
      find("#selections_0 option:contains('A-MA.1.01')").select_option
      find("#selections_9 option:contains('K-MA.1.11')").select_option

      find('#save_matches').click
      #
      # Confirm math 1 counts are correct
      # 8 updates:
      #  - 1 reactivate of MA.1.12
      #  - 2 swap of codes for MA.1.04 and MA.1.08
      #  - 1 code change for MA.1.03
      #  - 2 semester changes for MA.1.05, and MA.1.07
      #  - 2 matched description changes for MA.1.01, and MA.1.11
      # 1 deactivate:
      #  - 1 deactivate of MA.1.02
      page.should have_content('Learning Outcomes Updated Matching Report')
      page.should have_css("#prior_subj", text: 'Math 1')
      within('#count_updated_subjects') { page.should have_content('1')}
      within('#count_errors') { page.should have_content('0')}
      within('#count_updates') { page.should have_content('8')}
      within('#count_adds') { page.should have_content('0')}
      within('#count_deactivates') { page.should have_content('1')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('8')}
      within('#total_adds') { page.should have_content('0')}
      within('#total_deactivates') { page.should have_content('1')}
    end # within #page-content
  end # def bulk_upload_art_matching

  def bulk_upload_capstone_1s1_delete_all
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      page.should have_content('Upload Curriculum / LOs File')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Capstone 1s1', from: "subject_id")
      end
      find('#upload').click

      page.should have_content('Match Old LOs to New LOs')
      within('#breadcrumb-flash-msgs') do
        page.should_not have_content('No Curriculum Records to upload.')
      end
      # 'Save Matches' button should be showing
      page.should have_button("Reconcile Subject")
      page.should_not have_css("#save_all")
      page.should have_css('#save_matches')

      page.should have_css("tr[data-old-db-id='11'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='11'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='12'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='12'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='13'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='13'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='14'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='14'] td.old_lo_desc.gray-out")
    end # within #page-content
  end # def bulk_upload_art_matching

  # test for all subjects bulk upload of Learning Outcomes into Model School
  # some mismatches (deactivates, reactivates or changes) - requires subject by subject matching
  def bulk_upload_wrong_file
    visit upload_lo_file_subject_outcomes_path
    # hide the sidebar for better printing during debugging
    find('li#head-sidebar-toggle a').click
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/StaffDataUpload.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click

      page.should have_content('Match Old LOs to New LOs')
      within('#breadcrumb-flash-msgs') do
        page.should have_content('No Curriculum Records to upload.')
        page.should_not have_content('Automatically Updated Subjects')

      end
    end
  end

  # test for all subjects bulk upload of Learning Outcomes into Model School
  # some mismatches (deactivates, reactivates or changes) - requires subject by subject matching
  def bulk_upload_all_mismatches
    visit upload_lo_file_subject_outcomes_path
    # hide the sidebar for better printing during debugging
    find('li#head-sidebar-toggle a').click
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click

      # Should automatically process Art 1, and then display Art 2 for Manual Matching

      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Match Old LOs to New LOs')
      within('.flash_notify') do
        page.should have_content('Automatically Updated Subjects counts:')
      end
      within('h3.ui-error') do
        page.should have_content('Note: When save is done, all unmatched new records will be added, and all unmatched old records will be deactivated.')
      end

      within('.block-title h3') do
        page.should have_content("Learning Outcomes Matching Process of #{@subj_art_2.name} of All Subjects")
      end

      page.should have_css("tr[data-new-rec-id='5'] select#selections_5")
      # page.should have_css("tr[data-new-rec-id='5'] .ui-error")
      page.should have_css("tr[data-new-rec-id='6'] select#selections_6")
      # page.should have_css("tr[data-new-rec-id='6'] .ui-error")
      page.should have_css("tr[data-new-rec-id='7'] input[type='hidden'][name='selections[7]']")
      page.should have_css("tr[data-new-rec-id='8'] input[type='hidden'][name='selections[8]']")

      page.should have_css("tr[data-old-db-id='7'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='7'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='8'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='8'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='9'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='10'] td.old_lo_desc.gray-out")

      page.should have_css("#prior_subj", text: 'Automatically Updated Subjects')
      within('#count_errors') { page.should have_content('0')}
      within('#count_updates') { page.should have_content('3')}
      within('#count_adds') { page.should have_content('1')}
      within('#count_deactivates') { page.should have_content('0')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('3')}
      within('#total_adds') { page.should have_content('1')}
      within('#total_deactivates') { page.should have_content('0')}

      select('E-AT.2.01', from: "selections_5")

      page.should_not have_css('#save_matches')

      find('#skip_subject').click

      # Skip Capstones 3.2, now move on to Math 1

      assert_equal("/subject_outcomes/lo_matching", current_path)
      page.should have_content('Match Old LOs to New LOs')
      within('.flash_notify') do
        page.should have_content(@subj_art_2.name)
      end
      within('h3.ui-error') do
        page.should have_content('Note: When save is done, all unmatched new records will be added, and all unmatched old records will be deactivated.')
      end
      within('.block-title h3') do
        page.should have_content("Learning Outcomes Matching Process of #{@subj_math_1.name} of All Subjects")
      end

      page.should have_css("tr[data-new-rec-id='13'] select#selections_13")
      page.should have_css("tr[data-new-rec-id='14'] input[type='hidden'][name='selections[14]']")
      page.should have_css("tr[data-new-rec-id='15'] input[type='hidden'][name='selections[15]']")
      page.should have_css("tr[data-new-rec-id='16'] input[type='hidden'][name='selections[16]']")
      page.should have_css("tr[data-new-rec-id='17'] input[type='hidden'][name='selections[17]']")
      page.should have_css("tr[data-new-rec-id='18'] input[type='hidden'][name='selections[18]']")
      page.should have_css("tr[data-new-rec-id='19'] input[type='hidden'][name='selections[19]']")
      page.should have_css("tr[data-new-rec-id='20'] input[type='hidden'][name='selections[20]']")
      page.should have_css("tr[data-new-rec-id='21'] input[type='hidden'][name='selections[21]']")
      page.should have_css("tr[data-new-rec-id='22'] select#selections_22")
      page.should have_css("tr[data-new-rec-id='23'] input[type='hidden'][name='selections[23]']")

      page.should have_css("tr[data-old-db-id='27'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='27'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='28'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='28'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='29'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='30'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='31'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='32'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='33'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='34'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='35'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='36'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='37'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='37'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='38'] td.old_lo_desc.inactive")

      page.should have_css("#prior_subj", text: 'Art 2')
      within('#count_errors') { page.should have_content('0')}
      within('#count_updates') { page.should have_content('0')}
      within('#count_adds') { page.should have_content('0')}
      within('#count_deactivates') { page.should have_content('12')}
      within('#total_errors') { page.should have_content('0')}
      within('#total_updates') { page.should have_content('3')}
      within('#total_adds') { page.should have_content('1')}
      within('#total_deactivates') { page.should have_content('12')}

      select('Z-MA.1.01', from: "selections_13")
      select('BJ-MA.1.11', from: "selections_22")

      find('#save_matches').click

      # move on to Math 2

      assert_equal("/subject_outcomes/lo_matching", current_path)
      page.should have_content('Match Old LOs to New LOs')
      within('.flash_notify') do
        page.should have_content(@subj_math_1.name)
      end
      within('h3.ui-error') do
        page.should have_content('Note: When save is done, all unmatched new records will be added, and all unmatched old records will be deactivated.')
      end
      within('.block-title h3') do
        page.should have_content("Learning Outcomes Matching Process of #{@subj_math_2.name} of All Subjects")
      end

      within("tr[data-new-rec-id='24']") do
        page.should have_css("input[type='hidden'][name='selections[24]']")
        page.should have_css(".ui-error", text: 'Duplicate Description')
      end
      within("tr[data-new-rec-id='25']") do
        page.should have_css("input[type='hidden'][name='selections[25]']")
        page.should have_css(".ui-error", text: 'Duplicate Description')
      end
      within("tr[data-new-rec-id='26']") do
        page.should have_css("input[type='hidden'][name='selections[26]']")
        page.should have_css(".ui-error", text: 'Duplicate Description')
      end
      within("tr[data-new-rec-id='27']") do
        page.should have_css("input[type='hidden'][name='selections[27]']")
        page.should have_css(".ui-error", text: 'Duplicate Description')
      end
      within("tr[data-new-rec-id='28']") do
        page.should have_css("input[type='hidden'][name='selections[28]']")
        page.should have_css(".ui-error", text: 'Duplicate Code')
      end
      within("tr[data-new-rec-id='29']") do
        page.should have_css("select#selections_29")
        page.should have_css(".ui-error", text: 'Duplicate Code')
      end

      page.should have_css("tr[data-old-db-id='39'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='40'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='40'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='41'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='42'] td.old_lo_desc")
      page.should_not have_css("tr[data-old-db-id='42'] td.old_lo_desc.gray-out")
      page.should have_css("tr[data-old-db-id='43'] td.old_lo_desc.gray-out")

      page.should have_css("#prior_subj", text: 'Math 1')
      page.should have_css('#count_updates', text: '8')
      page.should have_css('#count_adds', text: '0')
      page.should have_css('#count_deactivates', text: '1')
      page.should have_css('#count_errors', text: '0')
      # page.should have_css('#count_updated_subjects', text: '4')
      page.should have_css('#total_updates', text: '11')
      page.should have_css('#total_adds', text: '1')
      page.should have_css('#total_deactivates', text: '13')
      page.should have_css('#total_errors', text: '0')

      page.should_not have_css("#save_matches")
      find('#skip_subject').click

      page.should have_content('Learning Outcomes Updated Matching Report')
      page.should have_css("#prior_subj", text: 'Math 2')
      page.should have_css('#count_errors', text: '0')
      page.should have_css('#count_updates', text: '0')
      page.should have_css('#count_adds', text: '0')
      page.should have_css('#count_deactivates', text: '0')
      # page.should have_css('#count_updated_subjects', text: '4')
      within('#count_updated_subjects') { page.should have_content('4')}
      page.should have_css('#total_errors', text: '0')
      page.should have_css('#total_updates', text: '11')
      page.should have_css('#total_adds', text: '1')
      page.should have_css('#total_deactivates', text: '13')

    end # within #page-content

    #
    # run again and confirm updates were previously done
    #
    #
    visit upload_lo_file_subject_outcomes_path
    # hide the sidebar for better printing during debugging
    find('li#head-sidebar-toggle a').click
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click

      # Should go to Art 2 for Manual Matching

      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Match Old LOs to New LOs')
      within('.flash_notify') do
        page.should have_content('Automatically Updated Subjects counts:')
      end
      within('h3.ui-error') do
        page.should have_content('Note: When save is done, all unmatched new records will be added, and all unmatched old records will be deactivated.')
      end
      within('.block-title h3') do
        page.should have_content("Learning Outcomes Matching Process of #{@subj_art_2.name} of All Subjects")
      end

      page.should_not have_css("#save_matches")
      find('#skip_subject').click

      within('.block-title h3') do
        page.should have_content("Learning Outcomes Matching Process of #{@subj_math_2.name} of All Subjects")
      end

      page.should_not have_css("#save_matches")
      find('#skip_subject').click

      # should go to ending report (all updates are done)

      page.should have_content('Learning Outcomes Updated Matching Report')
      within('#count_updated_subjects') { page.should have_content('1')}
      page.should have_css("#prior_subj", text: 'Math 2')
      page.should have_css('#count_errors', text: '0')
      page.should have_css('#count_updates', text: '0')
      page.should have_css('#count_adds', text: '0')
      page.should have_css('#count_deactivates', text: '0')
      page.should have_css('#total_errors', text: '0')
      page.should have_css('#total_updates', text: '0')
      page.should have_css('#total_adds', text: '0')
      page.should have_css('#total_deactivates', text: '0')

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
    visit schools_path()
    assert_equal("/schools", current_path)
    page.should_not have_css("a[href='/subject_outcomes/upload_lo_file']")

    visit upload_lo_file_subject_outcomes_path()
    assert_equal("/subject_outcomes/upload_lo_file", current_path)
    # page.should have_content('Upload Learning Outcomes from Curriculum')
    page.should have_content('This school is not configured for Bulk Uploading Learning Outcomes')
  end

end
