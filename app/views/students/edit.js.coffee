
# replace the body of the modal dialog box with the haml we want rendered
# $('#modal_content').html("<%= escape_javascript(render('students/edit') ) %>");
$('#modal-body').html("<%= escape_javascript(render('students/edit') ) %>");
