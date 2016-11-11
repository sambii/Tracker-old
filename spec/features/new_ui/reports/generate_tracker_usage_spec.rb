# generate_tracker_usage_spec.rb
require 'spec_helper'


describe "Generate Tracker Usage Report", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    @school1 = FactoryGirl.create :school, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    @discipline = @subject1.discipline

    load_test_section(@section1_1, @teacher1)

    # set of valid ratings for populating the sor and esor records
    val_esors = ["B", "G", "Y", "R", "M", "U"]
    val_sors = ["H", "P", "N", "U"]

    # section outcome with no evidence and no ratings
    @subjo_1_0_0_0 = FactoryGirl.create(:subject_outcome, subject: @subject1)
    @secto_1_0_0_0 = FactoryGirl.create(:section_outcome, section: @section1_1, subject_outcome: @subjo_1_0_0_0, minimized: false) # don't minimize any
    @ev_1_0_0_0 = FactoryGirl.create(:evidence, section: @section1_1)

    # section outcome with one evidence and no ratings
    @subjo_1_0_1_0 = FactoryGirl.create(:subject_outcome, subject: @subject1)
    @secto_1_0_1_0 = FactoryGirl.create(:section_outcome, section: @section1_1, subject_outcome: @subjo_1_0_1_0, minimized: false) # don't minimize any
    @ev_1_0_1_0 = FactoryGirl.create(:evidence, section: @section1_1)
    @eso_1_0_1_0 = FactoryGirl.create :evidence_section_outcome, section_outcome: @secto_1_0_1_0, evidence: @ev_1_0_1_0

    # section outcome with one evidence ratings
    @subjo_1_1_1_0 = FactoryGirl.create(:subject_outcome, subject: @subject1)
    @secto_1_1_1_0 = FactoryGirl.create(:section_outcome, section: @section1_1, subject_outcome: @subjo_1_1_1_0, minimized: false) # don't minimize any
    @ev_1_1_1_0 = FactoryGirl.create(:evidence, section: @section1_1)
    @sor_1_1_1_0 = FactoryGirl.create :section_outcome_rating, section_outcome: @secto_1_1_1_0, student: @student2, rating: val_sors[0]
    @eso_1_1_1_0 = FactoryGirl.create :evidence_section_outcome, section_outcome: @secto_1_1_1_0, evidence: @ev_1_1_1_0
    # @esor_1_1_1_0 = FactoryGirl.create :evidence_section_outcome_rating, evidence_section_outcome: @eso_1_1_1_0, student: @student2, rating: val_esors[0]

    # section outcome rated with one evidence rated
    @subjo_1_1_1_1 = FactoryGirl.create(:subject_outcome, subject: @subject1)
    @secto_1_1_1_1 = FactoryGirl.create(:section_outcome, section: @section1_1, subject_outcome: @subjo_1_1_1_1, minimized: false) # don't minimize any
    @ev_1_1_1_1 = FactoryGirl.create(:evidence, section: @section1_1)
    @sor_1_1_1_1 = FactoryGirl.create :section_outcome_rating, section_outcome: @secto_1_1_1_1, student: @student2, rating: val_sors[0]
    @eso_1_1_1_1 = FactoryGirl.create :evidence_section_outcome, section_outcome: @secto_1_1_1_1, evidence: @ev_1_1_1_1
    @esor_1_1_1_1 = FactoryGirl.create :evidence_section_outcome_rating, evidence_section_outcome: @eso_1_1_1_1, student: @student2, rating: val_esors[0]

    # section outcome rated with one deactivated evidence rated
    @subjo_d0_1_1_1 = FactoryGirl.create(:subject_outcome, subject: @subject1)
    @secto_d0_1_1_1 = FactoryGirl.create(:section_outcome, section: @section1_1, subject_outcome: @subjo_d0_1_1_1, minimized: false) # don't minimize any
    @ev_d0_1_1_1 = FactoryGirl.create(:evidence, section: @section1_1, active: false)
    @sor_d0_1_1_1 = FactoryGirl.create :section_outcome_rating, section_outcome: @secto_d0_1_1_1, student: @student2, rating: val_sors[0]
    @eso_d0_1_1_1 = FactoryGirl.create :evidence_section_outcome, section_outcome: @secto_d0_1_1_1, evidence: @ev_d0_1_1_1
    @esor_d0_1_1_1 = FactoryGirl.create :evidence_section_outcome_rating, evidence_section_outcome: @eso_d0_1_1_1, student: @student2, rating: val_esors[0]

    # section outcome rated with one deactivated rated eso
    @subjo_1_1_d0_1 = FactoryGirl.create(:subject_outcome, subject: @subject1)
    @secto_1_1_d0_1 = FactoryGirl.create(:section_outcome, section: @section1_1, subject_outcome: @subjo_1_1_d0_1, minimized: false, active: false) # don't minimize any
    @ev_1_1_d0_1 = FactoryGirl.create(:evidence, section: @section1_1)
    @sor_1_1_d0_1 = FactoryGirl.create :section_outcome_rating, section_outcome: @secto_1_1_d0_1, student: @student2, rating: val_sors[0]
    @eso_1_1_d0_1 = FactoryGirl.create :evidence_section_outcome, section_outcome: @secto_1_1_d0_1, evidence: @ev_1_1_d0_1
    @esor_1_1_d0_1 = FactoryGirl.create :evidence_section_outcome_rating, evidence_section_outcome: @eso_1_1_d0_1, student: @student2, rating: val_esors[0]

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
      @err_page = "/teachers/#{@teacher1.id}"
    end
    it { has_no_tracker_usage_report }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { has_valid_tracker_usage_report(:school_administrator) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { has_valid_tracker_usage_report(:researcher) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      Rails.logger.debug("*** @school1: #{@school1.inspect}")
      set_users_school(@school1)
    end
    it { has_valid_tracker_usage_report(:system_administrator) }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @err_page = "/students/#{@student.id}"
    end
    it { has_no_reports }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @err_page = "/parents/#{@student.parent.id}"
    end
    it { has_no_reports }
  end

  ##################################################
  # test methods

  def has_no_reports
    # should not have a link to generate reports
    page.should_not have_css("#side-reports")
    page.should_not have_css("a", text: 'Generate Reports')
    # should fail when going to generate reports page directly
    visit new_generate_path
    assert_equal(@err_page, current_path)
    page.should_not have_content('Internal Server Error')
    # should fail when running tracker usage report directly
    visit tracker_usage_teachers_path
    assert_equal(@err_page, current_path)
    within('head title') do
      page.should_not have_content('Internal Server Error')
    end
  end

  def has_no_tracker_usage_report
    page.should have_css("#side-reports a", text: 'Generate Reports')
    find("#side-reports a", text: 'Generate Reports').click
    page.should have_content('Generate Reports')
    within("#page-content") do
      within('form#new_generate') do
        page.should have_selector("select#generate-type")
        within('select#generate-type') do
          page.should_not have_css('option#tracker_usage')
        end
      end
    end
    # should fail when running tracker usage report directly
    visit tracker_usage_teachers_path
    assert_equal(@err_page, current_path)
    within('head title') do
      page.should_not have_content('Internal Server Error')
    end
  end

  def has_valid_tracker_usage_report(role)
    page.should have_css("#side-reports a", text: 'Generate Reports')
    find("#side-reports a", text: 'Generate Reports').click
    page.should have_content('Generate Reports')
    within("#page-content") do
      within('form#new_generate') do
        page.should have_css('fieldset#ask-subjects', visible: false)
        page.should have_css('fieldset#ask-date-range', visible: false)
        page.should have_selector("select#generate-type")
        select('Tracker Usage', from: "generate-type")
        find("select#generate-type").value.should == "tracker_usage"
        find("button", text: 'Generate').click
      end
    end
    assert_equal(tracker_usage_teachers_path(), current_path)
    page.should_not have_content('Internal Server Error')

    within("#page-content") do
      within('.report-header') do
        page.should have_content("Tracker Activity for School #{@school1.name}")
      end
      within('.report-body') do
        within("table tbody.tbody-header[data-tch-id='#{@teacher1.id}']") do
          page.should have_css("td.evid_count", text: '27')
          page.should have_css("td.evid_rated_count", text: '25')
          page.should have_css("td.los_count", text: '9')
          page.should have_css("td.los_rated_count", text: '7')
        end
        within("table tbody.tbody-body[data-tch-id='#{@teacher1.id}']") do
          page.should have_css("td.evid_count", text: '27')
          page.should have_css("td.evid_rated_count", text: '25')
          page.should have_css("td.los_count", text: '9')
          page.should have_css("td.los_rated_count", text: '7')
        end
      end
    end
  end # def has_valid_tracker_usage_report


end
