
errors_count = <%= @student.errors.count %>
console.log "errors_count= #{errors_count}"
if errors_count.toString() != '0'
  # display flash messages if any
  $('#modal-message').html("<%= escape_javascript(render('layouts/messages')) %>")
# replace the body of the modal dialog box with the haml we want rendered
$("#user_" + <%= @student.id %>).html("<%= escape_javascript(render(partial: 'students/temporary_password', locals: {user: @student}) ) %>");
