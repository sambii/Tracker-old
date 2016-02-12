# breadcrumbs.rb
# breadcrumb configuration file using gretel gem.
# see https://github.com/lassebunk/gretel for docs and samples

crumb :root do
  link "Home", root_path
  # if current_user.present? && (current_user.system_administrator? || current_user.researcher?)
  #   link 'schools', schools_path
  #   if session[:school_context].to_i > 0
  #     link "school", school_path(session[:school_context].to_i)
  #   end
  # end
end

crumb :current do
  link "Current"
  parent :root
end

crumb :subject do |subject|
  link subject.name.truncate(15, omission: '...'), subject #
end

crumb :section do |section|
  if can?(:update_subject_outcomes, section.subject)
  	link section.line_number, section
    parent :subject, section.subject
  else
    link "#{section.subject.name.truncate(15, omission: '...')} - #{section.line_number}", section
    parent :root
  end
end

crumb :section_outcome do |sect_o|
  link sect_o.subject_outcome.name.truncate(15, omission: '...'), sect_o
  parent :section, sect_o.section
end

crumb :rate_evidence do  |section, evidence|
  link evidence.name.truncate(15, omission: '...'), evidence
  parent :section, section
end

crumb :add_learning_outcome do |section|
  link 'Add LO', section
  parent :section, section
end

crumb :new_evidence do |section|
  link 'Add Evidence', section
  parent :section, section
end

crumb :edit_evidence do |section|
  link 'Edit Evidence', section
  parent :section, section
end

crumb :restore_evidence do |section|
  link 'Restore Evid.', section
  parent :section, section
end

crumb :section_attendance do |section|
  link 'Section Attend.', section
  parent :section, section
end

crumb :generate_reports do
  link 'Reports', new_generate_path
end

crumb :section_generate_reports do |section|
  link 'Reports', new_generate_path
  parent :section, section
end

crumb :rpt_sect_sum_outcome do |section|
  link 'Sect. Sum. LO', section_summary_outcome_section_path
  parent :generate_reports, section
end

crumb :rpt_sect_sum_student do |section|
  link 'Sect. Sum. Student', section_summary_student_section_path
  parent :generate_reports, section
end

crumb :rpt_nyp_student do |section|
  link 'NYP Student', nyp_student_section_path
  parent :generate_reports, section
end

crumb :rpt_nyp_lo do |section|
  link 'NYP LO', nyp_outcome_section_path
  parent :generate_reports, section
end

crumb :rpt_progress_gen do |section|
  link 'Prog. Rpt. Gen.', progress_rpt_gen_section_path
  parent :generate_reports, section
end

crumb :rpt_attend do
  link 'Att. by Date', attendance_report_attendances_path
  parent :generate_reports
end

crumb :prof_bar_chart do
  link 'Student Prof.', students_report_path
  parent :generate_reports
end

crumb :prof_bar_chart_subject do
  link 'Subject Prof.', proficiency_bars_subjects_path
  parent :generate_reports
end

crumb :progress_meters do
  link 'Subject Progress', progress_meters_subjects_path
  parent :generate_reports
end

crumb :acct_activity do
  link 'Acct. Activity', account_activity_report_users_path
  parent :generate_reports
end

crumb :staff_listing do
  link 'Staff Listing', staff_listing_users_path
  parent :root
end

crumb :staff_section_listing do
  link 'Staff Sections Listing', sections_list_user_path
  parent :staff_listing
end

crumb :student_listing do
  link 'Student Listing', students_path
  parent :root
end

crumb :student_section_listing do
  link 'Student Sections Listing', sections_list_student_path
  parent :student_listing
end

crumb :attend_maint do
  link 'Attend. Maint.', attendance_maintenance_attendances_path
  parent :root
end

crumb :new_section do
  link 'New Section', new_section_path
  parent :root
end


crumb :student_dashboard do |student|
  if current_user.see_school?
    if student
      link student.full_name.truncate(15, omission: '...'), student_path(student)
    end
    parent :root
  end
end
crumb :student_tracker do |enrollment|
  link enrollment.section.subject.name.truncate(15, omission: '...'), enrollment_path(enrollment)
  if current_user.see_school?
    parent :student_dashboard, enrollment.student
  end
end


crumb :teacher_dashboard do |teacher|
  if current_user.see_all_school?
    if teacher
      link "#{teacher.full_name.truncate(15, omission: '...')}", teacher_path(teacher)
    end
    # if current_user.see_all?
    #   parent :school_admin_dashboard
    # end
      parent :root
    # end
  end
end
crumb :section_dashboard do |section|
  if can?(:update_subject_outcomes, section.subject)
    link section.subject.name.truncate(15, omission: '...'), section.subject
  end
  link section.line_number.truncate(15, omission: '...'), class_dashboard_section_path(section)
  if current_user.see_all_school?
    parent :teacher_dashboard, section.teachers.first
  end
end


crumb :school_admin_dashboard do |school_admin|
  if current_user.see_all?
    link "#{school_admin.full_name.truncate(15, omission: '...')}", school_administrator_path(school_admin)
    parent :root
  end
end


crumb :system_admin_dashboard do |system_admin|
  link "#{system_admin.full_name.truncate(15, omission: '...')}", system_administrator_path(system_admin)
  # parent :root
end

crumb :subjects_sections_listing do
  link "Subjects"
  parent :root
end


crumb :school_listing do
  link "Schools"
  parent :root
end

crumb :section_bulk_entry do
  link "Section Entry"
  parent :subjects_sections_listing
end

crumb :section_bulk_updated do
  link 'Sections Bulk'
  parent :subjects_sections_listing
end

crumb :staff_bulk_entry do
  link 'Staff Bulk Upload'
  parent :staff_listing
end


crumb :student_bulk_entry do
  link 'Student Bulk Upload'
  parent :student_listing
end

crumb :teaching_assignment_bulk_entry do
  link 'Teacher Assignment Bulk Entry'
  parent :subjects_sections_listing
end

crumb :upload_templates do
  link 'Upload Templates'
  parent :root
end

crumb :school_dashboard do
  link 'School'
  parent :root
end
