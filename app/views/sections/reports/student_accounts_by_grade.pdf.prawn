z = 0
last_grade = -1
@students.each_with_index do |student|
  last_grade = student.grade_level if last_grade == -1 # set so only breaks after a grade has already listed
  if student.grade_level != last_grade
    pdf.move_down 10
    pdf.text "End of Grade Level: #{last_grade.to_s}", size: 20
  end
  if pdf.y < 250 || student.grade_level != last_grade
    pdf.start_new_page
  end
  if student.temporary_password.present? or student.parents.map { |a| a.temporary_password.present? }.index(true).present?
    pdf.text student.last_name_first, size: 20
    pdf.text "Student Username: #{student.username}"
    pdf.text "Temporary Password: " + student.temporary_password.to_s
    pdf.move_down 10
    student.parents.each do |parent|
      pdf.text "Parent Username: #{parent.username}"
      pdf.text "Temporary Password: #{parent.temporary_password}"
      pdf.move_down 10
    end
    pdf.text "You can use the credentials above to log into your Progress Tracker at: #{request.protocol+request.host_with_port}"
    pdf.move_down 10
    pdf.text "- " * 74
    z += 1
  end
  last_grade = student.grade_level
end
if last_grade != -1
  pdf.move_down 10
  pdf.text "End of Grade Level: #{last_grade.to_s}", size: 20
end
