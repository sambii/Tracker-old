#
# * Common JS Code for All Pages
$ ->
  if false  # always load this page for all pages
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
    # REGULAR FUNCTIONS

    # save cell width to server (session variable)
    saveToolkitState = (value) ->
      console.log 'saveToolkitState'
      console.log "value = #{value}"
      if value == 'true' || value == 'false'
        $.ajax({
          url:  "/ui/save_toolkit.js",
          type: 'put',
          data: {
            source_controller: 'ui',
            source_action: 'save_toolkit',
            toolkit: value
          },
          dataType: 'script'
        })

    ###################################
    # ADD EVENT HANDLERS


    # toolkit open/close toggle
    toggleSidebar = (that, ev) ->
      console.log 'toggleSidebar'
      App.sidebar('toggle-sidebar')
      status = $('#page-container').hasClass('sidebar-visible-lg')
      status_str = status.toString()
      saveToolkitState ( status_str )

    # print this page
    printThisPage = (that, ev) ->
      console.log 'printThisPage'
      window.print()

    # show report button
    showReportBtn = (that, ev) ->
      console.log 'show report button clicked'
      $('.hidden_report').show()
      $('.show_report_btn').hide()

    # show upload button
    showUploadBtn = (that, ev) ->
      console.log 'show showUploadBtn called'
      $('#show-upload').show()
      $('.upload-output').hide()
      $('#form-errors').hide()
      $('#breadcrumb-flash-msgs').hide()


    ###################################
    # EVENT BINDINGS


    # toolkit open/close toggle
    $('#head-sidebar-toggle a').on 'click', (event, state) ->
      toggleSidebar(this, event)

    # all print icons will be automatically print enabled
    $('.fa-print').on 'click', (event, state) ->
      printThisPage(this, event)

    # show report button
    $('.show_report_btn').on 'click', (event, state) ->
      showReportBtn(this, event)
    $('.show-report-btn').on 'click', (event, state) ->
      showReportBtn(this, event)

    # show upload button
    $('input:file').on 'change', (event, state) ->
      showUploadBtn(this, event)


    ###################################
    # PAGE INITIALIZATIONS




    ###################################
    # SERVER BUSY PAGE SPINNER

    # initially hide spinner
    $(".spinner").hide();


    # show spinner on AJAX start
    $(document).ajaxStart ->
      $(".spinner").show()

    # show spinner on submit
    $(document).on 'submit', () ->
      $(".spinner").show()

    # hide spinner on AJAX stop
    $(document).ajaxStop ->
      $(".spinner").hide()

  return



