# update tracker page after creating single evidence rating

# # display any errors if any
# errors = <%= @evidence_section_outcome_rating.errors %>
# if errors && errors.count > 0
#   $('#breadcrumb-flash-msgs').html("<span class='flash_error'><%= @evidence_section_outcome_rating.errors.full_messages %><span>")

# clear out popup (we clear after every update - they can always click again)
$('#popup-rate-single-evid').hide()

esor_id = "<%= @evidence_section_outcome_rating.id %>"
student_id = "<%= @evidence_section_outcome_rating.student_id %>"
so_id = "<%= @evidence_section_outcome_rating.evidence_section_outcome.section_outcome_id %>"
eso_id = "<%= @evidence_section_outcome_rating.evidence_section_outcome_id %>"
new_rating = "<%= @evidence_section_outcome_rating.rating %>"
new_comment = "<%= @evidence_section_outcome_rating.comment %>"
cell_section = $(".tbody-section[data-so-id='#{so_id}']")
console.log "cell_section.length = #{cell_section.length}"
original_cell = cell_section.find("tr[data-eso-id='#{eso_id}'] a.esor[data-student-id='#{student_id}']")
console.log "original_cell.length = #{original_cell.length}"
console.log "original_cell.attr('id') = #{original_cell.attr('id')}"
original_cell.data('id', esor_id)
  .data('rating', new_rating)
  .attr('id', "e_s_o_r_#{esor_id}")
console.log "original_cell.attr('id') = #{original_cell.attr('id')}"
window.trackerCommonCode.updateEvidenceCellRating(original_cell, new_rating)
$(original_cell).data('comment',new_comment)
if new_comment
  $(original_cell).addClass('commented')
else
  $(original_cell).removeClass('commented')
