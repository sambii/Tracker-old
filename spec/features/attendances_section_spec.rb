require 'spec_helper'

describe "Shared Examples" do

  shared_examples "SectionAttendance" do
    it "authorized user should be able to create and update section attendance records", js: true do
      visit section_path(@section)
      find("#tools").click
      find("#tools_section_attendance").click
      # @enrollments = Enrollment.where(section_id: @section.id).includes(:student).alphabetical
      @section = Section.find(@section.id)
      #@enrollments = Enrollment.includes(:student).where(section_id: @section.id).alphabetical
      find('#attendance_date').should have_content("#{@test_date}")
      # should see all students enrolled to section
      within_table("attendance_table") do
        # make sure all enrollments are listed and with empty attendance record
        @enrollments.each do |e|
          if @cur_user.researcher.present?
            # current user is a researcher, should not see actual names
            page.should_not have_content("#{e.student.full_name}")
            find("td#attendance_#{e.student_id}_full_name").text.should_not == e.student.full_name
          else
            page.should have_content("#{e.student.full_name}")
            find("td#attendance_#{e.student_id}_full_name").text.should == e.student.full_name
          end
          find("select#attendance_#{e.student_id}_attendance_type_id").value.should == ''
          find("select#attendance_#{e.student_id}_excuse_id").value.should == ''
          find("input#attendance_#{e.student_id}_comment").value.should == ''
        end
      end

      if @can_edit
        select(@attendance_type1.description, from: "attendance_#{@enrollments[0].student_id.to_s}_attendance_type_id")
        select(@excuse1.description, from: "attendance_#{@enrollments[1].student_id.to_s}_excuse_id")
        fill_in("attendance_#{@enrollments[2].student_id.to_s}_comment", with: "suprise, suprise")

        Attendance.scoped.count.should == 0
        find('#save_attendance').click()
        #
        # check to see if insert worked and errors returned
        find('#attendance_date').should have_content("#{@test_date}")
        Attendance.scoped.count.should == 1
        find("#alert").text.should == I18n.translate('alerts.errors_see_below')
        page.should_not have_css("tr#attendance_#{@enrollments[0].student_id.to_s} td.error_description")
        page.should have_css("tr#attendance_#{@enrollments[1].student_id.to_s} td.error_description")
        find("tr#attendance_#{@enrollments[1].student_id.to_s} td.error_description").text.should =~ /#{I18n.translate('errors.cant_be_blank')}/
        page.should have_css("tr#attendance_#{@enrollments[2].student_id.to_s} td.error_description")
        find("tr#attendance_#{@enrollments[2].student_id.to_s} td.error_description").text.should =~ /#{I18n.translate('errors.cant_be_blank')}/
        #
        # put in an update - remove first one, and fix the second one
        select('', from: "attendance_#{@enrollments[0].student_id.to_s}_attendance_type_id")
        select(@attendance_type2.description, from: "attendance_#{@enrollments[1].student_id.to_s}_attendance_type_id")
        fill_in("attendance_#{@enrollments[1].student_id.to_s}_comment", with: "yep got it")
        fill_in("attendance_#{@enrollments[2].student_id.to_s}_comment", with: "")
        find('#save_attendance').click()
        #
        find('#attendance_date').should have_content("#{@test_date}")
        Attendance.scoped.count.should == 1
        page.should_not have_css("#alert")
        page.should_not have_css("tr#attendance_#{@enrollments[0].student_id.to_s} td.error_description")
        page.should have_css("select#attendance_#{@enrollments[0].student_id.to_s}_attendance_type_id")
        # note for no deletion of prior days code, we will be expecting the original value of the record to be returned, not the attempted bad update
        # find("select#attendance_#{@enrollments[0].student_id.to_s}_attendance_type_id").value.should == @attendance_type1.id.to_s
        find("select#attendance_#{@enrollments[0].student_id.to_s}_attendance_type_id").value.should == ''
        find("select#attendance_#{@enrollments[0].student_id.to_s}_excuse_id").value.should == ''
        find("input#attendance_#{@enrollments[0].student_id.to_s}_comment").value.should == ""
        # find("tr#attendance_#{@enrollments[0].student_id.to_s} td.error_description").text.should =~ /#{I18n.translate('errors.cannot_delete_attendance_record')}/
        find("select#attendance_#{@enrollments[1].student_id.to_s}_attendance_type_id").value.should == @attendance_type2.id.to_s
        find("input#attendance_#{@enrollments[1].student_id.to_s}_comment").value.should == "yep got it"
        find("input#attendance_#{@enrollments[2].student_id.to_s}_comment").value.should == ''
        #
        # hitting close button should bring user back to section page
        find('a', :text => 'Close').click()
        current_path.should == section_path(@section)
      else
        # ensure they cannot cannot edit
        page.should_not have_button('Save Attendance')
        # todo: add a controller test to ensure a post would fail for this user
        # cannot figure out how to exit out of shared example
        # - return gives error:  Failure/Error: return / LocalJumpError: / unexpected return
        # - break gives error:  Failure/Error: break / LocalJumpError: / break from proc-closure
      end
    end  # end sysadmin maintenance testing
  end

  shared_examples "NotSeeSectionAttendance" do
    it "should not let unauthorized user see the section attendance page" do
      visit section_attendance_attendances_path+"?section_id=#{@section.id}"
      page.should_not have_css('#attendance_date')
    end
  end

