# subject_sections_listing_spec.rb
require 'spec_helper'


describe "Subjects Sections Listing", js:true do
  before (:each) do

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

    # another subject in @school2
    @section3_1 = FactoryGirl.create :section
    @subject3 = @section3_1.subject
    @school2 = @section3_1.school
    @teacher2 = @subject1.subject_manager
    @section3_2 = FactoryGirl.create :section, subject: @subject3
    @section3_3 = FactoryGirl.create :section, subject: @subject3

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
    end
    it { has_valid_subjects_listing(false, true) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { has_valid_subjects_listing(false, true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { has_valid_subjects_listing(false, false) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { has_valid_subjects_listing(true, true) }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { has_no_subjects_listing }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { has_no_subjects_listing }
  end

  ##################################################
  # test methods

  def has_no_subjects_listing
    visit subjects_path()
    assert_not_equal("/subjects", current_path)
  end

  def has_valid_subjects_listing(can_create_subject, can_create_section)
    visit subjects_path

    # ensure subject managers and subject administrators can see their subjects
    if(@test_user.id == @subject1.subject_manager_id ||
      @test_user.has_permission?('subject_admin') ||
      @test_user.role_symbols.include?('system_administrator'.to_sym)
      # School administrators must be given subject administrator to see this
      # (@test_user.role_symbols.include?('school_administrator'.to_sym) && @test_user.school_id == @school1.id)
    )
      page.should have_css("a[href='/subjects/#{@subject1.id}/edit_subject_outcomes']")
    else
      page.should_not have_css("a[href='/subjects/#{@subject1.id}/edit_subject_outcomes']")
      page.should have_css("a[data-url='/subjects/#{@subject1.id}/view_subject_outcomes']")
    end
    if(@test_user.id == @subject2.subject_manager_id ||
      @test_user.has_permission?('subject_admin') ||
      @test_user.role_symbols.include?('system_administrator'.to_sym)
      # School administrators must be given subject administrator to see this
      # (@test_user.role_symbols.include?('school_administrator'.to_sym) && @test_user.school_id == @school1.id)
    )
      page.should have_css("a[href='/subjects/#{@subject2.id}/edit_subject_outcomes']")
    else
      page.should_not have_css("a[href='/subjects/#{@subject2.id}/edit_subject_outcomes']")
      page.should have_css("a[data-url='/subjects/#{@subject2.id}/view_subject_outcomes']")
    end
    # no tests for subject3, because it is in a different school, so whould not be shown

    within("#page-content") do
      page.should have_content('Subjects / Sections Listing')
      page.should_not have_content("#{@subject3.discipline.name} : #{@subject3.name}")
      within("tbody#subj_header_#{@subject1.id}") do
        page.should have_content("#{@subject1.discipline.name} : #{@subject1.name}")
        page.should_not have_content("#{@subject2.discipline.name} : #{@subject2.name}")
      end
      within("tbody#subj_body_#{@subject1.id}") do
        within("#sect_#{@section1_1.id}") do
          page.should have_content("#{@teacher1.full_name}")
          page.should have_content("#{@section1_1.line_number}")
          page.should have_content("#{@section1_1.active_students.count}")
        end
        within("#sect_#{@section1_2.id}") do
          page.should have_content("#{@teacher1.full_name}")
          page.should have_content("#{@section1_2.line_number}")
          page.should have_content("#{@section1_2.active_students.count}")
        end
        within("#sect_#{@section1_3.id}") do
          page.should have_content("#{@teacher1.full_name}")
          page.should have_content("#{@section1_3.line_number}")
          page.should have_content("#{@section1_3.active_students.count}")
        end
        page.should_not have_css("#sect_#{@section2_1.id}")
        page.should_not have_css("#sect_#{@section2_2.id}")
        page.should_not have_css("#sect_#{@section2_3.id}")
      end

      within("tbody#subj_header_#{@subject2.id}") do
        page.should_not have_content("#{@subject1.discipline.name} : #{@subject1.name}")
        page.should have_content("#{@subject2.discipline.name} : #{@subject2.name}")
      end
      within("tbody#subj_body_#{@subject2.id}") do
        within("#sect_#{@section2_1.id}") do
          page.should_not have_content("#{@teacher1.full_name}")
          page.should have_content("#{@section2_1.line_number}")
          page.should have_content("#{@section2_1.active_students.count}")
        end
        within("#sect_#{@section2_2.id}") do
          page.should_not have_content("#{@teacher1.full_name}")
          page.should have_content("#{@section2_2.line_number}")
          page.should have_content("#{@section2_2.active_students.count}")
        end
        within("#sect_#{@section2_3.id}") do
          page.should_not have_content("#{@teacher1.full_name}")
          page.should have_content("#{@section2_3.line_number}")
          page.should have_content("#{@section2_3.active_students.count}")
        end
        page.should_not have_css("#sect_#{@section1_1.id}")
        page.should_not have_css("#sect_#{@section1_2.id}")
        page.should_not have_css("#sect_#{@section1_3.id}")
      end
        
      # click on right arrow should minimize subject
      page.should_not have_css("tbody#subj_header_#{@subject1.id}.show-tbody-body")
      page.should_not have_css("tbody#subj_header_#{@subject2.id}.show-tbody-body")
      find("a#subj_header_#{@subject1.id}_a").click
      page.should have_css("tbody#subj_header_#{@subject1.id}.show-tbody-body")
      # click on down arrow should maximize subject
      find("a#subj_header_#{@subject1.id}_a").click
      page.should_not have_css("tbody#subj_header_#{@subject1.id}.show-tbody-body")


      # todo - click on down arrow at top of page should maximize all subjects
      find("a#expand-all-tbodies").click
      page.should have_css("tbody#subj_header_#{@subject1.id}.show-tbody-body")
      page.should have_css("tbody#subj_header_#{@subject2.id}.show-tbody-body")

      # todo - click on right arrow at top of page should minimize all subjects
      find("a#collapse-all-tbodies").click
      page.should_not have_css("tbody#subj_header_#{@subject1.id}.show-tbody-body")
      page.should_not have_css("tbody#subj_header_#{@subject2.id}.show-tbody-body")

      # if (can_create_subject)
      #   # click on add subject should show add subject popup

    end # within("#page-content") do

    if (can_create_subject)
      # click on add subject should show add subject popup
      page.should have_css("a[data-url='/subjects/new.js']")
      find("a[data-url='/subjects/new.js']").click
      within('#modal-body') do
        within('h3') do
          page.should have_content('Create Subject')
        end
      end

      # click on edit subject should show edit subject popup
      page.should have_css("a[data-url='/subjects/#{@subject1.id}/edit.js']")
      find("a[data-url='/subjects/#{@subject1.id}/edit.js']").click
      within('#modal-body') do
        within('h3') do
          page.should have_content("Edit Subject - #{@subject1.name}")
        end
      end
    else
      page.should_not have_css("a#add-subject")
      page.should_not have_css("a[data-url='/subjects/#{@subject1.id}/edit.js']")
    end

    if (can_create_section)

      find("a#collapse-all-tbodies").click
      page.should_not have_css("tbody#subj_header_#{@subject1.id}.show-tbody-body")
      page.should_not have_css("tbody#subj_header_#{@subject2.id}.show-tbody-body")

      find("a#subj_header_#{@subject1.id}_a").click

      # click on edit section should show edit section popup
      page.should have_css("a[data-url='/sections/#{@section1_2.id}/edit.js']")
      find("a[data-url='/sections/#{@section1_2.id}/edit.js']").click

      within('#modal-body') do
        within('h2') do
          # if(can_create_subject)
          #   page.should have_content("Edit Section: Changed Subject Name - #{@section1_2.line_number}")
          # else
            page.should have_content("Edit Section: #{@section1_2.name} - #{@section1_2.line_number}")
          # end
        end
        within('#section_line_number') do
          page.should_not have_content(@section1_2.subject.name)
        end
        page.should have_selector("#section_line_number", value: "#{@section1_2.line_number}")
        page.fill_in 'section_line_number', :with => 'Changed Section ID'
        # within('#section_message') do
        #   page.should have_content(@section1_2.message)
        # end
        page.should have_selector("#section_school_year_id", value: "#{@section1_2.school_year.name}")
        page.click_button('Save')
      end

      if (can_create_section)
        # # click on add section should show add section popup
        # Rails.logger.debug("*** subj_header_#{@section1_2.subject.id}")
        # find("subj_header_#{@section1_2.subject.id} a.add-section").click
        # within('#modal-body') do
        #   within('h3') do
        #     page.should have_content("Add Section")
        #   end
        #   # within('#section_line_number') do
        #   #   page.should_not have_content(@section1_2.subject.name)
        #   # end
        #   # page.should have_selector("#section_line_number", value: "#{@section1_2.line_number}")
        #   # page.fill_in 'section_line_number', :with => 'Changed Section ID'
        #   # within('#section_message') do
        #   #   page.should have_content(@section1_2.message)
        #   # end
        #   # page.should have_selector("#section_school_year_id", value: "#{@section1_2.school_year.name}")
        #   # page.click_button('Save')
        # end

        # # save should go back to section listing

      end

# <<<<<<< HEAD
#       if (can_create)
#         # # click on add section should show add section popup
#       end

#     end # within("#page-content") do
# =======
      # user should see add section icon
      page.should have_css("a[href='/sections/new?subject_id=#{@subject1.id}']")
      find("a[href='/sections/new?subject_id=#{@subject1.id}']").click

      # click on add section should show add section popup
      # Rails.logger.debug("*** subj_header_#{@section1_2.subject.id}")
      # find("subj_header_#{@section1_2.subject.id} a.add-section").click
      # within('#modal-body') do
      #   within('h3') do
      #     page.should have_content("Add Section")
      #   end
      #   # within('#section_line_number') do
      #   #   page.should_not have_content(@section1_2.subject.name)
      #   # end
      #   # page.should have_selector("#section_line_number", value: "#{@section1_2.line_number}")
      #   # page.fill_in 'section_line_number', :with => 'Changed Section ID'
      #   # within('#section_message') do
      #   #   page.should have_content(@section1_2.message)
      #   # end
      #   # page.should have_selector("#section_school_year_id", value: "#{@section1_2.school_year.name}")
      #   # page.click_button('Save')
      # end
      # # save should go back to section listing
    else
      page.should_not have_css("a[data-url='/sections/#{@section1_2.id}/edit.js']")
      page.should_not have_css("a[href='/sections/new?subject_id=#{@subject1.id}']")
    end

  end # def has_valid_subjects_listing


end
