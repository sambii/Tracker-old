
# replace the body of the modal dialog box with the haml we want rendered
$('#modal-body').html("<%= escape_javascript(render('sections/update') ) %>");
$('#modal_popup .modal-dialog').addClass('wide-modal')
###################################
# bind events for new content
