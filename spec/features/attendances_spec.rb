require 'spec_helper'

describe "Shared Examples" do

  shared_examples "AttendanceMaintenance" do
    it "authorized user should be able to create and update attendance records", js: true do
      Attendance.all.count.should == 2
      @attendances.count.should == 2
      visit "/attendances?attendance_date_field=#{@test_date}"
      find('#attendance_date').should have_content("#{@test_date}")
      
      #make sure all attendances for the date are listed
      #todo - fix this when addressing administrative attendance
      @attendances.each do |a|
        within(:css, "#attendance_#{a.id}") do
          if @cur_user.researcher.present?
            # current user is a researcher, should not see actual names
            page.should_not have_content("#{a.student.full_name}")
          else
            page.should have_content("#{a.student.full_name}")
          end
          find("#attendance_#{a.id}_attendance_type").text.should == @attendance_types[a.attendance_type_id].description
          find("#attendance_#{a.id}_excuse").text.should == @excuses[a.excuse_id].description
          find("#attendance_#{a.id}_comment").text.should == a.comment
          if @can_edit
            page.should have_link('View')
            page.should have_link('Edit')
            page.should have_link('Delete')
          else
            page.should_not have_link('View')
            page.should_not have_link('Edit')
            page.should_not have_link('Delete')
          end
        end
      end
      if !@can_edit
        # skip out here if user cannot edit
        break
      end
      
      #edit an attendance item
      #todo - fix this when addressing administrative attendance
      within(:css, "#attendance_#{@attendances[0].id}") do
        click_link('Edit')
      end
      current_path.should == "/attendances/#{@attendances[0].id}/edit"
      find('#attendance_date').should have_content("#{@test_date}")
      within(:css, "#edit_attendance_#{@attendances[0].id}") do
        page.should have_content("#{a.student.full_name}")
        find("select#attendance_#{a.id}_attendance_type").value.should == a.attendance_type_id
        find("select#attendance_#{a.id}_excuse").value.should == a.excuse_id
        find("input#attendance_#{a.id}_comment").value.should == a.comment
      end


    end  # end sysadmin maintenance testing
  end

  shared_examples "NotSeeAttendanceMaintenance" do
    it "should not let unauthorized user see the section attendance page" do
      visit "/attendances/section_attendance/?section_id=#{@section.id}&layout=html_popup"
      page.should_not have_css('#attendance_date')
    end
  end

end

