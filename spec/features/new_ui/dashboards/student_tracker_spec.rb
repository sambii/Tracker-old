# student_tracker_spec.rb
require 'spec_helper'


describe "Student Tracker", js:true do
  before (:each) do
    @section = FactoryGirl.create :section
    @teacher = FactoryGirl.create :teacher, school: @section.school
    load_test_section(@section, @teacher)
    # todo - add prior/next year section
  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    # it { can_see_student_tracker }
    it { student_tracker_is_valid }
    # # one time check to ensure unenrolled student is flagged on page
    # it { deactivated_student_shows_unenrolled }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @section.school
      sign_in(@school_administrator)
    end
    # it { can_see_student_tracker }
    it { student_tracker_is_valid }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@section.school)
    end
    # it { can_see_student_tracker }
    it { student_tracker_is_valid }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section.school)
    end
    # it { can_see_student_tracker }
    it { student_tracker_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    # it { can_see_student_tracker }
    it { student_tracker_is_valid }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    # it { can_see_student_tracker }
    it { student_tracker_is_valid }
  end

  ##################################################
  # test methods

  # def can_see_student_tracker
  #   visit enrollment_path(@enrollment.id)
  #   assert_equal("/enrollments/#{@enrollment.id}", current_path)
  # end

  def student_tracker_is_valid
    visit enrollment_path(@enrollment.id)
    assert_equal("/enrollments/#{@enrollment.id}", current_path)
    within("#evidence-stats-overall h4.text-success") do
      page.should have_content('12/24')
    end
    within("#evidence-stats-overall h4.text-danger") do
      page.should have_content('12/24')
    end
    within("#evidence-stats-last7 h4.text-success") do
      page.should have_content('12/24')
    end
    within("#evidence-stats-last7 h4.text-danger") do
      page.should have_content('12/24')
    end
    within("#lo-pie") do
      page.should have_content('1 - High Performance')
      page.should have_content('1 - Proficient')
      page.should have_content('1 - Not Yet Proficient')
      page.should have_content('1 - Unrated')
    end

    # ensure deactivated enrollment doesn't show on page
    page.should_not have_content('Deactivated')

    # todo - tests for Learning Outcome / Evidence Rating Comments 
    # @section_outcomes.each do |k, so|
    #   sor = @sors_by_so_s["#{so.id}:#{@student.id}"]
    #   within("#lo-evid") do
    #     within("#lo-#{so.id}") do
    #       page.should have_content("#{so.name}")
    #       within("td.lo-rating-name") do
    #         page.should_not have_content(long_section_outcome_rating(sor.rating))
    #       end
    #     end
    #   end
    # end

    # lo_names = page.all("#lo-evid .lo-name")
    # eso_evidence_names = page.all("#lo-evid .eso-evidence-name")
    # # evid_dates = page.all("#lo-evid .tracker-evid-date")
    # # evid_types = page.all("#lo-evid .tracker-evid-type")
    # # evid_rating_icons = page.all("#lo-evid .eso-evidence-rating-icon")
    # evid_rating_icons = page.all("#lo-evid .eso-evidence-rating-icon i")
    # evid_rating_comment = page.all("#lo-evid .eso-evidence-rating-comment")
    # # evid_attach_name = page.all("#lo-evid .evidence-attachment-name")
    # # evid_hyper_title = page.all("#lo-evid .evidence-hyperlink-title")

  end

  # def deactivated_student_shows_unenrolled
  #   visit enrollment_path(@enrollment_unenrolled.id)
  #   assert_equal("/enrollments/#{@enrollment_unenrolled.id}", current_path)
  #   within("#page-content .header-block h2.h1.page-title") do
  #     page.should have_content('unenrolled')
  #   end
  # end

end
