require 'spec_helper'

describe "Gradebook -" do
  before do
    @section = create :section
    @school = @section.school
    @teacher = @section.subject.subject_manager #set teacher to subjects' manager
    create :teaching_assignment, teacher: @teacher, section: @section
    @section_outcome = create :section_outcome, section: @section
    @evidence = create :evidence, section: @section
    @eso = create :evidence_section_outcome, section_outcome: @section_outcome, evidence: @evidence
    @student = create :student, school: @school
    create :enrollment, student: @student, section: @section
    @esor = create :evidence_section_outcome_rating, evidence_section_outcome: @eso, rating: "Y", comment: "Mediocre", student: @student
    @evidence_attachment = create :evidence_attachment, evidence: @evidence
    @evidence_hyperlink = create :evidence_hyperlink, evidence: @evidence
  end

  context "As a system administrator -" do
    before do
      @system_administrator = create :system_administrator
      sign_in @system_administrator
      visit section_path(@section)
      find("td#evidence_#{@eso.id}").find(".evidence_attachments").should have_content 2 # 1 attachments + 1 hyperlinks = 2
      find("td#evidence_#{@eso.id}").find(".evidence_attachments").click
    end

    it "should have a valid display", js: true do
      confirm_has_valid_attachments_popup
    end    
  end

  context "As a teacher -" do
    before do
      sign_in @teacher
      visit section_path(@section)
      find("td#evidence_#{@eso.id}").find(".evidence_attachments").should have_content 2 # 1 attachments + 1 hyperlinks = 2
      find("td#evidence_#{@eso.id}").find(".evidence_attachments").click
    end

    it "should have a valid display", js: true do
      confirm_has_valid_attachments_popup
    end    
  end

  context "As a school administrator -" do
    before do
      @school_administrator = create :school_administrator, school: @school
      sign_in @school_administrator
      visit section_path(@section)
      find("td#evidence_#{@eso.id}").find(".evidence_attachments").should have_content 2 # 1 attachments + 1 hyperlinks = 2
      find("td#evidence_#{@eso.id}").find(".evidence_attachments").click
    end

    it "should have a valid display", js: true do
      confirm_has_valid_attachments_popup
    end    
  end

  def confirm_has_valid_attachments_popup

    hyperlink1_url = "http://www.economist.com"
    hyperlink1_text = "Economist"
    hyperlink2_url = "http://www.wsj.com"
    hyperlink2_text = "Wall Street Journal"

    # it should be in a popup
    page.should have_css("#popup_form")

    # it should list the initial attachment
    page.should have_css("#popup_form #evidence_attachment_#{@evidence_attachment.id}")
    page.should have_css("#popup_form #evidence_attachment_#{@evidence_attachment.id} a", :text => @evidence_attachment.name)
    page.should have_css("#popup_form #evidence_attachment_#{@evidence_attachment.id} a[@href='#{@evidence_attachment.attachment.url}']")

    # it should list the initial hyperlink
    page.should have_css("#popup_form #evidence_hyperlink_#{@evidence_hyperlink.id}")
    page.should have_css("#popup_form #evidence_hyperlink_#{@evidence_hyperlink.id} a", :text => @evidence_hyperlink.title)
    page.should have_css("#popup_form #evidence_hyperlink_#{@evidence_hyperlink.id} a[@href='#{@evidence_hyperlink.hyperlink}']")

    # it should be able to remove an attached file
    check "evidence_attachment_#{@evidence_attachment.id}_remove"

    # it should be able to remove a hyperlink
    check "evidence_hyperlink_#{@evidence_hyperlink.id}_remove"

    # update changes
    click_button "Update Evidence"

    # confirm attachments count is correct in gradebook
    find("td#evidence_#{@eso.id}").find(".evidence_attachments").should have_content 0 # 0 attachments + 0 hyperlinks = 0

    # open up attachments popup
    find("td#evidence_#{@eso.id}").find(".evidence_attachments").click

    # it should be in a popup
    page.should have_css("#popup_form")

    # it should be able to add two file attachments
    page.should have_css("#popup_form input[@type='file']")
    page.should have_css("#popup_form button", :text => 'Add Another Attachment')
    # todo - mock file upload, create dummy test file, and save
    # manual_test - attach two files and confirm attached

    # it should not list the initial attachment
    page.should_not have_css("#popup_form #evidence_attachment_#{@evidence_attachment.id}")

    # it should not list the initial hyperlink
    page.should_not have_css("#popup_form #evidence_hyperlink_#{@evidence_hyperlink.id}")

    # # it should be able to add new attachments
    # todo - once mock file upload

    # it should be able to add two hyperlinks
    fill_in "evidence_evidence_hyperlinks_attributes_30_hyperlink", with: hyperlink1_url
    fill_in "evidence_evidence_hyperlinks_attributes_30_title", with: hyperlink1_text
    click_button "Add Another Hyperlink"
    fill_in "evidence_evidence_hyperlinks_attributes_31_hyperlink", with: hyperlink2_url
    fill_in "evidence_evidence_hyperlinks_attributes_31_title", with: hyperlink2_text

    # update changes
    click_button "Update Evidence"

    # confirm attachments count is correct in gradebook
    find("td#evidence_#{@eso.id}").find(".evidence_attachments").should have_content 2 # 0 attachments + 2 hyperlinks = 2

    # open up attachments popup
    find("td#evidence_#{@eso.id}").find(".evidence_attachments").click

    # it should be in a popup
    page.should have_css("#popup_form")

    # # it should list the new attachments
    # todo - once mock file upload is done, confirm they are attached

    # it should list the new hyperlinks
    page.should have_css("#popup_form a", :text => hyperlink1_text)
    page.should have_css("#popup_form a[@href='#{hyperlink1_url}']")
    page.should have_css("#popup_form a", :text => hyperlink2_text)
    page.should have_css("#popup_form a[@href='#{hyperlink2_url}']")

  end

end
