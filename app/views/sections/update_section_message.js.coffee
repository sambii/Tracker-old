
errors_count = <%= @section.errors.count %>
console.log "errors_count= #{errors_count}"
if errors_count.toString() != '0'
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # redisplay form with errors
  # $('#modal_content').html("<%= escape_javascript(render('sections/edit_section_message') ) %>");
  $('#modal-body').html("<%= escape_javascript(render('sections/edit_section_message') ) %>");
else
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # close out dialog if it exists
  console.log 'closing out dialog box'
  $('#modal_popup').modal('hide')

  # only section message is updated through js (so far)
  message = "<%= @section.message %>"
  message_loc = $('#tracker-comments-students a span')
  message_loc.text(message)

