# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class StudentMailer < ActionMailer::Base
  default :from => "trackersupport@21pstem.org"

  def show(address, student_id, section_id)
    @student                  = Student.find(student_id)
    @section                  = Section.find(section_id)
    @evidence_ratings         = @student.section_evidence_ratings(section_id)
    @section_outcome_ratings  = @student.section_section_outcome_ratings(section_id)
    @marking_periods 		  = Range::new(1,@section.school.marking_periods)
    mail(to: address, subject: "PARLO Progress Tracker: #{@section.name}")
  end
end
