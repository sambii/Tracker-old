
errors_count = <%= @excuse.errors.count %>
console.log "errors_count= #{errors_count}"

# display flash messages if any
$('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")

if errors_count.toString() != '0'
  # # redisplay form with errors
  # $('#modal_content').html("<%= escape_javascript(render('excuses/new') ) %>");
  $('#modal-body').html("<%= escape_javascript(render('excuses/new') ) %>");
else

  # if successful, refresh listing
  # todo add spinner here
  window.location.href = "<% attendance_maintenance_attendances_path %>"
  window.location.reload(true)
