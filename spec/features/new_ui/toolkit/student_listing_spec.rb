# staff_listing_spec.rb
require 'spec_helper'


describe "Student Listing", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    @school1 = FactoryGirl.create :school, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
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

    @enrollment_s2 = FactoryGirl.create :enrollment, section: @section2_1, student: @student

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
    end
    it { has_valid_student_listing(true, false, false) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { has_valid_student_listing(true, true, true) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { has_valid_student_listing(false, false, true, true) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { has_valid_student_listing(true, true, true) }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { has_no_student_listing(true) }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { has_no_student_listing(false) }
  end

  ##################################################
  # test methods

  def has_no_student_listing(student)
    page.should_not have_css("#side-students")
    visit students_path
    if student
      all('.student-row').count.should == 1
      page.should have_css("a[data-url='/students/#{@student.id}.js']")
      page.should_not have_css("a[data-url='/students/#{@student.id}/edit.js']")
    else
      all('.student-row').count.should == 0
    end
  end

  def has_valid_student_listing(can_create, can_deactivate, can_see_all, read_only=false)
    visit students_path
    assert_equal("/students", current_path)
    within("#page-content") do
      page.should have_content("All Students for: #{@school1.name}")
      page.should have_css("tr#student_#{@student.id}")
      page.should_not have_css("tr#student_#{@student.id}.deactivated")
      within("tr#student_#{@student.id}") do
        page.should have_content("#{@student.last_name}") if can_create
        page.should_not have_content("#{@student.last_name}") if !can_create
        page.should have_content("#{@student.first_name}") if can_create
        page.should_not have_content("#{@student.first_name}") if !can_create
        page.should have_content("#{@student.email}") if can_create
        page.should_not have_content("#{@student.email}") if !can_create
        page.should have_css("i.fa-dashboard")
        page.should have_css("i.fa-check")
        page.should have_css("i.fa-ellipsis-h")
        page.should have_css("i.fa-edit") if can_create
        page.should_not have_css("i.fa-edit") if !can_create
        page.should have_css("i.fa-unlock") if can_deactivate
        # fine tune this, so testing if teachers can unlock students they are assigned to
        # page.should_not have_css("i.fa-unlock") if !can_deactivate
        page.should have_css("i.fa-times-circle") if can_deactivate && @student.active == true
        page.should_not have_css("i.fa-times-circle") if !can_deactivate && @student.active == true
      end
      page.should have_css("tr#student_#{@student_transferred.id}")
      page.should have_css("tr#student_#{@student_transferred.id}.deactivated")
      within("tr#student_#{@student_transferred.id}") do
        page.should have_content("#{@student_transferred.last_name}") if can_create
        page.should_not have_content("#{@student_transferred.last_name}") if !can_create
        page.should have_content("#{@student_transferred.first_name}") if can_create
        page.should_not have_content("#{@student_transferred.first_name}") if !can_create
        page.should have_content("#{@student_transferred.email}") if can_create
        page.should_not have_content("#{@student_transferred.email}") if !can_create
        page.should have_css("i.fa-undo") if can_deactivate && @student_transferred.active == false
        page.should_not have_css("i.fa-undo") if !can_deactivate && @student_transferred.active == false
      end
    end # within("#page-content") do
    can_see_student_dashboard(@student)
    visit students_path
    assert_equal("/students", current_path)
    can_see_student_sections(@student, @enrollment, @enrollment_s2, can_see_all)
    visit students_path
    assert_equal("/students", current_path)
    can_reset_student_password(@student) if !read_only # note: tested more completely in password_change_spec.rb
    can_change_student(@student) if !read_only
    can_create_student(@student) if !read_only
  end # def has_valid_subjects_listing

  ##################################################
  # supporting tests (called from test methods)

  def can_see_student_dashboard(student)
    within("tr#student_#{student.id}") do
      page.should have_css("a[href='/students/#{student.id}']")
      find("a[href='/students/#{student.id}']").click
    end
    assert_equal("/students/#{student.id}", current_path)
  end

  def can_see_student_sections(student, enrollment, enrollment_s2, can_see_all)
    within("tr#student_#{student.id}") do
      page.should have_css("a[href='/students/#{student.id}/sections_list']")
      find("a[href='/students/#{student.id}/sections_list']").click
    end
    assert_equal("/students/#{student.id}/sections_list", current_path)
    within("tr#enrollment_#{enrollment_s2.id}") do
      if can_see_all
        page.should have_css("a[href='/enrollments/#{enrollment_s2.id}']")
        find("a[href='/enrollments/#{enrollment_s2.id}']").click
        visit("/students/#{student.id}/sections_list")
        assert_equal("/students/#{student.id}/sections_list", current_path)
      else
        # should not see link to tracker page for section not teaching that section
        page.should_not have_css("a[href='/enrollments/#{enrollment_s2.id}']")
      end
    end
    within("tr#enrollment_#{enrollment.id}") do
      page.should have_css("a[href='/enrollments/#{enrollment.id}']")
      find("a[href='/enrollments/#{enrollment.id}']").click
    end
    assert_equal("/enrollments/#{enrollment.id}", current_path)
  end

  def can_reset_student_password(student)
    within("tr#student_#{student.id}") do
      page.should have_css("a[data-url='/students/#{student.id}/security.js']")
      find("a[data-url='/students/#{student.id}/security.js']").click
    end
    page.should have_content("Student/Parent Security and Access")
    within("#user_#{student.id}") do
      page.should have_css("a[href='/students/#{student.id}/set_student_temporary_password']")
      find("a[href='/students/#{student.id}/set_student_temporary_password']").click
    end
    within("#user_#{student.id}.student-temp-pwd") do
      page.should_not have_content('(Reset Password')
    end

  end
  def can_change_student(student)
    within("tr#student_#{student.id}") do
      page.should have_css("a[data-url='/students/#{student.id}/edit.js']")
      find("a[data-url='/students/#{student.id}/edit.js']").click
    end
    page.should have_content("Edit Student")
    within("#modal_popup .modal-dialog .modal-content .modal-body") do
      within("form#edit_student_#{student.id}") do
        # page.select(@subject2_1.discipline.name, from: "subject-discipline-id")
        page.fill_in 'student_first_name', :with => 'Changed Fname'
        page.fill_in 'student_last_name', :with => 'Changed Lname'
        # confirm the required flag is displayed (this school has username by email)
        page.should have_css("#email span.ui-required")
        page.fill_in 'student_email', :with => ''
        page.click_button('Save')
      end
    end
    # ensure that blank email gets an error on updates
    page.should have_css("#modal_popup form#edit_student_#{student.id}")
    within("#modal_popup .modal-dialog .modal-content .modal-body") do
      within("form#edit_student_#{student.id}") do
        page.should have_css('span.ui-error', text:'Email is required.')
        page.fill_in 'student_email', :with => 'changed@email.address'
        page.click_button('Save')
      end
    end
    page.should_not have_css("#modal_popup form#edit_student_#{student.id}")
    assert_equal("/students", current_path)
    within("tr#student_#{student.id}") do
      page.should have_css("a[data-url='/students/#{student.id}.js']")
      find("a[data-url='/students/#{student.id}.js']").click
    end
    page.should have_content("View Student")
    within("#modal_popup .modal-dialog .modal-content .modal-body") do
      page.should have_content('Changed Fname')
      page.should have_content('Changed Lname')
      page.should have_content('changed@email.address')
    end
  end

  def can_create_student(student)
    within("div#page-content") do
      page.should have_css("a[data-url='/students/new.js']")
      find("a[data-url='/students/new.js']").click
    end
    page.should have_content("Create New Student")
    within("#modal_popup .modal-dialog .modal-content .modal-body") do
      within("form#new_student") do
        page.fill_in 'student_first_name', :with => ''
        page.fill_in 'student_last_name', :with => ''
        # confirm the required flag is displayed (this school has username by email)
        page.should have_css("#email span.ui-required")
        page.fill_in 'student_email', :with => ''
        page.fill_in 'student_grade_level', :with => '4'
        page.click_button('Save')
      end
    end
    # ensure that blank email gets an error on creates
    page.should have_css("#modal_popup form#new_student")
    within("#modal_popup .modal-dialog .modal-content .modal-body") do
      within("form#new_student") do
        page.should have_css('#first-name span.ui-error', text:'["can\'t be blank"]')
        page.fill_in 'student_first_name', :with => 'New Fname'
        page.should have_css('#last-name span.ui-error', text:'["can\'t be blank"]')
        page.fill_in 'student_last_name', :with => 'New Lname'
        page.should have_css('#email span.ui-error', text:'["Email is required."]')
        page.fill_in 'student_email', :with => 'new@email.address'
        page.should have_css('#grade-level span.ui-error', text:'["Grade Level is invalid"]')
        page.fill_in 'student_grade_level', :with => '2'
        page.click_button('Save')
      end
    end
    page.should_not have_css("#modal_popup form#new_student")
    assert_equal("/students", current_path)
    # expect(page.text).to match(/New\sFname/) # alternate syntax
    page.text.should match(/New\sFname/)
    # expect(page.text).to match(/New\sLname/) # alternate syntax
    page.text.should match(/New\sLname/)
    page.should have_content('new@email.address')

    # confirm error on duplicate email
    within("div#page-content") do
      page.should have_css("a[data-url='/students/new.js']")
      find("a[data-url='/students/new.js']").click
    end
    page.should have_content("Create New Student")
    within("#modal_popup .modal-dialog .modal-content .modal-body") do
      within("form#new_student") do
        page.fill_in 'student_first_name', :with => 'Another New Fname'
        page.fill_in 'student_last_name', :with => 'Another New Lname'
        page.fill_in 'student_email', :with => 'new@email.address'
        page.fill_in 'student_grade_level', :with => '2'
        page.click_button('Save')
      end
    end
    # ensure that duplicate email gets an error on creates
    page.should have_css("#modal_popup form#new_student")
    within('#modal_popup #modal-message') do
      page.should have_content('Username has already been taken')
    end
  end


end
