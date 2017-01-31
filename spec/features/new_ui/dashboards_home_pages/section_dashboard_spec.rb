# section_dashboard_spec.rb
require 'spec_helper'


describe "Section Dashboard", js:true do
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
    it { section_dashboard_is_valid }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @section.school
      sign_in(@school_administrator)
    end
    it { section_dashboard_is_valid }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@section.school)
    end
    it { section_dashboard_is_valid }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@section.school)
    end
    it { section_dashboard_is_valid }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { cannot_see_section_dashboard }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { cannot_see_section_dashboard }
  end

  ##################################################
  # test methods

  def cannot_see_section_dashboard
    visit class_dashboard_section_path(@section.id)
    assert_not_equal("/sections/#{@section.id}/class_dashboard", current_path)
  end

  def section_dashboard_is_valid
    visit class_dashboard_section_path(@section.id)
    assert_equal("/sections/#{@section.id}/class_dashboard", current_path)
    within("#overall") do
      page.should have_content('6 - High Performance')
      page.should have_content('6 - Proficient')
      page.should have_content('6 - Not Yet Proficient')
      page.should have_content('6 - Unrated')
    end

    within("#prof_bar") do
      ratings_by_so = [['2','2','1','1'], ['1','2','2','1'], ['1','1','2','2'], ['2','1','1','2']]
      seq = 0
      @section_outcomes.each do |so_id, so|
        rates = ratings_by_so[seq]
        Rails.logger.debug("+++ seq: #{seq}, rates: #{rates[0]} #{rates[1]} #{rates[2]} #{rates[3]}")
        seq += 1
        Rails.logger.debug("+++ so: #{so.inspect}")
        Rails.logger.debug("+++ so.id: #{so.id}")
        within("tr[data-prof-bar-so-id='#{so.id}']") do
          within('div.high-rating-bar') do
            page.should have_content(rates[0])
          end
          within('div.prof-rating-bar') do
            page.should have_content(rates[1])
          end
          within('div.nyp-rating-bar') do
            page.should have_content(rates[2])
          end
          within('div.unrated-rating-bar') do
            page.should have_content(rates[3])
          end
        end
      end
    end

    page.should_not have_css("#nyp_student tr[data-nyp-student-id='#{@student_unenrolled.id}']")
    page.should_not have_css("#nyp_student tr[data-nyp-student-id='#{@student_transferred.id}']")
    page.should_not have_css("#nyp_student tr[data-nyp-student-id='#{@student_out.id}']")

    # ensure deactivated enrollment doesn't show on page
    page.should_not have_content('Deactivated')

    page.should have_css("#unrated_los")
    page.should_not have_css("#unrated_los tr")

    # todo - validate links on page
    # page.find("tr a[href='/sections/#{@section.id}/class_dashboard']").click
    # assert_equal("/sections/#{@section.id}/class_dashboard", current_path)
  end

end
