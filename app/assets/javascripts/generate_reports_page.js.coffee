#
# * Custom JS Code for Generate Reports Page
$ ->
  if $('#page-content.generate-reports').length == 0
    return
  else
    # we are on the generate reports page, do the following

    #----------------------------------------------------------------------
    # Setup - Variables
    # todo - put this in an include file.
    #----------------------------------------------------------------------

    err_element = $('#breadcrumb-flash-msgs')
    tracker_rating_blue = '#28a9e1'
    tracker_rating_green = '#2fb15d'
    tracker_rating_yellow = '#f4bd00'
    tracker_rating_red = '#e64d3c'

    #----------------------------------------------------------------------
    # Setup - Calculated Variables
    #----------------------------------------------------------------------

    ###################################
    # COMMON FUNCTIONS

    # set the visibility of form fields based upon the selected value
    showHideBySelect = (that) ->
      val = $(that).val()
      # prevent javascript error if no report type selected
      return if !val
      console.log 'selected value: '+val
      $('#ask-subjects').hide()
      if $(that).find('#'+val).data('ask-subjects') == 1
        $('#ask-subjects').show()
      $('#ask-grade-level').hide()
      if $(that).find('#'+val).data('ask-grade-level') == 1
        $('#ask-grade-level').show()
      $('#ask-sections').hide()
      if $(that).find('#'+val).data('ask-sections') == 1
        $('#ask-sections').show()
      $('#ask-los').hide()
      if $(that).find('#'+val).data('ask-los') == 1
        $('#ask-los').show()
      $('#ask-student').hide()
      if $(that).find('#'+val).data('ask-student') == 1
        $('#ask-student').show()
      $('#ask-single-student').hide()
      if $(that).find('#'+val).data('ask-single-student') == 1
        $('#ask-single-student').show()
      $('#ask-marking-periods').hide()
      if $(that).find('#'+val).data('ask-marking-periods') == 1
        $('#ask-marking-periods').show()
      $('#ask-date-range').hide()
      if $(that).find('#'+val).data('ask-date-range') == 1
        $('#ask-date-range').show()
      $('#ask-attendance-type').hide()
      if $(that).find('#'+val).data('ask-attendance-type') == 1
        $('#ask-attendance-type').show()
      $('#ask-details').hide()
      if $(that).find('#'+val).data('ask-details') == 1
        $('#ask-details').show()


    # show subject-section (if enabled) and populate with sections for subject
    showSectionsForSubjects = (that) ->
      console.log 'getSectionsForSubject'
      subject_id = $(that).val()
      if school_year_id != null && subject_id != null
        $('#ask-subject-sections').show()
        console.log "subject_id: #{subject_id}"
        school_year_id = $('input#school_year_id').val()
        console.log "school_year_id: #{school_year_id}"
        xhr = $.ajax
          url:  "/sections"
          type: 'get'
          data:
            subject_id: subject_id,
            school_year_id: school_year_id
          dataType: 'json'
          success: (resp, status, xhr) ->
            console.log "done: status: #{status}"
            $('#subject-section-select').select2('val', '')
            $('#subject-section-select')
              .find('option')
              .remove()
              .end()
              .append("<option value='subj'></option>")
            for sect, i in resp
              $('#subject-section-select').append("<option value='#{sect.id}'>#{sect.name}</option>")
            - # set default to be no sections
            $('#subject-section-select').val('subj').change()
          error: (xhr, status, err) ->
            console.log "fail: resp: #{xhr.responseText}"
            console.log "fail: status: #{status}"
      else
        $('#breadcrumb-flash-msgs').html("<span class='flash_notice'>Warning: no school / school year</span>")

    ###################################
    # ADD EVENT HANDLERS

    # change which form fields the user enters, based upon the selected generate
    changeGenerateType = (that, ev) ->
      console.log 'called changeGenerateType'
      showHideBySelect(that)

    # change subject
    changeSubject = (that, ev) ->
      console.log 'called changeSubject'
      showSectionsForSubjects(that)

    # clear out dummy hyperlink and attachment items before submit
    prepForSubmit = (that, ev) ->
      console.log 'called prepForSubmit'


    ###################################
    # ADD EVENT BINDINGS

    $('select#generate-type').on 'change', (event, state) ->
      changeGenerateType(this, event)

    $('select#subject').on 'change', (event, state) ->
      changeSubject(this, event)

    $(".btn-primary[type='submit']").on 'click', (event, state) ->
      prepForSubmit(this, event)


    ###################################
    # INITIALIZE FOR EXISTING SELECTED VALUE

    console.log 'Initialize Generate Generates Page'
    showHideBySelect($('#generate-type'))


  return



