
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
  # # todo remove refresh, update name and teachers in current line in subject listing
  console.log 'get section_id'
  section_id = <%= @section.id %>
  subject_id = <%= @section.subject_id %>
  subjects_path = '/subjects?show_subject_id='+subject_id
  console.log 'log section_id'
  console.log "#{section_id}"
  console.log "#{subject_id}"
  console.log "#{subjects_path}"
  window.location.href = "<% subjects_path(show_subject_id: @section.subject_id) %>"

