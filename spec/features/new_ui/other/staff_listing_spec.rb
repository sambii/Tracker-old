# staff_listing_spec.rb
require 'spec_helper'


describe "Staff Listing", js:true do
  before (:each) do
    create_and_load_arabic_model_school

    @school = FactoryGirl.create :school, :arabic
    @teacher = FactoryGirl.create :teacher, school: @school
    @teacher_deact = FactoryGirl.create :teacher, school: @school, active: false
    @subject = FactoryGirl.create :subject, school: @school, subject_manager: @teacher
    @section = FactoryGirl.create :section, subject: @subject
    @discipline = @subject.discipline
    load_test_section(@section, @teacher)


  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    it { has_no_staff_listing }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school
      sign_in(@school_administrator)
    end
    it { has_valid_staff_listing(true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school)
    end
    it { has_valid_staff_listing(false) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school)
    end
    it { has_valid_staff_listing(true) }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { has_no_staff_listing }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { has_no_staff_listing }
  end

  ##################################################
  # test methods

  def has_no_staff_listing
    visit staff_listing_users_path
    assert_not_equal("/users/staff_listing", current_path)
  end

  def has_valid_staff_listing(can_create)
    visit staff_listing_users_path
    assert_equal("/users/staff_listing", current_path)
    within("#page-content") do
      page.should have_content("All Staff for #{@school.name}")
      page.should have_css("tr#user_#{@teacher.id}")
      page.should_not have_css("tr#user_#{@teacher.id}.deactivated")
      page.should have_css("tr#user_#{@teacher.id}.active")
      within("tr#user_#{@teacher.id}") do
        page.should have_content("#{@teacher.last_name}")
        page.should have_content("#{@teacher.first_name}")
        page.should have_content("#{@teacher.email}")
        page.should have_css("i.fa-dashboard")
        page.should have_css("i.fa-check")
        page.should have_css("i.fa-ellipsis-h")
        page.should have_css("i.fa-edit") if can_create
        page.should_not have_css("i.fa-edit") if !can_create
        page.should have_css("i.fa-unlock") if can_create
        page.should_not have_css("i.fa-unlock") if !can_create
        # click the deactivate icon
        if can_create
          find('#remove-staff').click
          page.driver.browser.switch_to.alert.accept
        end
      end
      # confirm the user is deactivated
      if can_create
        page.should have_css("tr#user_#{@teacher.id}.deactivated")
        page.should_not have_css("tr#user_#{@teacher.id}.active")
      end

      page.should have_css("tr#user_#{@teacher_deact.id}")
      page.should have_css("tr#user_#{@teacher_deact.id}.deactivated")
      page.should_not have_css("tr#user_#{@teacher_deact.id}.active")
      within("tr#user_#{@teacher_deact.id}") do
        page.should have_content("#{@teacher_deact.last_name}")
        page.should have_content("#{@teacher_deact.first_name}")
        page.should have_content("#{@teacher_deact.email}")
        page.should have_css("i.fa-undo") if can_create && @teacher_deact.active == false
        page.should_not have_css("i.fa-undo") if !can_create && @teacher_deact.active == false
        # click the reactivate icon
        if can_create
          find('#restore-staff').click
          page.driver.browser.switch_to.alert.accept
        end
      end
      # confirm the user is deactivated
      if can_create
        page.should have_css("tr#user_#{@teacher_deact.id}.active")
        page.should_not have_css("tr#user_#{@teacher_deact.id}.deactivated")
      end
    end # within("#page-content") do
  end # def has_valid_subjects_listing


end
