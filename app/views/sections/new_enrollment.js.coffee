
# replace the body of the modal dialog box with the haml we want rendered
# $('#modal_content').html("<%= escape_javascript(render('sections/new_enrollment') ) %>");
$('#modal-body').html("<%= escape_javascript(render('sections/new_enrollment') ) %>");
###################################
# bind events for new content

# show create student form
$('#modal_content a').on 'click', (event, state) ->
  console.log 'showNewStudentForm'
  $('#new-student').show()
  $('#enroll_student').hide()


  event.preventDefault()

