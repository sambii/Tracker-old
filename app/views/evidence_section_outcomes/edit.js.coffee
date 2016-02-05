
# replace the body of the modal dialog box with the haml we want rendered
# $('#modal_content').html("<%= escape_javascript(render('evidence_section_outcomes/edit', formats: [:haml]) ) %>");
$('#modal-body').html("<%= escape_javascript(render('evidence_section_outcomes/edit', formats: [:haml]) ) %>");

###################################
# ADD EDIT EVIDENCE EVENT HANDLERS

showLosToAddToEvid = (that, ev) ->
  # click on + button to show LOs to add
  $('#evid-current-los').hide()
  $('#evid-other-los').show()

hideLosToAddToEvid = (that, ev) ->
  # click on return button to see Learning Outcomes list
  $('#evid-other-los').hide()
  $('#evid-current-los').show()

removeLoFromEvid = (that, ev) ->
  # move lo from learning outcomes list to available LOs
  $(that).parent().detach().appendTo('#evid-other-los ul')

addLoToEvid = (that, ev) ->
  # move LO from available LOs to Learning Outcomes List.
  $(that).parent().detach().appendTo('#evid-current-los ul')

showAttachToAdd = (that, event) ->
  $('#evid-add-attachments li').clone().appendTo('#evid-attachments-ul')

showHyperToAdd = (that, event) ->
  $('#evid-add-hyperlinks li').clone().appendTo('#evid-hyperlinks-ul')


###################################
# ADD EDIT EVIDENCE EVENT BINDINGS

$('#show-los-to-add').on 'click', (event, state) ->
  showLosToAddToEvid(this, event)
  return

$('#hide-los-to-add').on 'click', (event, state) ->
  hideLosToAddToEvid(this, event)
  return

$('.remove_lo_from_evid').on 'click', (event, state) ->
  removeLoFromEvid(this, event)
  return

$('.add_lo_to_evid').on 'click', (event, state) ->
  addLoToEvid(this, event)

$('#show-attach-to-add').on 'click', (event, state) ->
  showAttachToAdd(this, event)

$('#show-hyper-to-add').on 'click', (event, state) ->
  showHyperToAdd(this, event)




