
errors_count = <%= @evidence_type.errors.count %>
console.log "announcement create errors_count= #{errors_count}"
if errors_count.toString() != '0'
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # redisplay form with errors
  $('#modal-body').html("<%= escape_javascript(render('evidence_types/form') ) %>");
else
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # close out dialog if it exists
  console.log 'closing out dialog box'
  $('#modal_popup').modal('hide')

  # # if successful, refresh listing
  # # todo add spinner here
  window.location.href = "<% evidence_types_path %>"

