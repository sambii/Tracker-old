
console.log 'toggle_marking_period.js.coffee'
errors_count = <%= @section_outcome.errors.count %>
console.log "errors_count= #{errors_count}"
is_active = <%= @is_active %>
console.log "is_active= #{is_active}"
this_mpi = <%= @this_mpi %>
console.log "this_mpi= #{this_mpi}"
section_outcome_id = <%= @section_outcome.id %>
console.log "section_outcome_id= #{section_outcome_id}"
find_elements = "tbody.tbody-header[data-so-id='#{section_outcome_id}'] .mp#{this_mpi}"
console.log "header_elements = #{find_elements}"

if errors_count.toString() != '0'
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
else
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")

  mp_li = $("tbody.tbody-header[data-so-id='#{section_outcome_id}'] .mp#{this_mpi}")
  console.log "mp_li.length = #{mp_li.length}"
  if is_active
    mp_li.addClass('active')
  else
    mp_li.removeClass('active')