describe "Types of Users tests" do
  before (:each) do
    # init_all_factories
    # @excuse1 = Excuse.new(code: 'Dog', description: 'Dog ate it')
    # @excuse1.school = @school
    # @excuse1.id = 1
    # @excuse1.save
    # @excuse2 = Excuse.new(code: 'Sick', description: 'Sick')
    # @excuse2.school = @school
    # @excuse2.id = 2
    # @excuse2.save
    # @excuse3 = Excuse.new(code: 'Suspended', description: 'Suspended')
    # @excuse3.school = @school
    # @excuse3.id = 3
    # @excuse3.save
    # @excuses = [nil, @excuse1, @excuse2, @excuse3] # by id
    # @attendance_type1 = AttendanceType.new(description: 'Tardy')
    # @attendance_type1.school = @school
    # @attendance_type1.id = 1
    # @attendance_type1.save
    # @attendance_type2 = AttendanceType.new(description: 'Absent')
    # @attendance_type2.school = @school
    # @attendance_type2.id = 2
    # @attendance_type2.save
    # @attendance_types = [nil, @attendance_type1, @attendance_type2] # by id
    # @attendance1 = Attendance.new(attendance_date: '2013-10-01', comment: "he made it!")
    # @attendance1.school_id = @school.id
    # @attendance1.user_id = @joseph_heller.id
    # @attendance1.attendance_type_id = @attendance_type1.id
    # @attendance1.excuse_id = @excuse1.id
    # @attendance1.save
    # @attendance1.errors.full_messages.should == []
    # @attendance1.errors.count.should == 0
    # @attendance2 = Attendance.new(attendance_date: '2013-10-01', comment: "what happened?")
    # @attendance2.school_id = @school.id
    # @attendance2.user_id = @murakami_haruki.id
    # @attendance2.attendance_type_id = @attendance_type2.id
    # @attendance2.excuse_id = @excuse2.id
    # @attendance2.save
    # @attendance2.errors.count.should == 0
    # @attendances = [@attendance1, @attendance2]
    # @test_date = '2013-10-01' # use this date for current date in test (avoid midnight problem)
    # @test_date2 = '2013-10-02' # use this date for current date in test (avoid midnight problem)
  end


  pending "System Administrator should be able to do Attendance Maintenance" do
    before (:each) do
      sign_in(@system_administrator, "sysadminpass")
      @cur_user = @system_administrator
      @can_edit = true
      set_users_school(@school)
    end
      it_behaves_like "AttendanceMaintenance"
  end
  pending "School Administrator should be able to do Attendance Maintenance" do
    before (:each) do
      sign_in(@school_administrator, "secret_admin")
      @cur_user = @school_administrator
      @can_edit = true
    end
    it_behaves_like "AttendanceMaintenance"
  end
  pending "Researcher should be able to only view Attendance Maintenance"  do
    # before (:each) do
    #   sign_in(@researcher, "secret_researcher")
    #   @cur_user = @researcher
    #   @can_edit = false
    #   set_users_school(@school)
    # end
    # it_behaves_like "AttendanceMaintenance"
    it "should probably let researchers at least list the attendance records"
  end
  pending "Teachers should be able to do Attendance Maintenance" do
    before (:each) do
      sign_in(@teacher, "secret_password")
      @cur_user = @teacher
      @can_edit = true
    end
    it_behaves_like "AttendanceMaintenance"
  end
  pending "Students should not be able to see Attendance Maintenance" do
    before (:each) do
      sign_in(@joseph_heller, "secret_password")
      @cur_user = @joseph_heller
    end
    it_behaves_like "NotSeeAttendanceMaintenance"
  end
  pending "Parents should not be able to see Attendance Maintenance" do
    before (:each) do
      @parent = @joseph_heller.parent
      @parent.temporary_password = nil
      @parent.password = "parent_password"
      @parent.password_confirmation = "parent_password"
      @parent.save
      sign_in(@parent, "parent_password")
      @cur_user = @parent
    end
    it_behaves_like "NotSeeAttendanceMaintenance"
  end
  pending "attendance form should" do
    it 'should confirm the page updates when the date is changed'
    # it "should have a date picker popup when the date field is clicked", js: true do
    #   sign_in(@system_administrator, "sysadminpass")
    #   set_users_school(@school)
    #   visit "/attendances/section_attendance/?section_id=#{@section.id}&layout=html_popup"
    #   page.should have_css('#attendance_date_field')
    #   find('#attendance_date_field').click
    #   page.should have_css('#ui-datepicker-div')
    #   find('#ui-datepicker-div tbody td').click
    #   page.driver.browser.switch_to.alert.accept
    # end
    # it "should allow the user to change the date", js: true do
    #   sign_in(@system_administrator, "sysadminpass")
    #   set_users_school(@school)
    #   visit "/attendances/section_attendance/?section_id=#{@section.id}&layout=html_popup"
    #   page.should have_css('#attendance_date_field')
    #   fill_in("attendance_date_field", with: "2013-10-01")
    #   # page.driver.browser.switch_to.alert.accept
    # end
  end

  pending "Dashboards for each user - " do
    it "should have Attendance Maintenance links for System Administrators." do
      # sign_in(@system_administrator, "sysadminpass")
      # @cur_user = @system_administrator
      # @can_edit = true
      # set_users_school(@school)
      # # verify user can list attendances
      # visit "/schools/#{@school.id}"
      # page.should_not have_link("Attendance Maintenance")
      # click_link("Attendance Maintenance")
      # current_path.should == "/attendances?school_id=#{@school.id}"
      # # verify user can list Attendance Types
      # visit "/schools/#{@school.id}"
      # page.should have_link("Attendance Types Maintenance")
      # click_link("Attendance Types Maintenance")
      # current_path.should == "/attendances?school_id=#{@school.id}"
      # # verify user can list Excuses
      # visit "/schools/#{@school.id}"
      # page.should have_link("Excuses Maintenance")
      # click_link("Excuses Maintenance")
      # current_path.should == "/attendances?school_id=#{@school.id}"
    end
    it "should have Attendance Maintenance links for School Administrators."
    it "should have Attendance Maintenance links for Researcher."
    it "should have Attendance Maintenance links for System Administrators."
  end
end


