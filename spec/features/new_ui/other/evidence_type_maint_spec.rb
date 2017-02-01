# evidence_type_maint_spec.rb
require 'spec_helper'


describe "Evidence Type Maintenance", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    # @school1
    @school = FactoryGirl.create :school_current_year, :arabic
    @teacher = FactoryGirl.create :teacher, school: @school
    @subject = FactoryGirl.create :subject, school: @school, subject_manager: @teacher
    @section = FactoryGirl.create :section, subject: @subject
    @discipline = @subject.discipline
    load_test_section(@section, @teacher)

    @evidence_type_ids = @evidences.values.map{ |e| e.evidence_type_id }

  end


  describe "as teacher" do
    before do
      sign_in(@teacher)
      @home_page = "/teachers/#{@teacher.id}"
    end
    it { cannot_see_evid_type_maint }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school
      sign_in(@school_administrator)
      @home_page = "/school_administrators/#{@school_administrator.id}"
    end
    it { cannot_see_evid_type_maint }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      # set_users_school(@school)
      @home_page = "/researchers/#{@researcher.id}"
    end
    it { cannot_see_evid_type_maint }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      # set_users_school(@school)
      @home_page = "/system_administrators/#{@system_administrator.id}"
    end
    it { can_maintain_evid_type }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @home_page = "/students/#{@student.id}"
    end
    it { cannot_see_evid_type_maint }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @home_page = "/parents/#{@student.parent.id}"
    end
    it { cannot_see_evid_type_maint }
  end

  ##################################################
  # test methods

  def cannot_see_evid_type_maint
    # should not have a active toolkit item for System Maint.
    page.should_not have_css("#side-sys-maint")
    page.should_not have_css("a[href='/system_administrators/system_maintenance']")
    # try to go directly to page
    visit system_maintenance_system_administrators_path
    assert_equal(@home_page, current_path)

    # evidence types listing should not have links to new or edit
    visit evidence_types_path
    assert_equal('/evidence_types', current_path)
    page.should_not have_css("a[href='/evidence_types/#{@evidence_type_ids[0]}/edit']")
    page.should_not have_css("a[href='/evidence_types/new']")

    # should not be able to directly maintain evidence types
    visit edit_evidence_type_path(@evidence_type_ids[0])
    assert_equal(@home_page, current_path)
    visit new_evidence_type_path
    assert_equal(@home_page, current_path)

  end # cannot_see_evid_type_maint

  def can_maintain_evid_type
    # this is only seen by a system administrator, so landing page should be the sys admin home page

    # should be on school show page (after selecting school)

    # go to system maintenance page directly
    visit system_maintenance_system_administrators_path
    assert_not_equal(@home_page, current_path)
    assert_equal(system_maintenance_system_administrators_path, current_path)

    # click the evidence type maintenance link
    page.find('#sys-admin-links #evidence-types a').click
    assert_equal('/evidence_types', current_path)

    save_and_open_page

    # page should list the current evidence types
    assert_equal(7, page.all('tr.evidence-item').count )
    within('table') do
      @evidence_type_ids.each do |et|
        Rails.logger.debug("+++ evidence type id: #{et.inspect}")
        page.should have_css("tr#et_#{et}")
      end
    end


    # Add a new evidence type with no description should return error

    # edit returned error form to add new evidence type

    # new evidence type should be listed


    # to do - add deactivate option for evidence types (requires database change and many tests)

  end # can_maintain_evid_type

end
