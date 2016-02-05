
errors_count = <%= @section_outcome.errors.count %>
console.log "errors_count= #{errors_count}"
pso_active = <%= params[:section_outcome][:active] if params[:section_outcome] %>
console.log "pso_active= #{pso_active}"
pso_minimized = <%= params[:section_outcome][:minimized] if params[:section_outcome] %>
console.log "pso_minimized= #{pso_minimized}"
p_id = <%= params[:id] %>
console.log "p_id= #{p_id}"
p_mp = <%= params[:mp] if params[:mp] %>

if errors_count.toString() != '0'
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
else
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  if typeof pso_active != 'undefined'
    # update class on LO to hide it
    console.log 'hiding LO - '
    $("tbody.tbody-header[data-so-id='#{p_id}']").removeClass('showLO')
  if typeof pso_minimized != 'undefined'
    if pso_minimized
      # update class on LO to hide evidences below it
      console.log 'hiding evidences - '
      $("tbody.tbody-header[data-so-id='#{p_id}']").removeClass('tbody-open')
    else
      # update class on LO to show evidences below it
      console.log 'showing evidences - '
      $("tbody.tbody-header[data-so-id='#{p_id}']").addClass('tbody-open')
  if typeof p_mp != 'undefined'
    # update marking periods on LO ???????
    console.log 'showing evidences'
    $("tbody.tbody-header[data-so-id='#{p_id}']").addClass('tbody-open')

