#
# * Custom JS Code for Miscellaneous Pages
$ ->
  if $('#page-content.misc').length == 0
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
    tracker_rating_unrated = '#999'

    #----------------------------------------------------------------------
    # Setup - Calculated Variables
    #----------------------------------------------------------------------

    ###################################
    # REGULAR FUNCTIONS

    # prepare pie chart
    preparePieChart = () ->
      console.log 'called preparePieChart'
      pie = $('#pie-chart')
      if pie.length > 0
        console.log "pie.length = #{pie.length}"
        red_count = parseInt(pie.data('red-count'))
        console.log "red_count = #{red_count}"
        green_count = parseInt(pie.data('green-count'))
        console.log "green_count = #{green_count}"
        blue_count = parseInt(pie.data('blue-count'))
        console.log "blue_count = #{blue_count}"
        unrated_count = parseInt(pie.data('unrated-count'))
        console.log "unrated_count = #{unrated_count}"
        if isNaN(unrated_count)
          unrated_count = 0
          console.log "WARNING - NO unrated_count IS SET!!!"
        size = parseInt(pie.data('px-size')) || 300
        console.log "size = #{size}"
        pie.sparkline(["#{unrated_count}", "#{red_count}", "#{green_count}", "#{blue_count}"], type: 'pie', width: '#{size}', height: "#{size}", sliceColors: ["#{tracker_rating_unrated}", "#{tracker_rating_red}", "#{tracker_rating_green}", "#{tracker_rating_blue}"]);


    ###################################
    # ADD EVENT HANDLERS

    # group collapse and expand toggle
    toggleGroupBody = (that, ev) ->
      console.log 'toggleGroupBody'
      $(that).parents(".group-header").toggleClass "show-body"
      return

    collapseAllGroups = (that, ev) ->
      console.log 'collapseAllGroups'
      $('.group-header').removeClass('show-body')

    expandAllGroups = (that, ev) ->
      console.log 'expandAllGroups'
      $('.group-header').addClass('show-body')


    # tbody collapse and expand toggle
    toggleTbodyBody = (that, ev) ->
      console.log 'toggleTbodyBody'
      $(that).parents(".tbody-header").toggleClass "show-tbody-body"
      return

    collapseAllTbodies = (that, ev) ->
      console.log 'collapseAllTbodies'
      $('.tbody-header').removeClass('show-tbody-body')

    expandAllTbodies = (that, ev) ->
      console.log 'expandAllTbodies'
      $('.tbody-header').addClass('show-tbody-body')


    # toggle all checkboxes on student listings
    toggleAllStudents = (that, ev) ->
      console.log 'toggleAllStudents'
      current_state = $(that).prop('checked')
      $('.toggle-student').prop('checked', current_state)


    # submit on change (e.g. date picker)
    submitOnChange = (that, ev) ->
      console.log 'submitOnChange'
      ev.preventDefault()
      $(that).parents('form').submit()


    ###################################
    # EVENT BINDINGS


    # Toggle expand-collapse group on click
    $(".expand-collapse-group .toggle-group-body").on "click", (event, state) ->
      toggleGroupBody(this, event)

    $("#collapse-all-groups").on 'click', (event, state) ->
      collapseAllGroups(this, event)

    $("#expand-all-groups").on 'click', (event, state) ->
      expandAllGroups(this, event)


    # Toggle expand-collapse tbody on click
    $(".expand-collapse-tbody .toggle-tbody").on "click", (event, state) ->
      toggleTbodyBody(this, event)

    $("#collapse-all-tbodies").on 'click', (event, state) ->
      collapseAllTbodies(this, event)

    $("#expand-all-tbodies").on 'click', (event, state) ->
      expandAllTbodies(this, event)


    # toggle all checkboxes on student listings
    $('#toggle-all-students').on 'click', (event, state) ->
      toggleAllStudents(this, event)


    # submit on change (e.g. date picker)
    $('.submit-on-change').on 'change', (event, state) ->
      submitOnChange(this, event)


    ###################################
    # PAGE INITIALIZATIONS

    console.log 'check to Prepare Pie chart'
    preparePieChart()

  return



