
errors_count = <%= @user.errors.count %>
console.log "errors_count= #{errors_count}"
if errors_count.toString() != '0'
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # redisplay form with errors
  # $('#modal_content').html("<%= escape_javascript(render('users/edit') ) %>");
  $('#modal-body').html("<%= escape_javascript(render('system_administrators/edit_system_user') ) %>");
else
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # close out dialog if it exists
  console.log 'closing out dialog box'
  $('#modal_popup').modal('hide')

  # if user deactivated, update listing
  staff_tr = $("#user_<%= @user.id %>")
  console.log "found user_<%= @user.id %> length = #{staff_tr.length}"

  # update all fields for user in listing
  staff_tr.find('.user-last-name').text("<%= @user.last_name %>")
  staff_tr.find('.user-first-name').text("<%= @user.first_name %>")
  staff_tr.find('.user-roles').text("<%= @user.role_symbols.join(' ') %>")
  staff_tr.find('.user-email').text("<%= @user.email %>")

