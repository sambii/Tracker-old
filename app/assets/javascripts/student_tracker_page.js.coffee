#
# * Custom JS Code for Student Tracker Page
$ ->
  if $('#page-content.student-tracker-page').length == 0
    return
  else
    # we are on the student tracker page
    console.log "Loading the student-tracker-page"

    #----------------------------------------------------------------------
    # Setup - Variables
    #----------------------------------------------------------------------

    #----------------------------------------------------------------------
    # Setup - Calculated Variables
    #----------------------------------------------------------------------

    #----------------------------------------------------------------------
    # Common functions
    #----------------------------------------------------------------------

    #----------------------------------------------------------------------
    # Event Handler Methods (and supporting methods)
    #----------------------------------------------------------------------


    loShowHideByMarkingPeriod = (that, ev) ->
      console.log 'loShowHideByMarkingPeriod'
      marking_period = $(that).find('a').html().trim().toString()
      marking_period = 0 if marking_period == "All"
      # note - no update to database as in teacher tracker. Students see all at page load.
      # reset active filter (display to user)
      $('.mp-filter').removeClass('active')
      $(that).addClass('active')
      # only show matching learning outcomes (and their opened evidences)
      if marking_period == "All" or marking_period == 0 # or marking_period == null
        $("tbody.tbody-header").addClass('show-tbody')
      else
        $("tbody.tbody-header").each () ->
          # note on student tracker page, the mp# class does not show unless active
          if $(this).find(".mp#{marking_period}").length > 0
            console.log "show header"
            $(this).addClass('show-tbody')
            # if evids.length == 1
            #   evids.first.addClass('showLO')
          else
            console.log "hide header"
            $(this).removeClass('show-tbody')
            # if evids.length == 1
            #   evids.first.removeClass('showLO')


    #----------------------------------------------------------------------
    # Event Handlers & immediate calls to functions
    #----------------------------------------------------------------------

    $("li.mp-filter").on 'click', (event, state) ->
      loShowHideByMarkingPeriod(this, event)

    #----------------------------------------------------------------------
    # PAGE INITIALIZATIONS
    #----------------------------------------------------------------------

