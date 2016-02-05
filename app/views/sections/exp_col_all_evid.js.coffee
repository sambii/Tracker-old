
error_count = <%= @error_count %>
console.log "error_count= #{error_count}"
p_minimized = <%= params[:minimized] %>
console.log "p_minimized= #{p_minimized}"

if error_count.toString() != '0'
  # display flash messages if any
  console.log 'got errors'
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
else
  # display flash messages if any
  console.log 'no errors'
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  if p_minimized == 'true' || p_minimized == true
    # update class on LO to hide evidences below it
    console.log 'hiding evidences'
    $('.tbody-header').removeClass('tbody-open')
  else if p_minimized == 'false' || p_minimized == false
    # update class on LO to show evidences below it
    console.log 'showing evidences'
    $('.tbody-header').addClass('tbody-open')

