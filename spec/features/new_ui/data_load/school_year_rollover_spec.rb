# school_year_rollover_spec.rb
require 'spec_helper'


describe "Rollover School Year", js:true do
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
    it { cannot_rollover_school_year(true) }
    it { cannot_rollover_model_school_year(true) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { can_rollover_school_year(true) }
    it { cannot_rollover_model_school_year(true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { cannot_rollover_school_year(true) }
    it { cannot_rollover_model_school_year(true) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { can_rollover_school_year(true) }
    it { can_rollover_model_school_year }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { cannot_rollover_school_year(false) }
    it { cannot_rollover_model_school_year(false) }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { cannot_rollover_school_year(false) }
    it { cannot_rollover_model_school_year(false) }
  end

  ##################################################
  # test methods

  def cannot_rollover_school_year(can_list_school)
    visit schools_path()
    if can_list_school
      assert_equal("/schools", current_path)
      page.should_not have_css("a[href='/schools/1/new_year_rollover']")
    else
      assert_not_equal("/schools", current_path)
    end
  end # cannot_rollover_school_year

  def cannot_rollover_model_school_year(can_list_school)
    visit schools_path()
    if can_list_school
      assert_equal("/schools", current_path)
      page.should_not have_css("a[href='/schools/#{@school1}/new_year_rollover']")
      page.should_not have_css("a[href='/subject_outcomes/upload_lo_file']")
    else
      assert_not_equal("/schools", current_path)
    end
  end # cannot_rollover_model_school_year

  def can_rollover_school_year(can_list_school)
    visit schools_path()
    if can_list_school
      # system admins can do this
      assert_equal("/schools", current_path)
    else
      # school admins can do this
      assert_not_equal("/schools", current_path)
    end
  end # def can_rollover_school_year

  def can_rollover_model_school_year
    visit schools_path()
    # only system admins can do this
    assert_equal("/schools", current_path)
  end # def can_rollover_model_school_year


end
