# Locate the student ID by determining the column that the rating is in and pulling that column
# from the roster row.
window.locateStudent = (target) ->
  student_index = $(target).parent("tr").children("td, th").index($(target))
  student_array = $("table#roster tbody tr").children("th")
  student_div   = $(student_array[student_index]).children("div")[0]
  $(student_div).attr('id').replace("student_", "")

# Locate the section outcome / evidence section outcome that the rating is associated with by
# extracting the ID of the parent row / table.
window.locateRatingTarget = (target) ->
  parent_id = $($(target).parents("tr.evidence, table.section_outcome")[0]).attr("id")
  parent_id = parent_id.replace("evidence_right_row_", "")
  parent_id = parent_id.replace("section_outcome_table_right_", "")
  parent_id