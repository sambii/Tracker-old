#
# * Custom JS Code for Add Evidence or Edit Evidence Page
$ ->
  if $('#page-content.add-edit-evidence').length == 0
    return
  else
    # we are on the tracker page, do the following

    #----------------------------------------------------------------------
    # Setup - Variables
    #----------------------------------------------------------------------

    err_element = $('#breadcrumb-flash-msgs')

    #----------------------------------------------------------------------
    # Setup - Calculated Variables
    #----------------------------------------------------------------------


    #----------------------------------------------------------------------
    # UTILITY FUNCTIONS (ERROR HANDLING, ...)
    #----------------------------------------------------------------------

    # Display an error
    displayError = (err_msg) ->
      err_element.html("<span class='flash_error'>#{err_msg}</span>")

    # Clear the errors
    clearErrors = () ->
      err_element.html("<span></span>")

    #----------------------------------------------------------------------
    # ADD EDIT EVIDENCE EVENT HANDLERS
    #----------------------------------------------------------------------

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
      destroy = true
      console.log 'removeLoFromEvid'
      rate_count = $(that).data('rate-count')
      console.log "rate-count = #{rate_count}"
      if rate_count > 0
        destroy = confirm 'Are you sure (this will PERMANENTLY DELETE RATINGS)?'
      if destroy
        evid_lo = $(that).parent().detach()
        so_id_elem = $(evid_lo).find('.so_ids')
        console.log 'value is : '+so_id_elem.val()
        # add x in front of ID, to indicate it is not selected
        so_id_value = so_id_elem.val()
        so_id_elem.val('x'+so_id_value)
        # change active value to false when pre-existing LO is removed
        evid_lo.find('.remove-this-lo').attr('value', '1')
        evid_lo.appendTo('#evid-other-los ul')
        console.log 'Destroyed'
      else
        console.log 'Not destroyed!'

    addLoToEvid = (that, ev) ->
      # move LO from available LOs to Learning Outcomes List.
      evid_lo = $(that).parent().detach()
      so_id_elem = $(evid_lo).find('.so_ids')
      console.log 'value is : '+so_id_elem.val()
      # remove x in front of ID, to indicate it is now selected
      so_id_value = so_id_elem.val()
      so_id_elem.val(so_id_value.replace('x',''))
      # change active value to true when pre-existing LO is reinstated
      evid_lo.find('.remove-this-lo').attr('value', '0')
      evid_lo.appendTo('#evid-current-los ul')

    # clone a blank attachment element to the Attachments Listing
    showAttachToAdd = (that, event) ->
      # clone of new attachment element template.
      attach_elem = $('#evid-add-attachments li').clone()
      # get the next available sequence number from last added item
      last_one_added = $('#evid-attachments-ul li:last-child')
      updated_elem = assignNextSeqEvidItem(attach_elem, last_one_added)
      # append clone to attachments list
      updated_elem.appendTo('#evid-attachments-ul')
      updated_elem.find('.attach_item').trigger('click')

    # clone a blank hyperlink element to the Hyperlinks Listing
    showHyperToAdd = (that, event) ->
      # $('#evid-add-hyperlinks li').clone().appendTo('#evid-hyperlinks-ul')
      # clone of new hyperlink element template.
      attach_elem = $('#evid-add-hyperlinks li').clone()
      # get the next available sequence number from last added item
      last_one_added = $('#evid-hyperlinks-ul li:last-child')
      updated_elem = assignNextSeqEvidItem(attach_elem, last_one_added)
      # append clone to attachments list
      updated_elem.appendTo('#evid-hyperlinks-ul')

    # assign sequence numbers to the cloned item's input fields (attachments and hyperlinks)
    assignNextSeqEvidItem = (attach_elem, last_one_added) ->
      next_seq = '0'
      console.log 'last_one_added.length: '+last_one_added.length
      if last_one_added.length > 0 && last_one_added.find('.attach_item').length > 0
        name = last_one_added.find('.attach_item').attr('name')
        # get ID from name for both attachments and hyperlinks
        last_seq = name.replace('evidence[evidence_attachments_attributes][', '').replace('][attachment]', '').replace('evidence[evidence_hyperlinks_attributes][', '').replace('][hyperlink]', '')
        console.log "last_seq = #{last_seq}"
        next_seq = String(parseInt(last_seq, 10) + 1)
      console.log "next_seq = #{next_seq}"
      # adjust clone with next available sequence number
      console.log "attach_elem.length = #{attach_elem.length}"
      console.log "attach_elem.prop('tagName') = #{attach_elem.prop('tagName')}"
      elem = attach_elem.find('.attach_remove')
      name = elem.attr('name').replace('xxseqxx', next_seq)
      elem.attr('name', name)
      elem = attach_elem.find('.attach_item')
      name = elem.attr('name').replace('xxseqxx', next_seq)
      elem.attr('name', name)
      elem = attach_elem.find('.attach_name')
      name = elem.attr('name').replace('xxseqxx', next_seq)
      elem.attr('name', name)
      return attach_elem

    # clear out dummy hyperlink and attachment items before submit
    # check for errors. only submit if no errors, else warn user.
    prepForSubmit = (that, event) ->
      console.log 'called prepForSubmit'
      $('#evid-add-attachments').remove()
      $('#evid-add-hyperlinks').remove()
      error_row = $('#evid-current-los li#error-row')
      console.log "current los length = #{$('#evid-current-los .lo-row').length}"
      to_return = true
      if $('#evid-current-los .lo-row').length == 0
        displayError('ERRORS: Please fix errors below:')
        error_row.removeClass('display-none')
        error_row.text('Evidence must be assigned to at least one Learning Outcome')
        to_return = false
      if $('#evidence_name').first().val() == ''
        console.log 'empty name error'
        displayError('ERRORS: Please fix errors below:')
        $('#name_error').text('Name is required.')
        to_return = false
      if $('#evidence_evidence_type_id').first().val() == ''
        console.log 'empty type error'
        displayError('ERRORS: Please fix errors below:')
        $('#type_error').text('Evidence Type is required.')
        to_return = false
      console.log "value = #{$('#evid-date_evidence_assignment_date').first().val()}"
      if $('#evid-date_evidence_assignment_date').first().val() == ''
        console.log 'empty date error'
        displayError('ERRORS: Please fix errors below:')
        $('#date_error').text('Assignment Date is required.')
        to_return = false
      return to_return

    removeAllHyperlinks = (that, ev) ->
      console.log 'removeAllHyperlinks'
      console.log 'that on tag: '+$(that).get(0).tagName
      # clearErrors()
      current_state = $(that).prop('checked')
      $('.remove-hyperlink').prop('checked', current_state)

    removeAllAttachments = (that, ev) ->
      console.log 'removeAllAttachments'
      console.log 'that on tag: '+$(that).get(0).tagName
      # clearErrors()
      current_state = $(that).prop('checked')
      $('.remove-attachment').prop('checked', current_state)


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

    $(".btn-primary[type='submit']").on 'click', (event, state) ->
      prepForSubmit(this, event)

    $('#remove-all-hyperlinks').on 'click', (event, state) ->
      removeAllHyperlinks(this, event)

    $('#remove-all-attachments').on 'click', (event, state) ->
      removeAllAttachments(this, event)

  return



