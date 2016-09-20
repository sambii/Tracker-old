# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class StudentsController < ApplicationController

  include StudentsHelper

  load_and_authorize_resource

  # skip_load_and_authorize_resource only: :index

  # New UI
  # Student Dashboard page
  #   GET "/students/#"
  #   Parameters: {"id"=>"#"}
  #   Rendered students/show.html.haml within layouts/application
  # Popup for Student Listing
  #   GET "/students/#.js"
  #   Parameters: {"id"=>"#"}
  def show
    # @sections = @student.active_sections.includes(:subject, :teachers)
    # @section_outcome_rating_counts = @student.hash_of_section_outcome_rating_counts
    # @active_enrollments = Enrollment.includes(:section).alphabetical.current.where(student_id: @student)
    @active_enrollments = Enrollment.includes(:section).current.where(student_id: @student)
    current_sect_ids = @active_enrollments.pluck(:section_id)
    Rails.logger.debug("*** current_sect_ids: #{current_sect_ids}")
    @ratings = @student.hash_of_section_outcome_rating_counts(section_ids: current_sect_ids)
    @e_over_cur = @student.overall_current_evidence_ratings
    @e_weekly_cur = @student.overall_current_evidence_ratings 1.week.ago
    @missing = @student.missing_evidences_by_section
    @parent = @student.get_parent

    respond_to do |format|
      format.html
      format.js # show user popup from student listing
    end
  end

  # New UI
  # - Students listing (from toolkit)
  # - Generate Reports - Proficiency Bars
  def index
    authorize! :index, Student

    template = "students/reports/#{params[:report]}" if params[:report].present?
    template ||= "index"

    @school = get_current_school

    # todo performance tune this report.  Note view calls student.rb ratings_count method which does SQL against SectionOutcomeRating table for each student.

    if template == "index"
      # @students = Student.accessible_by(current_ability).active.includes(:parent).order(:grade_level, :last_name, :first_name)
      if @school.has_flag?(School::USER_BY_FIRST_LAST)
        @students = Student.includes(:parent).accessible_by(current_ability).order(:first_name, :last_name).scoped
      else
        @students = Student.includes(:parent).accessible_by(current_ability).order(:last_name, :first_name).scoped
      end
    else
      authorize! :proficiency_bars, Student
      @students = Student.accessible_by(current_ability).active.order(:last_name, :first_name).scoped
    end

    respond_to do |format|
      if @school.id.present?
        @students = @students.where(school_id: @school.id)
        format.html { render template }
      else
        @students
        flash[:alert] = "Please pick a school."
        format.html {redirect_to schools_path}
      end
    end
  end

  # # New UI
  # # Students listing (from toolkit)
  # def index
  #   @students = Student.includes(:parent).accessible_by(current_ability).order(:last_name, :first_name).scoped
  #   @school = get_current_school
  #   respond_to do |format|
  #     if @school.id.present?
  #       @students = @students.where(school_id: @school.id)
  #       format.html
  #     else
  #       @students
  #       flash[:alert] = "Please pick a school."
  #       format.html {redirect_to schools_path}
  #     end
  #   end
  # end

  # New UI
  def new
    @student = Student.new
    @parent = Parent.new
    respond_to do |format|
      format.js
    end
  end

  # New UI
  def create
    @school = get_current_school
    @student.school_id = @school.id
    @student.set_unique_username
    @student.set_temporary_password

    respond_to do |format|
      if @student.save
        begin
          UserMailer.welcome_user(@student, @school, get_server_config).deliver
        rescue => e
          Rails.logger.error("Error: Student Email missing ServerConfigs record with support_email address")
          raise InvalidConfiguration, "Missing ServerConfigs record with support_email address"
        end
        @parent = @student.parent
        parent_status = @parent.update_attributes(params[:parent])
        begin
          UserMailer.welcome_user(@parent, @school, get_server_config).deliver
        rescue => e
          Rails.logger.error("Error: Parent Email missing ServerConfigs record with support_email address")
          raise InvalidConfiguration, "Missing ServerConfigs record with support_email address"
        end
        if !parent_status
          flash[:alert] = @parent.errors.full_messages
        end
        format.js
      else
        # @parent = Parent.new
        @parent = @student.parent
        if !@parent
          @parent = Parent.new
          @parent.errors.add(:base, 'ERROR - Missing parent/guardian record')
          # todo notify trackersupport
        elsif params[:parent]
          parent_status = @parent.update_attributes(params[:parent])
        else
          parent_status = true
        end
        if !parent_status
          flash[:alert] = @student.errors.full_messages << @parent.errors.full_messages
        else
          flash[:alert] = @student.errors.full_messages
        end
        format.js # { render js: "alert('Student not successfully created!')"}
      end
    end
  end

  # New UI
  # Students edit screen via js
  def edit
    @parent = @student.get_parent
    respond_to do |format|
      format.js
    end
  end


  # New UI
  # Students update from edit screen via HTML
  # Edit Student from Students listing via js
  def update
    @school = get_current_school
    lname = params[:student][:last_name]
    reload_student_list = (lname.present? && lname != @student.last_name && lname[0] != @student.last_name[0]) ? true : false

    student_status = @student.update_attributes(params[:student])
    if student_status && params[:student][:password].present? && params[:student][:temporary_password].present?
      UserMailer.changed_user_password(@student, @school, get_server_config).deliver # deliver after save
    end
    parent_status = true
    @parent = @student.parent
    parent_status = @parent.update_attributes(params[:parent])

    respond_to do |format|
      if student_status && parent_status
        # successful update of both student and parent
        flash[:alert]=''
        if reload_student_list
          # if first letter of last name changed, reload page (it is no longer in the current opened section)
          format.js { render js: "window.location.reload(true);" }
        else
          format.js
        end
      else
        # format.js { render js: "alert('Student not successfully updated!')" }
        # flash[:alert] = 'Errors, please fix.'
        format.html
        format.js
      end
    end
  end


  # New UI
  # Students reset passwords from student listing via JS
  def security
    @student = Student.find(params[:id])
    Rails.logger.debug("*** @student = #{@student.inspect.to_s}")
    @parent = @student.get_parent
    Rails.logger.debug("*** @parent = #{@parent.inspect.to_s}")
    respond_to do |format|
      format.js  # render security.js.coffee which renders _security.html.haml
    end
  end


  # New UI
  # listing of current and previous sections for a student
  def sections_list
    @student = Student.find(params[:id])
    if @student
      @current_enr = @student.enrollments.current
      @previous_enr = @student.enrollments.old
    else
      @current_enr = []
      @previous_enr = []
      flash[:alert] = "ERROR: user #{params[:id]} is not a student!"
    end
    respond_to do |format|
      format.html
    end
  end


  # new UI HTML get method
  # Bulk Upload Students (plus their parents)
  # see bulk_update for further processing of file uploaded.
  # stage 1 - gets the filename to upload and is posted to bulk_update
  def bulk_upload
    @errors = Hash.new
    @stage = 1
    @school = get_current_school
    respond_to do |format|
      flash.now[:alert] = 'No current school selected.' if @school.id.blank?
      format.html
    end
  end


  # new UI HTML post method
  # Bulk Update Students (plus their parents)
  # see bulk_upload which gets the file to upload.
  # stage 2 - reads csv file in and errors found within spreadsheet
  # stage 3 - reads csv file in and errors found against database
  # stage 4 - reads csv file and performs model validation of each record
  # stage 5 - updates records within a transaction - can upload again if errors
  # see app/helpers/students_helper.rb for helper functions
  def bulk_update
    @preview = true if params['preview']

    school = get_current_school

    # get all usernames in school to manually set usernames
    usernames = Hash.new
    User.where(school_id: school.id).each do |u|
      usernames[u.username] = u.id
    end

    @stage = 1
    Rails.logger.debug("*** StudentsController.bulk_update started")
    @errors = Hash.new
    @school = get_current_school
    Rails.logger.debug("*** @school: #{@school.inspect}")
    @errors[:base] = 'No current school selected.' if @school.id.blank?
    @records = Array.new

    if @errors.count > 0
      # don't process, error
    elsif params['file'].blank?
      # don't process, no input file to process
      @errors[:filename] = "Error: Missing Student Upload File."
    else

      @stage = 2
      Rails.logger.debug("*** Stage: #{@stage}")
      # no initial errors, process file
      @filename = params['file'].original_filename
      # note: 'headers: true' uses column header as the key for the name (and hash key)
      CSV.foreach(params['file'].path, headers: true) do |row|
        rhash = validate_csv_fields(row.to_hash)
        if rhash[COL_ERROR]
          @errors[:base] = 'Errors exist - see below:' if !rhash[COL_EMPTY]
        end
        @records << rhash if !rhash[COL_EMPTY]
      end  # end CSV.foreach

      # check for file duplicate Student emails and Student IDs (OK for duplicate parent emails)
      # loop through all records
      dup_email_checked = validate_dup_emails(@records)
      @error_list = dup_email_checked[:error_list]
      @records1 = dup_email_checked[:records]
      @errors[:base] = 'Errors exist - see below!!!:' if dup_email_checked[:abort] || @error_list.length > 0

      dup_xid_checked = validate_dup_xids(@records1)
      @error_list_2 = dup_xid_checked[:error_list]
      @records2 = dup_xid_checked[:records]
      @errors[:base] = 'Errors exist - see below!!!:' if dup_xid_checked[:abort] || @error_list_2.length > 0

      # stage 3
      @stage = 3
      Rails.logger.debug("*** Stage: #{@stage}")
      # create an array of emails to preload all from database
      emails = Array.new
      @records2.each do |rx|
        emails << rx[COL_EMAIL]
      end
      # get any matching emails in database
      matching_emails = User.where(school_id: @school.id, email: emails)
      if matching_emails.count > 0
        @records2.each_with_index do |rx, ix|
          # check all records following it for duplicated email
          if emails.include?(rx[COL_EMAIL])
            @records2[ix][COL_ERROR] = append_with_comma(@records2[ix][COL_ERROR], 'Email in use.')
            @errors[:base] = 'Errors exist - see below:'
          end
        end
      end # matching_emails.count > 0

      # stage 4
      @stage = 4
      Rails.logger.debug("*** @errors: #{@errors.inspect}")
      Rails.logger.debug("*** Stage: #{@stage}")

      @records2.each_with_index do |rx, ix|

        student = build_student(rx)
        # manually generate a valid username. We are in a transaction, and we must manually build a unique one)
        username = build_unique_username(student, school, usernames)
        student.username = username
        # put this username in the usernames hash if not there
        usernames[student.username] = username
        rx[COL_USERNAME] = username
        if rx[COL_PAR_EMAIL].present?
          rx[COL_PAR_USERNAME] = student.username + "_p"
          Rails.logger.debug("*** rx[COL_PAR_USERNAME]: #{rx[COL_PAR_USERNAME]}")
        end
        if student.errors.count > 0 || !student.valid?
          err = @records2[ix]["error"]
          @records2[ix][COL_ERROR] = append_with_comma(@records2[ix][COL_ERROR], student.errors.full_messages.join(', '))
          Rails.logger.debug("*** @records[ix][COL_ERROR]: #{@records2[ix][COL_ERROR]}")
          msg_str = "ERROR: #{student.errors.full_messages}"
          Rails.logger.error(msg_str)
          @errors[:base] = 'Errors exist - see below:'
        end

      end # @records2 loop
    end # end stage 1-4

    if @errors.count == 0 && @error_list.length == 0

      # stage 5
      @stage = 5
    end

    Rails.logger.debug("*** @error_list: #{@error_list.inspect}")
    Rails.logger.debug("*** @errors: #{@errors.inspect}")
    Rails.logger.debug("*** Final Stage: #{@stage}")

    @any_errors = @errors.count > 0 || @error_list.count > 0

    @rollback = false # indicate if rolled back for View

    # if stage 5 and not preview mode
    # - update records within a transaction
    # - rollback if errors
    respond_to do |format|
      if !@preview && @stage == 5
        begin
          ActiveRecord::Base.transaction do
            @records2.each_with_index do |rx, ix|
              student = build_student(rx)
              student.username = rx[COL_USERNAME] # use the username from stage 4
              student.save!
              UserMailer.welcome_user(student, @school, get_server_config).deliver # deliver after update attributes
              if rx[COL_PAR_EMAIL].present? && student.parent.present?
                rx[COL_PAR_USERNAME] = student.username + "_p"
                parent = build_parent(student, rx)
                parent.save!
                @records2[ix][COL_PAR_USERNAME] = student.username + "_p"
                UserMailer.welcome_user(parent, @school, get_server_config).deliver # deliver after update attributes
              end
              @records2[ix][COL_SUCCESS] = 'Created'
            end # @records2 loop
            # raise "Testing report output without update."
          end #transaction
          format.html {render action: 'bulk_update'}
        rescue Exception => e
          msg_str = "ERROR updating database: Exception - #{e.message}"
          @errors[:base] = msg_str
          @rollback = true
          Rails.logger.error(msg_str)
          flash.now[:alert] = 'Errors exist - see below:' if @errors[:base].present?
          format.html {render action: 'bulk_update'}
        end
      elsif @preview && @stage == 5
        # stage 5 preview, show the user the listing
        format.html {render action: 'bulk_update'}
      else
        # not stage 5, show user the errors
        flash.now[:alert] = 'Errors exist - see below:' if @errors[:base].present?
        format.html {render action: 'bulk_update'}
      end
    end
  end

  #####################################################################################
  protected

end