end

describe "Types of Users tests" do
  before (:each) do
    #init_all_factories
    @section = create :section
    @school = @section.school
    @subject = @section.subject
    @excuse1 = create :excuse, school: @school
    @excuses = create_list :excuse, 2

    @attendance_type1 = create :attendance_type, school: @school
    @attendance_type2 = create :attendance_type, school: @school
    @attendance_types = [@attendance_type1, @attendance_type2]

    students = create_list :student, 3, school: @school
    @enrollments = []
    students.each do |student|
      @enrollments << create(:enrollment, student: student, section: @section)
    end

    @test_date = Time.now.to_date.to_s # use this date for current date in test (avoid midnight problem)
    @yesterday_date = Date.yesterday.to_s # yesterday
  end

  context "System Administrator should be able to do section attendance", js: true do
    before (:each) do
      @system_administrator = create :system_administrator
      sign_in @system_administrator
      @cur_user = @system_administrator
      @can_edit = true
      set_users_school(@school)
    end
      it_behaves_like "SectionAttendance"
  end
  context "School Administrator should be able to do section attendance", js: true do
    before (:each) do
      @school_administrator = create :school_administrator, school: @school
      sign_in @school_administrator
      @cur_user = @school_administrator
      @can_edit = true
    end
    it_behaves_like "SectionAttendance"
  end
  context "Researcher should be able to only view section attendance", js: true do
    before (:each) do
      @researcher = create :researcher
      sign_in @researcher
      @cur_user = @researcher
      @can_edit = false
      set_users_school(@school)
    end
    it_behaves_like "SectionAttendance"
  end
  context "Teachers should be able to do section attendance", js: true do
    before (:each) do
      @teacher = create :teacher, school: @school
      create :teaching_assignment, teacher: @teacher, section: @section
      sign_in @teacher
      @cur_user = @teacher
      @can_edit = true
    end
    it_behaves_like "SectionAttendance"
    it "should let teachers only see attendance for sections they are assigned to" do
      visit section_attendance_attendances_path+"?section_id=#{@section.id}"

      find('h3').text.should =~ /#{@subject.name}/
      find('h3').text.should =~ /#{@section.line_number}/
    end
  end
  context "Students should not be able to see section attendance", js: true do
    before (:each) do
      @student = create :student, school: @school
      sign_in @student
    end
    it_behaves_like "NotSeeSectionAttendance"
  end
  context "Parents should not be able to see section attendance", js: true do
    before (:each) do
      @student = create :student, school: @school

      @parent = @student.parent
      @parent.temporary_password = nil
      @parent.password = "parent_password"
      @parent.password_confirmation = "parent_password"
      @parent.save

      sign_in @parent
    end
    it_behaves_like "NotSeeSectionAttendance"
  end
  context "attendance form should" do
    it 'should confirm the page updates when the date is changed'
    # it "should have a date picker popup when the date field is clicked", js: true do
    #   sign_in(@system_administrator, "sysadminpass")
    #   set_users_school(@school)
    #   visit section_attendance_attendances_path+"?section_id=#{@section.id}"
    #   page.should have_css('#attendance_date_field')
    #   find('#attendance_date_field').click
    #   page.should have_css('#ui-datepicker-div')
    #   find('#ui-datepicker-div tbody td').click
    #   page.driver.browser.switch_to.alert.accept
    # end
    # it "should allow the user to change the date", js: true do
    #   sign_in(@system_administrator, "sysadminpass")
    #   set_users_school(@school)
    #   visit section_attendance_attendances_path+"?section_id=#{@section.id}"
    #   page.should have_css('#attendance_date_field')
    #   fill_in("attendance_date_field", with: "2013-10-01")
    #   # page.driver.browser.switch_to.alert.accept
    # end
  end
  it "should let users clear out the attendance type for todays attendance."
  it "should let users clear out the attendance type if there is a comment for prior days attendance."
  it "might allow for setting the attendance to present or something like that instead of clearing out attendance type."
  it 'should warn and prevent updates of section attendance with deactivated attendance-type or excuse.'
  it 'should show deactivated attendance types and excuses in select boxes only if it was already saved with one.'
  it 'should handle invalid session[:close_to_path] when closing Section Attendance'
  it 'confirm that a teacher cannot visit a section attendance page that is not one of their sections'
  it 'test for proper display of deactivated students'
end


