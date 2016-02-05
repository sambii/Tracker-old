
# replace the body of the modal dialog box with the haml we want rendered
$('#modal-body').html("<%= escape_javascript(render('evidences/show_attachments', formats: [:haml]) ) %>");

#----------------------------------
# EVENT HANDLERS


#----------------------------------
# EVENT BINDINGS




