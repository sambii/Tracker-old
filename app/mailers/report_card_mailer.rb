# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ReportCardMailer < ActionMailer::Base
  default :from => ServerConfig.first.support_email

	def report_success_email(address,grade,full_name,file_attachment,school)
		@grade = grade
		@full_name = full_name
		report_card_content = File.read file_attachment
		@school = school

		#attachments must be called before calling mail
		attachments["#{@school.acronym}_report_card_grade_#{@grade}.pdf"] = {
			mime_type: 'application/pdf',
			content: 	report_card_content
		}
		mail(to: address, subject: "Completed: Grade #{@grade} Report Card Request")
	end

	def no_students_email(address,grade,full_name,school)
		@grade = grade
		@full_name = full_name
		@school = school

		mail(to: address, subject: "No Students Found: Grade #{@grade} Report Card Request")
	end

	def generic_exception_email(address,grade,full_name,school)
		@grade = grade
		@full_name = full_name
		@email = address
		@school = school

		mail(to: @email, subject: "Error: Grade #{@grade} Report Card Request")
	end

	def request_recieved_email(address,grade,full_name,school)
		@grade = grade
		@full_name = full_name
		@school = school

		mail(to: address, subject: "Recieved: Grade #{@grade} Report Card Request")
	end

end
