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
