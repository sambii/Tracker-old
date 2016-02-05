
errors_count = <%= @section.errors.count %>
console.log "section create errors_count= #{errors_count}"
if errors_count.toString() != '0'
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # redisplay form with errors
  $('#modal-body').html("<%= escape_javascript(render('sections/update') ) %>");
  $('#modal_popup .modal-dialog').addClass('wide-modal')
else
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # close out dialog if it exists
  console.log 'closing out dialog box'
  $('#modal_popup').modal('hide')

  # # if successful, refresh listing
  # # todo add spinner here
  window.location.href = "<% sections_path %>"

