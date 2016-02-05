# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ReportCardProcessor
	require 'tempfile'
	require 'prawn'

	def initialize(school_id,grade_level,email,full_name,url)
		@school = School.find(school_id)
		@grade = grade_level
		@email = email
		@full_name = full_name
		@url = url
	end

	def generate
		begin
		    acronym = @school.acronym.downcase
			outfile = Tempfile.new(["#{acronym}_reportcard", '.pdf'])
			build_report_cards @grade, outfile
			# everything is fine if we get here
			ReportCardMailer.report_success_email(@email,@grade,@full_name,outfile.path,@school).deliver
		rescue NoStudentsFoundException
			ReportCardMailer.no_students_email(@email,@grade,@full_name,@school).deliver
		rescue Exception => e
			# Log the execption
			Rails.logger.error("[#{Time.now}] [REPORT_CARDS] An unknown error occured when attempting to create report cards for:
				SCHOOL_NAME: #{@school.name} ; GRADE_LEVEL: #{@grade}, REQUESTED_BY: #{@email}")
			Rails.logger.error("[#{Time.now}] [REPORT_CARDS] EXCEPTION: #{e}")
			Rails.logger.error("[#{Time.now}] [REPORT_CARDS] #{e.backtrace}")

			ReportCardMailer.generic_exception_email(@email,@grade,@full_name,@school).deliver
		ensure
			outfile.close
			outfile.unlink
		end
	end
	handle_asynchronously :generate, priority: 2
	# higher number means lower priority than request_recieved_email

    def draw_header pdf, student, school_year_name
	    #pdf.image school_logo, at: [200, 740], width: 150
	    pdf.text "#{@school.name} Report Card", size: 20, align: :center, style: :bold
	    pdf.text "<color rgb='#4466bb'>#{student.last_name_first}</color>", align: :right, size: 14, inline_format: true
	    pdf.text "Student ID: #{student.xid.present? ? student.xid : '(unavailable)'}", align: :right, size: 10, style: :bold
	    pdf.text "School Year #{school_year_name}", align: :right, size: 10
	    pdf.horizontal_rule
	    pdf.move_down 6
	    pdf.stroke
    end

    def build_report_cards grade_level, pdf_output_file

	    s_o_r = @school.hash_of_section_outcome_ratings
	    e_r   = @school.hash_of_evidence_ratings

	    students = Student.where(grade_level: grade_level).includes(
	      enrollments:
	         {section:
	             {section_outcomes:
	                [:subject_outcome, {evidence_section_outcomes: :evidence}]
	              }
	         }
	    ).order([:grade_level, :last_name, :first_name]).where(school_id: @school.id)

	    raise NoStudentsFoundException if students.empty?

	    school_year_name = SchoolYear.find(@school.school_year_id).name
	    Prawn::Document.generate(pdf_output_file) do |pdf|
	      students.each do |student|
	      # Draw Summary Page
	        draw_header pdf, student, school_year_name
	        pdf.move_cursor_to 702
	        pdf.text "#{student.last_name_first}", size: 10
	        pdf.text "#{student.street_address}", size: 10
	        pdf.text "#{student.city}, #{student.state} #{student.zip_code}", size: 10
	        pdf.text "Phone: #{student.phone.present? ? student.phone : '(unavailable)'}", size: 10
	        # Summary Page Body
	        pdf.move_cursor_to 670
	        pdf.text "Summary Page", size: 13, align: :center, style: :bold
	        pdf.move_down 4
	        # Attendance commented out 11/26/2012 because it could be left blank for this report. Added students' parent
	        # account information instead.
	        # Attendance
	        # pdf.text "Attendance Information", size: 11, align: :center, style: :bold
	        # pdf.move_down 4
	        # pdf.text "Mastery Level: #{student.mastery_level.present? ? student.mastery_level : '(unavailable)'}", size: 10
	        # pdf.text "Attendance Rate: #{'%2.2f' % ((student.attendance_rate || 0) / 100) }%", size: 10
	        # pdf.text "Absences: #{student.absences.to_i}", size: 10
	        # pdf.text "Tardies: #{student.tardies.to_i}", size: 10
	        pdf.move_down 4
	        pdf.text "Parent Account Information", size: 9, align: :left, style: :bold
	        pdf.move_down 4
	        pdf.text "The account information below can be used to view your student's academic progress at <color rgb='#4466bb'>#{@url}</color>", size: 10, inline_format: true
	        pdf.text "<b>Username:</b> <i>#{student.parent.try(:username)}</i>", size: 10, inline_format: true
	        if student.parent.try(:temporary_password).present?
	          pdf.text "<b>Temporary Password:</b> <i>#{student.parent.temporary_password}</i>", size: 10, inline_format: true
	        else
	          pdf.text "Password already set by parent.", size: 10
	        end

	        # start evidence ratings summary by subject
	        pdf.move_down 6
	        pdf.text "Evidence Ratings Summary By Subject", size: 11, align: :center, style: :bold
	        data = []
	        student.sections.current.each do |section|
	          ratings = student.count_of_section_evidence_section_outcome_ratings section.id
	          data << [section.subject.name, section.teacher_names, ratings["B"], ratings["G"], ratings["Y"], ratings["R"], ratings["B"] + ratings["G"] + ratings["Y"] + ratings["R"], section.count_of_rated_evidence_section_outcomes]
	        end
	        if not data.empty?
	          pdf.table data, position: :center, font_size: 9, column_widths: { 0 => 180, 1 => 140, 2 => 27, 3 => 27, 4 => 27, 5 => 27, 6 => 60, 7 => 60 }, align: {2 => :center, 3 => :center, 4 => :center, 5 => :center, 6 => :center, 7 => :center}, headers: ["Subject", "Teacher Name(s)", "# B", "# G", "# Y", "# R", "# Ratings", "# Possible Ratings"]
	        else
	          pdf.text "<i>(Not Available)</i>", align: :center, inline_format: true
	        end
	        # end evidence ratings sumary by subject

	        # start LO ratings legend
	        pdf.move_down 14
	        pdf.text "Learning Outcome Ratings Legend", size: 12, align: :center, style: :bold
	        pdf.text "<i>Learning Outcomes appear in bold with the rating to the left. The related evidence appears underneath.</i>", size: 10, align: :center, inline_format: true
	        pdf.table [
	          ["H", "High Performance", "Student has demonstrated competence on a particular learning outcome that extends beyond proficient."],
	          ["P", "Proficient", "Student has demonstrated competence on a particular learning outcome."],
	          ["N", "Not Yet Proficient", "Student has demonstrated a limited understanding of this particular learning outcome."],
	          ["U", "Unrated", "There is not enough evidence to rate the student on this learning outcome at this time."]
	        ], column_widths: { 0 => 40, 1 => 110, 2 => 390}, font_size: 9, headers: ["Letter", "What it equals", "What does that mean?"]
	        pdf.move_down 8
	        pdf.horizontal_rule
	        pdf.stroke
	        pdf.move_down 2
	        pdf.text "<b>Sample Ratings</b>", align: :center, size: 9, inline_format: true
	        pdf.text "<i>*<u>    U    </u> 8. Follow and evaluate the logic and reasoning of the text, including assessing whether the evidence provided is sufficient to support the claims.</i>", size: 9, style: :bold, inline_format: true
	        pdf.indent(20) do
	          pdf.table [
	            ["Research Grouping", "Y"],
	            ["Identify Thesis-Supporting Detail", "G"]
	          ], border_width: 0, column_widths: { 0 => 225, 1 => 40, 2 => 225 }, font_size: 9
	        end
	        pdf.move_down 2
	        pdf.horizontal_rule
	        pdf.stroke
	        # end LO ratings legend

	        #start evidence ratings legend
	        pdf.move_down 14
	        pdf.text "Evidence Ratings Legend", size: 11, align: :center, style: :bold
	        pdf.text "<i>Evidence appears under the learning outcomes with the rating to the right.</i>", size: 10, align: :center, inline_format: true
	        pdf.table [
	          ["Blue (B)", "High Performing", "B", "Student has demonstrated competence on a particular piece of evidence that extends beyond proficient."],
	          ["Green (G)", "Proficient", "G", "Student has demonstrated competence on a particular piece of evidence."],
	          ["Yellow (Y)", "Developing", "Y", "Student has demonstrated a developed a basic understanding of concepts assessed in particular piece of evidence"],
	          ["Red (R)", "Basic", "R", "Student has demonstrated a limited understanding of concepts assessed in particular piece of evidence"]
	        ], column_widths: {0 => 85, 1 => 110, 2 => 45, 3 => 300}, position: :center, font_size: 9, headers: ["What you see", "What it equals", "Letter", "What does that mean?"]
	        # end evidence ratings legend

	      # Summary done

	        # Draw the students' detailed information on each subject.
	        pdf.start_new_page
	        draw_header pdf, student, school_year_name
	        student.sections.current.each do |section|
	          if pdf.cursor < 90
	            pdf.start_new_page
	          end
	          pdf.text "<b>#{section.subject.name}</b>", inline_format: true, size: 13, align: :center
	          pdf.text "<i>Taught by #{section.teacher_names}</i>", inline_format: true, size: 11, align: :center
	          pdf.move_down 4
	          section.section_outcomes.each do |section_outcome|
	            rating = s_o_r[student.id][section_outcome.id]
	            evidence_ratings = false
	            section_outcome.evidence_section_outcomes.each do |evidence|
	              evidence_ratings = true if e_r[student.id][evidence.id][:rating] != "U" and e_r[student.id][evidence.id][:rating] != ""
	            end
	            if rating != "U" or evidence_ratings == true
	              if pdf.cursor < 90
	                pdf.start_new_page
	              end
	              pdf.text "*<u>    #{rating}    </u> #{section_outcome.name}", size: 10, style: :bold, inline_format: true
	              data = []
	              section_outcome.evidence_section_outcomes.each do |evidence|
	                data << [evidence.name, "#{e_r[student.id][evidence.id][:rating]}", "#{e_r[student.id][evidence.id][:comment]}"]
	              end
	              if data.length > 0
	                pdf.indent(20) do
	                  pdf.table data, border_width: 0, column_widths: { 0 => 225, 1 => 40, 2 => 225 }, font_size: 10
	                end
	              end
	              pdf.move_down 8
	            end
	          end
	        end
	        pdf.start_new_page
	      end
	    end
	end

end

class NoStudentsFoundException < StandardError
end
