
errors_count = <%= @user.errors.count %>
console.log "errors_count= #{errors_count}"
if errors_count.toString() != '0'
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # redisplay form with errors
  # $('#modal_content').html("<%= escape_javascript(render('users/edit') ) %>");
  $('#modal-body').html("<%= escape_javascript(render('users/edit') ) %>");
else
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # close out dialog if it exists
  console.log 'closing out dialog box'
  $('#modal_popup').modal('hide')

  # if successful, refresh listing
  # todo add spinner here
  window.location.href = "<% staff_listing_users_path %>"