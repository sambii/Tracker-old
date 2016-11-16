# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class StudentMailer < ActionMailer::Base
  # removed because test database is empty when this is called
  # default :from => ServerConfig.first.support_email

  def show(address, student_id, section_id)
    @student                  = Student.find(student_id)
    @section                  = Section.find(section_id)
    @evidence_ratings         = @student.section_evidence_ratings(section_id)
    @section_outcome_ratings  = @student.section_section_outcome_ratings(section_id)
    @marking_periods 		  = Range::new(1,@section.school.marking_periods)
    mail(from: get_support_email, to: address, subject: "PARLO Progress Tracker: #{@section.name}")
  end

  def new_evidence_notify(enrollment_id, student, section, subject_line, tracker_url)
    @enrollment_id = enrollment_id
    @student = student
    @section = section
    @tracker_url = tracker_url
    if @section.teachers.count > 0 && @section.teachers.first.email.present?
      @email_from = @section.teachers.first.email
      @email_from_name = @section.teachers.first.full_name
    else
      @email_from = get_support_email
      @email_from_name = @server_config.support_team
    end

    mail(from: @email_from, to: @student.email, subject: subject_line) if @student.email.present?
  end


  private

  def get_support_email
    scr = ServerConfig.first
    if scr
      return scr.support_email
    else
      raise "Error: Missing Server Config Record"
    end
  end

end
