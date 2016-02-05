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
      $('#ask-students').hide()
      # if $(that).find('#'+val).data('ask-student') == 1
      #   $('#ask-student').show()
      $('#ask-marking-periods').hide()
      if $(that).find('#'+val).data('ask-marking-periods') == 1
        $('#ask-marking-periods').show()
      $('#ask-subjects').hide()
      if $(that).find('#'+val).data('ask-subjects') == 1
        $('#ask-subjects').show()
      $('#ask-date-range').hide()
      if $(that).find('#'+val).data('ask-date-range') == 1
        $('#ask-date-range').show()


    ###################################
    # ADD EVENT HANDLERS

    # change which form fields the user enters, based upon the selected generate
    changeGenerateType = (that, ev) ->
      console.log 'called changeGenerateType'
      showHideBySelect(that)



    # clear out dummy hyperlink and attachment items before submit
    prepForSubmit = (that, ev) ->
      console.log 'called prepForSubmit'


    ###################################
    # ADD EVENT BINDINGS

    $('select#generate-type').on 'change', (event, state) ->
      changeGenerateType(this, event)

    $(".btn-primary[type='submit']").on 'click', (event, state) ->
      prepForSubmit(this, event)


    ###################################
    # INITIALIZE FOR EXISTING SELECTED VALUE

    console.log 'Initialize Generate Generates Page'
    showHideBySelect($('#generate-type'))


  return



