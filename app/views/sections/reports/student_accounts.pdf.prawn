z = 0
@students.each_with_index do |student|
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
    pdf.start_new_page if z % 4 == 0 and z != 0
  end
end