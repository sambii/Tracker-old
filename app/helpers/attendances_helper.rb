# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
module AttendancesHelper

  # create an array of attendance records for the enrollments in a section for a specific date to present to the user
  def load_section_attendance_fields(section_id, date)
    if section_id
      # First get the attendances for the section and date
      section_attendances = Attendance.where(section_id: section_id, attendance_date: date).order(:attendance_date)
      a_by_student = Hash.new   # hash of found attendance records by student/user id for matching
      a_by_name = Array.new   # array of enrollment attendances (existing or blank)
      # put existing section attendance records into hash for lookup by student id
      section_attendances.each do |a|
        a_by_student[a.user_id]= a
      end
      # loop through enrollments, to ensure that there is an attendance record for every student in the class (use existing attendance records, or an empty one)
      @enrollments.each do |e|
        if a_by_student[e.student_id]
          # use existing student attendance record
          att_rec = a_by_student[e.student_id]
        else
          # use a new student attendance record to be displayed to the user to fill in
          att_rec = Attendance.new(attendance_date: date)
          att_rec.school_id = @school.id
          att_rec.section_id = e.section_id
          att_rec.user_id = e.student_id
        end
        # add attendance record with name fields in order
        if @school.has_flag?(School::USER_BY_FIRST_LAST)
          a_by_name << [
            e.student.first_name,
            e.student.last_name,
            att_rec
          ]
        else
          a_by_name << [
            e.student.last_name,
            e.student.first_name,
            att_rec
          ]
        end
      end
      # sort by last_name and first_name
      a_by_name.sort! { |x, y| x[0]+x[1] <=> y[0]+y[1] }
      # build the attendances instance variable with all attendances in the sort order
      @attendances = []
      a_by_name.each do |na|
        @attendances << na[2] # load the sorted attendance record
      end
    end
    # todo - add index on enrollments table for student and section
  end

  # load instance variables needed for section attendance (other than @attendances - see load_section_attendance_fields)
  def load_non_attendance_section_attendance_fields(section_id)
    @school = get_current_school
    if section_id
      @section = Section.find(section_id)
      @subject = @section.subject
      if @school.id != @subject.school.id
        flash.now[:alert] = "School mismatch"
      end
      @enrollments = Enrollment.includes(:student).where(section_id: @section.id).alphabetical
    else
      flash.now[:alert] = "Error: Missing section_id."
    end
    @attendance_types = AttendanceType.where(school_id: @school.id)
    @excuses = Excuse.where(school_id: @school.id)
    # todo - add index on enrollments table for student and section
  end

  # process one attendance record set of params
  # - return the updated/created record and any active record errors.
  # - or an unsaved blank record if there is no attendance record in the database.
  # - will not create any blank records in the database (and return a unsaved blank one).
  # - will return an unsaved blank one to replace record after deleting.
  # todo - allow deleting records if all ui fields are cleared out, but only for current date.
  # todo - if deleting for older days, record is cleared, but must have a comment provided by the user.
  # todo - see if there is a refactor on the @attendances array build in load_section_attendance_fields.
  # - attendance_params:: the params for one attendance record.
  def process_attendance_update(attendance_params, school_id, section_id)
    Rails.logger.debug("******* attendance_params: #{attendance_params.inspect.to_s}")
    a_id = attendance_params['id']
    a_rec = new_section_attendance_record(attendance_params, school_id, section_id)
    if a_id.blank? # record did not exist before.
      # Create if there is data to insert. Do not create empty records.
      if !attendance_params['attendance_type_id'].blank? || !attendance_params['excuse_id'].blank? || !attendance_params['comment'].blank?
        # new record, add it if there is a comment, excuse or attendance type
        a_rec.attendance_type_id = attendance_params['attendance_type_id']
        a_rec.excuse_id = attendance_params['excuse_id']
        a_rec.comment = attendance_params['comment']
        a_rec.save
        if a_rec.errors.count > 0
          Rails.logger.error("ERROR - "+ I18n.translate('alerts.had_errors') + a_rec.errors.full_messages.first)
          flash.now[:alert] = I18n.translate('alerts.errors_see_below')
        end
      end # end have entered fields
    else # record already exists
      # update it. Let model / active record decide if it is dirty or not, and set any errors.
      a_rec = Attendance.find(a_id)
      if a_rec
        # only update the fields entered by the user.
        cleared_params = attendance_params.clone
        cleared_params.keep_if {|k,_| ['attendance_type_id', 'excuse_id', 'comment'].include? k}
        if cleared_params['attendance_type_id'].blank? && cleared_params['excuse_id'].blank? && cleared_params['comment'].blank?
          # todo - # existing record is being cleared - delete it, but only if for current date
          # if Date.today == a_rec.attendance_date.to_date
          a_rec.delete
          if a_rec.errors.count > 0
            Rails.logger.error("ERROR - "+ I18n.translate('alerts.had_errors') + a_rec.errors.full_messages.first)
            flash.now[:alert] = I18n.translate('alerts.errors_see_below')
          else
            a_rec = new_section_attendance_record(attendance_params, school_id, section_id)
          end
          # else
          #   a_rec.errors.add :base, I18n.translate('errors.cannot_delete_prior_attendance_record')
          #   flash[:alert] = I18n.translate('alerts.had_errors')
          # end
          # a_rec.errors.add :base, I18n.translate('errors.cannot_delete_attendance_record')
        else
          Rails.logger.debug("update attributes - #{cleared_params}")
          a_rec.update_attributes(cleared_params)
          if a_rec.errors.count > 0
            Rails.logger.error("ERROR - "+ I18n.translate('alerts.had_errors') + a_rec.errors.full_messages.first)
            flash.now[:alert] = I18n.translate('alerts.errors_see_below')
          end
        end
      else
        Rails.logger.error("ERROR - unable to find attendance record for #{key}")
        flash.now[:alert] = I18n.translate('alerts.errors_see_below')
      end
    end # end if blank id
    return a_rec
  end

  # populate a blank/fresh Attendance record with initial foreign key values already set.
  def new_section_attendance_record(attendance_params, school_id, section_id)
    a_rec_blank = Attendance.new()
    a_rec_blank.school_id = school_id
    a_rec_blank.section_id = section_id
    a_rec_blank.user_id = attendance_params['user_id']
    a_rec_blank.attendance_date = attendance_params['attendance_date']
    return a_rec_blank
  end

end
