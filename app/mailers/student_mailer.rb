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
    @marking_periods          = Range::new(1,@section.school.marking_periods)
    mail(from: get_support_email, to: address, subject: "PARLO Progress Tracker: #{@section.name}")
  end

  def new_evidence_notify(section, enrollment, req)
    @student = enrollment.student
    @section = section
    @server_config = get_server_config
    @tracker_url = get_server_url(@server_config, req)
    if @section.teachers.count > 0 && @section.teachers.first.email.present?
      @email_from = @section.teachers.first.email
      @email_from_name = @section.teachers.first.full_name
    else
      @email_from = get_server_support_email(@server_config)
      @email_from_name = get_server_support_team(@server_config)
    end

    Rails.logger.debug("+++ new_evidence_notify send new evidence email to student: #{@student.full_name}")


    mail(from: @email_from, to: @student.email, subject: "New evidence for #{@section.name} - #{@section.line_number}") if @student.email.present?
  end


  private

  # to do - move these to a shared module
  def get_server_config
    scr = ServerConfig.first
    if scr
      return scr
    else
      raise "Error: Missing Server Config Record"
    end
  end

  def get_server_url(scr=nil, req)
    scr = get_server_config if !scr.present?
    return scr.server_url.present? ? scr.server_url : req.base_url
  end

  def get_server_support_email(scr=nil)
    scr = get_server_config if !scr.present?
    return scr.support_email.present? ? scr.support_email : ""
  end

  def get_server_support_team(scr=nil)
    scr = get_server_config if !scr.present?
    return scr.support_team.present? ? scr.support_team : ""
  end


  def get_support_email
    scr = ServerConfig.first
    if scr
      return scr.support_email
    else
      raise "Error: Missing Server Config Record"
    end
  end

end
