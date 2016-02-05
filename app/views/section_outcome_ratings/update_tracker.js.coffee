# display any errors if any
$('#breadcrumb-flash-msgs').html("<span class='flash_error'><%= @section_outcome_rating.errors.full_messages %><span>")
# clear out popup (we clear after every create or update - they can always click again)
$('#popup-rate-single-lo').hide()

sor_id = "<%= @section_outcome_rating.id %>"
console.log 'sor_id: '+sor_id
if sor_id > 0
  # sor created, update display
  student_id = "<%= @section_outcome_rating.student_id %>"
  so_id = "<%= @section_outcome_rating.section_outcome_id %>"
  new_rating = "<%= @section_outcome_rating.rating %>"
  cell_section = $(".tbody-header[data-so-id='#{so_id}']")
  original_cell = cell_section.find("[data-student-id='#{student_id}'][data-so-id='#{so_id}']")
  original_cell.data('id', sor_id)
    .data('rating', new_rating)
    .attr('id', "s_o_r_#{sor_id}")
  window.trackerCommonCode.updateLoCellRating(original_cell, new_rating)
else
  # error, sor not created
