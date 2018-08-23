#
# * Custom JS Code for Tracker Page
$ ->
  if $('#page-content.edit_subject_outcomes').length == 0
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


    ###################################
    # ADD EVENT HANDLERS

    addNewLo = (that, ev) ->
      # $('#evid-add-hyperlinks li').clone().appendTo('#evid-hyperlinks-ul')
      # clone of new hyperlink element template.

      attach_elem = $('#blank_lo li').clone()
      # get the next available sequence number from last added item
      last_one_added = $('#current_los li:last-child')
      updated_elem = assignNextSeqEvidItem(attach_elem, last_one_added)
      # append clone to attachments list
      updated_elem.appendTo('#current_los')

    # assign sequence numbers to the cloned item's input fields (attachments and hyperlinks)
    assignNextSeqEvidItem = (attach_elem, last_one_added) ->
      next_seq = '0'
      console.log 'last_one_added.length: '+last_one_added.length
      if last_one_added.length > 0 && last_one_added.find("input[type='text']").length > 0
        name = last_one_added.find('input').attr('name')
        last_seq = name.replace('subject[subject_outcomes_attributes][', '').replace('][name]', '')
        console.log "last_seq = #{last_seq}"
        next_seq = String(parseInt(last_seq, 10) + 1)
      console.log "next_seq = #{next_seq}"
      # adjust clone with next available sequence number
      console.log "attach_elem.length = #{attach_elem.length}"
      console.log "attach_elem.prop('tagName') = #{attach_elem.prop('tagName')}"
      elem = attach_elem.find("input[type='text']")
      name = elem.attr('name').replace('xxseqxx', next_seq)
      elem.attr('name', name)
      return attach_elem

    # clear out dummy hyperlink and attachment items before submit
    prepForSubmit = (that, event) ->
      console.log 'called prepForSubmit'
      $('#blank_lo').remove()


    ###################################
    # ADD EVENT BINDINGS

    $('#add_new_lo').on 'click', (event, state) ->
      console.log('called #addNewLo')
      addNewLo(this, event)
      console.log('called #addNewLo2')

    $(".btn-primary[type='submit']").on 'click', (event, state) ->
      prepForSubmit(this, event)


  return



