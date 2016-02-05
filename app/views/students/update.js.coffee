
errors_count = <%= @student.errors.count %>
console.log "errors_count= #{errors_count}"
if errors_count.toString() != '0'
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # redisplay form with errors
  # $('#modal_content').html("<%= escape_javascript(render('students/edit') ) %>");
  $('#modal-body').html("<%= escape_javascript(render('students/edit') ) %>");
else
  # display flash messages if any
  $('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
  # close out dialog if it exists
  console.log 'closing out dialog box'
  $('#modal_popup').modal('hide')

  # if student deactivated, update listing
  status = "<%= @student.active %>"
  student_tr = $("#student_<%= @student.id %>")
  if "#{status}" == 'true'
    student_tr.removeClass('deactivated')
    student_tr.addClass('active')
  else
    student_tr.addClass('deactivated')
    student_tr.removeClass('active')

  # update all fields for student in listing
  student_tr.find('.user-xid').text("<%= @student.xid %>")
  student_tr.find('.user-last-name').text("<%= @student.last_name %>")
  student_tr.find('.user-first-name').text("<%= @student.first_name %>")
  student_tr.find('.user-email').text("<%= @student.email %>")
  student_tr.find('.user-grade-level').text("<%= @student.grade_level %>")
  student_tr.find('.user-street-address').text("<%= @student.street_address %>")
  student_tr.find('.user-city').text("<%= @student.city %>")
  student_tr.find('.user-state').text("<%= @student.state %>")
  student_tr.find('.user-zip-code').text("<%= @student.zip_code %>")
  student_tr.find('.user-race').text("<%= @student.race %>")
  student_tr.find('.user-special-ed').text("<%= @student.special_ed %>")
  student_tr.find('.user-parent-email').text("<%= @student.parent.email %>")
  student_tr.find('.user-parent-sub-status').text("<%= @student.parent.subscription_status %>")

