#
# * Custom JS Code for Tracker Page
$ ->
  if $('#page-content.tracker-page').length == 0
    return
  else
    # we are on the tracker page, do the following

    #----------------------------------------------------------------------
    # Setup - Variables
    #----------------------------------------------------------------------

    #
    # Init columns pagination functionality + mini-mode
    colsPerPage = 4   # this gets set in window.trackerCommonCode.resizePageContent
    trSetThinnerMode = $('#tr-set-thinnermode')
    trSetThinMode = $('#tr-set-thinmode')
    trSetRegMode = $('#tr-set-regmode')
    trSetWideMode = $('#tr-set-widemode')
    trSetWiderMode = $('#tr-set-widermode')
    gbPgNext = $("#gb-pg-next")
    gbPgPrev = $("#gb-pg-prev")
    curOffset = 0

    trTable = $(".tracker-table")

    #
    # Popups functionality
    puTop = undefined
    puLeft = undefined
    puHover = $("#popup-hover")
    puComment = $("#popup-hover-comment")
    puDate = $("#popup-hover-date")
    puRate1Lo = $('#popup-rate-single-lo')
    puRate1Evid = $('#popup-rate-single-evid')

    bulk_lo_changed = false
    bulk_evid_changed = false

    err_element = $('#breadcrumb-flash-msgs')

    #----------------------------------------------------------------------
    # Setup - Calculated Variables
    #----------------------------------------------------------------------


    # Here we count all the columns of the table and then remove 2 (the first and the last one)
    colsCount = 0
    trTable.find("thead th").each ->
      colsCount++
    colsCount = colsCount - 2


    # Disable previous pagination button
    gbPgPrev.parent("li").addClass "disabled"

    # Disable next pagination button only if needed
    gbPgNext.parent("li").addClass "disabled"  if colsCount <= colsPerPage

    # Show the first page
    window.trackerCommonCode.showPage -9999 # go to first page of students (force student column header rebuild/clone)


    #----------------------------------------------------------------------
    # Common functions
    #----------------------------------------------------------------------


    # save cell width to server (session variable)
    saveCellSize = (new_cell_size) ->
      if new_cell_size != ''
        $.ajax({
          url:  "/ui/save_cell_size.js",
          type: 'put',
          data: {
            source_controller: 'ui',
            source_action: 'save_cell_size',
            cell_size: new_cell_size
          },
          dataType: 'script'
        })

    initializeCellSizeSelectors = () ->
      console.log 'initializeCellSizeSelectors'
      trSetThinnerMode.parent('li').removeClass 'active'
      trSetThinMode.parent('li').removeClass 'active'
      trSetRegMode.parent('li').removeClass 'active'
      trSetWideMode.parent('li').removeClass 'active'
      trSetWiderMode.parent('li').removeClass 'active'
      if trTable.hasClass("thinner-mode")
        trSetThinnerMode.parent('li').addClass 'active'
      else if trTable.hasClass("thin-mode")
        trSetThinMode.parent('li').addClass 'active'
      else if trTable.hasClass("regular-mode")
        trSetRegMode.parent('li').addClass 'active'
      else if trTable.hasClass("wide-mode")
        trSetWideMode.parent('li').addClass 'active'
      else if trTable.hasClass("wider-mode")
        trSetWiderMode.parent('li').addClass 'active'
      else
        trSetRegMode.parent('li').addClass 'active'
      return

    initializeLoDragDrop = () ->
      console.log "initializeLoDragDrop"
      $("#tracker-table-container .tracker-table.ui-sortable").sortable
        axis: 'y'
        opacity: 0.7
        cursor: "move"
        forcePlaceholderSize: true
        items: "tbody.tbody-header"
        start: (e, ui) ->
          console.log "*** start event"
          cur_ix = ui.item.index()
          so_id = ui.item.attr('data-so-id')
          item_evidences = ui.item.parent().find("tbody.tbody-section[data-so-id=#{so_id}]")
          item_evidences.css("display","none")
          # # hide all evidences at start of drag
          # $('.tbody-section').each () ->
          #   $(this).css('display','none')
          return
        stop: (e, ui) ->
          # ensure all evidences are properly positioned and displayed when done
          # - regardless if no drag/drop done, lo placed between lo and evidences, etc.
          console.log "*** stop event"
          $('.tbody-header').each () ->
            item_lo = $(this)
            cur_ix = item_lo.index()
            so_id = item_lo.attr('data-so-id')
            item_evidences = $(this).parent().find("tbody.tbody-section[data-so-id=#{so_id}]")
            # make sure evidences is next item after LO, else move it
            if item_evidences.index() != cur_ix + 1
              console.log "must move item #{so_id} at #{item_evidences.index()} to #{cur_ix + 1}"
              item_lo.after(item_evidences.detach())
            # display evidences below LO if was originally shown
            if item_lo.hasClass('tbody-open')
              item_evidences.removeAttr('style')
          return

        update: (e, ui) ->
          console.log "*** update event"
          # get the section id for ajax call
          section_id = $('.tracker-table.ui-sortable').attr('data-section-id')
          # get the current sequence of LOs for update to back end
          outcome_ids = []
          $('.tbody-header').each () ->
            outcome_ids.push ''+$(this).attr('data-so-id')+''
          console.log "ids: [#{outcome_ids.join()}]"
          # update the sequence of LOs in the database
          $.ajax({
            url:  "/section_outcomes/sort",
            type: 'get',
            data: {
              source_controller: 'section_outcomes',
              source_action: 'sort',
              section_id: section_id,
              section_outcomes: outcome_ids
            },
            dataType: 'script'
          })
          return

    checkSingleBulkEvid = () ->
      console.log "checkSingleBulkEvid - #{$('.select-so').length}"
      if $('.select-so').length == 1
        $('.select-so').prop('checked', true)
      else

    checkSingleBulkLO = () ->
      console.log "checkSingleBulkLO - #{$('.evid-selector').length}"
      if $('.evid-selector').length == 1
        $('.evid-selector input').prop('checked', true)
      else


    #----------------------------------------------------------------------
    # Event Handler Methods (and supporting methods)
    #----------------------------------------------------------------------

    console.log 'On Tracker Page custom Javascript (tracker_page.js.coffee)'

    toggleTableSections = (that, ev) ->
      console.log 'toggleTableSections'
      clearErrors()
      checkPriorityEvents(ev)
      $(that).parents(".tbody-header").toggleClass "tbody-open"
      return

    # tbodyToggleAllCheckboxes = (that, ev) ->
    #   console.log 'tbodyToggleAllCheckboxes'
    #   checkPriorityEvents(ev)
    #   checkedStatus = $(that).prop("checked")
    #   tsection = $(that).parents(".tbody-header").next(".tbody-section")
    #   $("input:checkbox", tsection).each ->
    #     $(that).prop "checked", checkedStatus
    #     return
    #   return

    previousPagination = (that, ev) ->
      console.log 'previousPagination'
      clearErrors()
      checkPriorityEvents(ev)
      unless $(that).parent("li").hasClass("disabled")
        gbPgPrev.parent("li").addClass "disabled"  if (curOffset - colsPerPage) <= 0
        gbPgNext.parent("li").removeClass "disabled"
      window.trackerCommonCode.showPage -1
      return

    nextPagination = (that, ev) ->
      console.log 'nextPagination'
      clearErrors()
      checkPriorityEvents(ev)
      unless $(that).parent("li").hasClass("disabled")
        gbPgNext.parent("li").addClass "disabled"  if ((curOffset + colsPerPage) + colsPerPage) >= colsCount
        gbPgPrev.parent("li").removeClass "disabled"
      window.trackerCommonCode.showPage +1
      return

    clearModes = (that) ->
      console.log 'clearModes'
      trTable.removeClass "thinner-mode"
      trTable.removeClass "thin-mode"
      trTable.removeClass "regular-mode"
      trTable.removeClass "wide-mode"
      trTable.removeClass "wider-mode"
      trSetThinnerMode.parent('li').removeClass 'active'
      trSetThinMode.parent('li').removeClass 'active'
      trSetRegMode.parent('li').removeClass 'active'
      trSetWideMode.parent('li').removeClass 'active'
      trSetWiderMode.parent('li').removeClass 'active'
      return

    setThinnerMode = (that, ev) ->
      console.log 'setThinnerMode'
      clearErrors()
      checkPriorityEvents(ev)
      clearModes(that)
      trTable.addClass "thinner-mode"
      trSetThinnerMode.parent('li').addClass 'active'
      saveCellSize("thinner-mode")
      window.trackerCommonCode.showPage 0
      return

    setThinMode = (that, ev) ->
      console.log 'setThinMode'
      clearErrors()
      checkPriorityEvents(ev)
      clearModes(that)
      trTable.addClass "thin-mode"
      trSetThinMode.parent('li').addClass 'active'
      saveCellSize("thin-mode")
      window.trackerCommonCode.showPage 0
      return

    setRegMode = (that, ev) ->
      console.log 'setRegMode'
      clearErrors()
      checkPriorityEvents(ev)
      clearModes(that)
      trTable.addClass "regular-mode"
      trSetRegMode.parent('li').addClass 'active'
      saveCellSize("regular-mode")
      window.trackerCommonCode.showPage 0
      return

    setWideMode = (that, ev) ->
      console.log 'setWideMode'
      clearErrors()
      checkPriorityEvents(ev)
      clearModes(that)
      trTable.addClass "wide-mode"
      trSetWideMode.parent('li').addClass 'active'
      saveCellSize("wide-mode")
      window.trackerCommonCode.showPage 0
      return


    setWiderMode = (that, ev) ->
      console.log 'setWiderMode'
      clearErrors()
      checkPriorityEvents(ev)
      clearModes(that)
      trTable.addClass "wider-mode"
      trSetWiderMode.parent('li').addClass 'active'
      saveCellSize("wider-mode")
      window.trackerCommonCode.showPage 0
      return

    # position moveable dialog box to not go off page
    positionDialog = (dialog_elem, cell, show_evids=false) ->
      console.log 'positionDialog'
      cell_height = Math.floor($(cell).outerHeight())
      console.log 'cell_height: '+cell_height
      cell_width = Math.floor($(cell).outerWidth())
      console.log 'cell_width: '+cell_width
      puTop = Math.floor($(cell).offset().top) + cell_height
      puLeft = Math.floor($(cell).offset().left)
      console.log "original puLeft = #{puLeft}"
      if show_evids
        puLeft += cell_width + 4
        console.log "new puLeft = #{puLeft}"
      dialog_width = Math.floor(dialog_elem.width())
      full_width = puLeft + dialog_width
      console.log "full_width = #{full_width}"
      window_width = Math.floor($(window).width())
      console.log "window_width = #{window_width}"
      if show_evids
        # make sure evidences are not covered
        if full_width > window_width
          puLeft -= dialog_width + cell_width + 4
          console.log "puLeft = #{puLeft}"
      else
        # make sure dialog does not go past page width
        if full_width > window_width
          puLeft -= full_width - window_width
          console.log "puLeft = #{puLeft}"
      popup_height = Math.floor(dialog_elem.height())
      window_height = Math.floor($(window).height())
      document_height = Math.floor($(document).height())
      old_buffer_height = Math.floor($('#tracker_table_bottom_buffer').height())
      old_buffer_height = 0 if isNaN(old_buffer_height)
      buffer_height = Math.floor(puTop + popup_height + old_buffer_height - document_height)
      if buffer_height > 0
        $('#tracker_table_bottom_buffer').css('height', buffer_height)
      dialog_elem.css(
        top: puTop
        left: puLeft
      ).show()
      console.log "#{dialog_elem.attr('id')} dialog shown"


    # set event to warn user of changes before exiting page
    setBeforeUnload = () ->
      console.log 'setting beforeunload event.'
      $(window).on 'beforeunload', (event) ->
        console.log 'Trying to go to beforeunload popup'
        return "Your changes will be LOST if you leave this page now!!!"

    # clear event, to no longer warn user of changes before exiting page
    clearBeforeUnload = () ->
      $(window).off 'beforeunload'



    loShowHideByMarkingPeriod = (that, ev) ->
      console.log 'loShowHideByMarkingPeriod'
      clearErrors()
      checkPriorityEvents(ev)
      marking_period = $(that).find('a').html().trim().toString()
      marking_period = 0 if marking_period == "All"
      current_section_id = $("#tracker-header").attr('data-section-id')
      $.ajax({
        url:  "/sections/#{current_section_id}",
        type: 'put',
        data: {
          source_controller: 'sections',
          source_action: 'show',
          section: { selected_marking_period: marking_period }
        },
        dataType: 'script'
      })
      # reset active filter (display to user)
      $('.mp-filter').removeClass('active')
      $(that).addClass('active')
      # only show matching learning outcomes (and their opened evidences)
      if marking_period == "All" or marking_period == 0 # or marking_period == null
        # console.log "Show all LOs"
        $("tbody.tbody-header").addClass('showLO')
      else
        console.log "show"
        $("tbody.tbody-header").each () ->
          # evids = $(this).find(' ~ .tbody-section')
          # console.log "Check for Marking Period in #{$(this).prop('tagName')} - #{$(this).attr('data-so-id')}"
          # note on teacher tracker page, the mp# class is always there, if active or not
          if $(this).find(".mp#{marking_period}.active").length > 0
            $(this).addClass('showLO')
            # if evids.length == 1
            #   evids.first.addClass('showLO')
          else
            $(this).removeClass('showLO')
            # if evids.length == 1
            #   evids.first.removeClass('showLO')

    toggleEvidenceShow = (that, ev) ->
      console.log 'toggleEvidenceShow'
      clearErrors()
      checkPriorityEvents(ev)
      tbody_header = $(that).parents('.tbody-header')
      current_so_id = tbody_header.attr('data-so-id')
      console.log "current_so_id = #{current_so_id}"
      open_status = tbody_header.hasClass('tbody-open')
      console.log "open_status = #{open_status}"
      new_status = !open_status
      console.log "new_status = #{new_status}"
      $.ajax({
        url:  "/section_outcomes/#{current_so_id}",
        type: 'put',
        data: {
          source_controller: 'section_outcomes',
          source_action: 'update',
          section_outcome: { minimized: open_status }
        },
        dataType: 'script'
      })
      # this should be done by ajax response (feedback if errors, logged out, ...)
      # $(that).parents('.tbody-header').toggleClass('tbody-open')

    collapseAllEvidences = (that, ev) ->
      console.log 'collapseAllEvidences'
      clearErrors()
      checkPriorityEvents(ev)
      current_section_id = $("#tracker-header").attr('data-section-id')
      $.ajax({
        url:  "/sections/#{current_section_id}/exp_col_all_evid",
        type: 'put',
        data: {
          source_controller: 'sections',
          source_action: 'exp_col_all_evid',
          minimized: 'true'
        },
        dataType: 'script'
      })
      # this should be done by ajax response (feedback if errors, logged out, ...)
      # $('.tbody-header').removeClass('tbody-open')

    expandAllEvidences = (that, ev) ->
      console.log 'expandAllEvidences'
      clearErrors()
      checkPriorityEvents(ev)
      current_section_id = $("#tracker-header").attr('data-section-id')
      $.ajax({
        url:  "/sections/#{current_section_id}/exp_col_all_evid",
        type: 'put',
        data: {
          source_controller: 'sections',
          source_action: 'exp_col_all_evid',
          minimized: 'false'
        },
        dataType: 'script'
      })
      # this should be done by ajax response (feedback if errors, logged out, ...)
      # $('.tbody-header').addClass('tbody-open')

    updateSubsectionDisplay = (that, ev) ->
      console.log 'updateSubsectionDisplay'
      clearErrors()
      checkPriorityEvents(ev)
      console.log 'subsection='+$('#subsection-select').val()
      window.location = window.location.pathname + "?subsection=#{$('#subsection-select').val()}"


    # ###################################
    # # GENERAL POSITIONED POPUP CODE

    # submit_popup_on_enter = (that, ev) ->
    #   console.log 'keypress'
    #   if ((ev.keyCode == 13) && (ev.target.type != "textarea"))
    #     console.log 'keycode 13'
    #     ev.preventDefault()
    #     $(that).submit()


    ###################################
    # COMMENT HOVER CODE

    turn_on_comment_hover = (ev) ->
      console.log 'turn_on_comment_hover'
      $(".evid-cell > a.commented").off("mouseenter mouseleave")
      $(".evid-cell > a.commented").on("mouseenter", ->
        commentHoverOver(this, ev)
      ).on "mouseleave", ->
        commentHoverOff()
      return

    turn_off_comment_hover = () ->
      console.log 'turn_off_comment_hover'
      $(".evid-cell > a.commented").off("mouseenter mouseleave")
      return

    commentHoverOver = (that, ev) ->
      console.log 'commentHoverOver'
      checkPriorityEvents(ev)
      # clear all over popups
      if ev
        clearAllPopups(ev)
      # populate the popup with data
      esor_comment = $(that).data('comment')
      if typeof esor_comment == undefined
        $('#popup-hover-comment').text('')
      else
        $('#popup-hover-comment').text(esor_comment)
      # set position of popup
      puTop = $(that).offset().top + 40
      puLeft = $(that).offset().left
      # show popup (need to show background also)
      positionDialog(puHover, that)
      return

    commentHoverOff = () ->
      console.log 'commentHoverOff'
      puHover.css(
        top: 0
        left: 0
      ).hide()
      return


    ###################################
    # HANDLING CLICKS OUTSIDE OF POSITIONED POPUP

    # Click not captured by any event.  clear popups just in case.
    clickOutOfDialog = (that, ev) ->
      console.log 'clickOutOfDialog (uncaptured click)'
      checkPriorityEvents(ev)
      # # if click on element that does not have an id attribute, then clear all popups
      # # assumption here, is that elements with id attributes will have a popup ???
      # # Why - to allow other popups, or to prevent cancelling out of popup?
      # has_data_id = $(ev.target).closest('[data-id]').length
      # console.log 'target (has_data_id): '+has_data_id
      has_popup = $(ev.target).closest('.popup')
      if !has_popup.length  # !has_data_id &&
        clearAllPopups(ev)
      console.log 'click down done'

    clearAllPopups = (ev) ->
      console.log 'clearAllPopups'
      checkPriorityEvents(ev)
      commentHoverOff()
      puRate1Lo.hide()
      puRate1Evid.hide()
      $('table.tracker-table td.highlight-cell').removeClass('highlight-cell')
      $('table.tracker-table td.mark-evid-col').removeClass('mark-evid-col')
      turn_on_comment_hover(ev)

    checkPriorityEvents = (ev) ->
      console.log 'checkPriorityEvents'
      # only check for priority events on bulk pages (for bulk_lo_changed and bulk_evid_changed)
      if $('#page-content.bulk-rate').length > 0
        # don't do update if clicking inside the popup (and not captured)
        if typeof ev == 'undefined'
          # skip checks ??????
        else
          console.log "make sure not in popup"
          has_popup = $(ev.target).closest('.popup').length
          console.log "has_popup = #{has_popup}"
          console.log "ev.target = #{$(ev.target).attr('id')}"
          if has_popup == 0
            # outside of popup - update and close them
            updateCellBulkLo(ev) if bulk_lo_changed
            updateCellBulkEvid(ev) if bulk_evid_changed

    updateCellBulkLo = (ev) ->
      console.log 'updateCellBulkLo'
      clearErrors()
      onlySaveLoRating(ev)
      puRate1Lo.hide()  # do this to close dialog when clicking out of dialog
      bulk_lo_changed = false

    updateCellBulkEvid = (ev) ->
      console.log 'updateCellBulkEvid'
      clearErrors()
      onlySaveEvidenceRating(ev)
      puRate1Evid.hide()  # do this to close dialog when clicking out of dialog ?
      bulk_evid_changed = false

    ###################################
    # SECTION OUTCOME RATING POSITIONED POPUP

    # rate single LO popup call from click on student rating.
    sectionOutcomeCellClick = (that, ev) ->
      console.log 'sectionOutcomeCellClick'
      clearErrors()
      checkPriorityEvents(ev)
      # $('#popup-rate-single-lo').show()
      # clear all over popups
      clearAllPopups(ev)
      # sor_id = $(that).attr('id').replace("s_o_r_", "")
      sor_id = $(that).data('id')
      console.log 'sor_id: '+sor_id
      sor_student_id = $(that).data('student-id')
      console.log 'sor_student_id: '+sor_student_id
      sor_so_id = $(that).data('so-id')
      console.log 'sor_so_id: '+sor_so_id
      rating = $(that).data('rating')
      # highlight the current cell
      # $(that).parent().addClass('highlight-cell')
      # fill out the data in the popup
      puRate1Lo.find('li.active').removeClass('active')
      console.log 'rating: '+$(that).data('rating')
      switch $(that).data('rating')
        when 'H' then puRate1Lo.find('li.blue').addClass('active')
        when 'P' then puRate1Lo.find('li.green').addClass('active')
        when 'N' then puRate1Lo.find('li.red').addClass('active')
        when 'U' then puRate1Lo.find('li.unrated').addClass('active')
        else puRate1Lo.find('li.unrated').addClass('active')
      # save the ID of this sor in the popup (for popup handling)
      puRate1Lo.data('id', sor_id)
      console.log 'set id in popup: '+$(that).data('id')
      # save the student ID of this sor in the popup (for popup handling)
      puRate1Lo.data('student-id', sor_student_id)
      # save the eso ID of this sor in the popup (for popup handling)
      puRate1Lo.data('so-id', sor_so_id)
      bulk_rate = $(that).parents('.tbody-header').hasClass('bulk-rate')
      if bulk_rate
        puRate1Lo.addClass('bulk-rate')
      else
        puRate1Lo.removeClass('bulk-rate')
      console.log 'bulk_rate: '+bulk_rate
      console.log 'show evidences under'
      evid_ratings = $(".tbody-section[data-so-id='#{sor_so_id}'] td a[data-student-id='#{sor_student_id}']")
      evid_ratings.each (i, elem) ->
        console.log 'matched item with ID: '+$(elem).attr('id')
        $(elem).parent().addClass('mark-evid-col')
        return
      # turn off evidence hovers
      turn_off_comment_hover()
      # set the position and display the dialog
      positionDialog(puRate1Lo, that, true)
      ev.stopPropagation()
      return

    # record rating click on single LO popup (bulk or single)
    # does not close popup, update database or have cell updated
    setLoRating = (that, ev) ->
      # checkPriorityEvents(ev) #????
      clearErrors()
      console.log 'setLoRating'
      selected_rating = $(that).data('selection')
      console.log 'selected_rating: '+selected_rating
      $(that).parents('ul').find('li.active').removeClass('active')
      $(that).parents('li').addClass('active')
      if $(that).parents('#popup-rate-single-lo').hasClass('bulk-rate')
        console.log 'set bulk_lo_changed = true'
        bulk_lo_changed = true
      ev.stopPropagation()
      return

    saveLoRating = (ev) ->
      console.log 'saveLoRating'
      clearErrors()
      checkPriorityEvents(ev) #????
      onlySaveLoRating(ev)
      clearAllPopups(ev)

    onlySaveLoRating = (ev) ->
      # checkPriorityEvents(ev) #????
      console.log 'onlySaveLoRating'
      $('table.tracker-table td.mark-evid-col').removeClass('mark-evid-col')
      popup = $('#popup-rate-single-lo')
      selected_rating = popup.find('li.active a').data('selection')
      selected_id = popup.data('id')
      selected_student_id = popup.data('student-id')
      selected_so_id = popup.data('so-id')
      if popup.hasClass('bulk-rate')
        console.log 'WARNING - save process as bulk rate'
        setBeforeUnload() # warn user of changes made before moving off page
        # sor created, update display
        cell_section = $(".tbody-header[data-so-id='#{selected_so_id}']")
        original_cell = cell_section.find("[data-student-id='#{selected_student_id}'][data-so-id='#{selected_so_id}']")
        original_cell.data('changed', true)
        original_cell.data('rating', selected_rating)
        window.trackerCommonCode.updateLoCellRating(original_cell, selected_rating)
      else
        console.log 'WARNING - process as single rate with update'
        createUpdateSor(selected_id, selected_student_id, selected_so_id, selected_rating, false)
      # clearAllPopups(ev)


    cancelLoRating = (ev) ->
      # checkPriorityEvents(ev) #????
      console.log 'cancelLoRating'
      $('table.tracker-table td.mark-evid-col').removeClass('mark-evid-col')
      popup = $('#popup-rate-single-lo')
      selected_rating = popup.find('li.active a').data('selection')
      selected_id = popup.data('id')
      selected_student_id = popup.data('student-id')
      selected_so_id = popup.data('so-id')
      if popup.hasClass('bulk-rate')
        console.log 'process cancel in bulk rate dialog`'
        # set popup value to original value just in case
        cell_section = $(".tbody-header[data-so-id='#{selected_so_id}']")
        original_cell = cell_section.find("[data-student-id='#{selected_student_id}'][data-so-id='#{selected_so_id}']")
        original_rating = original_cell.data('rating')
        console.log 'original_rating: '+original_rating
        popup.find('li.active').removeClass('active')
        switch original_rating
          when 'H' then popup.find('li.blue').addClass('active')
          when 'P' then popup.find('li.green').addClass('active')
          when 'N' then popup.find('li.red').addClass('active')
          when 'U' then popup.find('li.unrated').addClass('active')
          else popup.find('li.unrated').addClass('active')
        window.trackerCommonCode.updateLoCellRating(original_cell, original_rating)
      else
        console.log 'ERROR = process as single rate with update'
        # createUpdateSor(selected_id, selected_student_id, selected_so_id, selected_rating, false)
      # clearAllPopups(ev)
      puRate1Lo.hide()
      $('table.tracker-table td.mark-evid-col').removeClass('mark-evid-col')
      # turn on evidence hovers
      turn_on_comment_hover(ev)
      console.log 'onlyCancelLoRating done'


    # ajax call to update the Section Outcome Rating (called from single popup and bulk save)
    createUpdateSor = (id, student_id, so_id, rating, bulk_rate) ->
      console.log 'createUpdateSor'
      clearErrors()
      if (typeof id == 'undefined')
        displayError('ERROR - undefined ID')
      else if ''+id == '0'
        console.log 'Create SOR, id == 0'
        $.ajax "/section_outcome_ratings",
          type: 'post'
          data: {
            source_controller: 'section_outcome_ratings',
            source_action: 'create',
            section_outcome_rating: { section_outcome_id: so_id, student_id: student_id, rating: rating },
            bulk: bulk_rate
          }
          dataType: 'script'
          async: false # make sure updates before page refresh
          # error: (xhr, textStatus, error) ->
          #   displayError "#{textStatus} #{xhr.status} - #{xhr.responseText}"
        clearBeforeUnload() # no longer warn user of changes made before moving off page
        console.log 'Create or Update of SOR.'
      else
        console.log "Create SOR - /section_outcome_ratings/#{id}"
        $.ajax "/section_outcome_ratings/#{id}",
          type: 'put'
          data: {
            source_controller: 'section_outcome_ratings',
            source_action: 'update',
            section_outcome_rating: { rating: rating },
            bulk: bulk_rate
          }
          dataType: 'script'
          async: false # make sure updates before page refresh
          # error: (xhr, textStatus, error) ->
          #   displayError "#{textStatus} #{xhr.status} - #{xhr.responseText}"

    ###################################
    # EVIDENCE RATING POSITIONED POPUP

    # click on evidence cell to bring up single evidence rating popup
    evidenceCellClick = (that, ev) ->
      console.log 'evidenceCellClick'
      clearErrors()
      checkPriorityEvents(ev)
      # clear all popups
      clearAllPopups(ev)
      # get the id of the esor from the data-id attribute
      esor_student_id = $(that).data('student-id')
      console.log 'esor_student_id: '+esor_student_id
      parent_row = $(that).parents('tr')
      eso_id = parent_row.data('eso-id')
      console.log 'eso_id: '+eso_id
      esor_id = $(that).data('id')
      console.log 'esor_id: '+esor_id
      esor_comment = $(that).data('comment')
      rating = $(that).data('rating')
      console.log 'rating: '+rating
      eso_reassess = parent_row.find('.tracker-firstcol .tracker-cell-title span.reassess-icon').length
      console.log 'eso_reassess: '+eso_reassess
      reassess = (eso_reassess > 0 && !!rating) ? true : false
      console.log 'reassess: '+reassess
      # highlight the current cell
      $(that).parent().addClass('highlight-cell')
      # fill out the data in the popup
      puRate1Evid.find('li.active').removeClass('active')
      switch rating
        when 'B' then puRate1Evid.find('li.blue').addClass('active')
        when 'G' then puRate1Evid.find('li.green').addClass('active')
        when 'Y' then puRate1Evid.find('li.yellow').addClass('active')
        when 'R' then puRate1Evid.find('li.red').addClass('active')
        when 'M' then puRate1Evid.find('li.missing').addClass('active')
        when 'U' then puRate1Evid.find('li.unrated').addClass('active')
        else puRate1Evid.find('li.empty').addClass('active')
      if typeof esor_comment == undefined
        puRate1Evid.find('textarea').val('')
      else
        puRate1Evid.find('textarea').val(esor_comment)
      puRate1Evid.find('#reassess-flag').prop('checked', reassess)
      # save the ID of this esor in the popup (for popup handling)
      puRate1Evid.data('id', esor_id)
      # save the student ID of this esor in the popup (for popup handling)
      puRate1Evid.data('student-id', esor_student_id)
      # save the eso ID of this esor in the popup (for popup handling)
      puRate1Evid.data('eso-id', eso_id)
      # save the esor ID of this esor in the popup (for popup handling)
      puRate1Evid.data('esor-id', esor_id)
      # save the reassessment flag of this evidence in the popup (for popup handling)
      puRate1Evid.data('reassess', reassess)
      # save the comment of this esor in the popup (for popup handling)
      puRate1Evid.data('comment', esor_comment)
      bulk_rate = $(that).parents('.tbody-section').hasClass('bulk-rate')
      if bulk_rate
        puRate1Evid.addClass('bulk-rate')
      else
        puRate1Evid.removeClass('bulk-rate')
      console.log 'bulk_rate: '+bulk_rate
      # turn off evidence hovers
      turn_off_comment_hover()
      # set the position and display the dialog
      positionDialog(puRate1Evid, that)
      if eso_reassess
        $('#reassess-fields').show()
      else
        $('#reassess-fields').hide()
      ev.stopPropagation()
      return

    # record rating click on single evidence popup
    # does not close popup, update database or have cell updated
    setEvidenceRating = (that, ev) ->
      # checkPriorityEvents(ev) # dont check events, still in popup
      console.log 'setEvidenceRating'
      clearErrors()
      # $('table.tracker-table td.highlight-cell').removeClass('highlight-cell')
      selected_rating = $(that).data('selection')
      console.log 'selected_rating: '+selected_rating
      $(that).parents('ul').find('li.active').removeClass('active')
      $(that).parents('li').addClass('active')
      setEvidPopupChanged(that, ev)
      return

    # flag evidence popup as changed
    setEvidPopupChanged = (that, ev) ->
      if puRate1Evid.hasClass('bulk-rate')
        console.log 'set bulk_evid_changed = true'
        bulk_evid_changed = true
      ev.stopPropagation() # make sure click is not captured (and updated yet)

    # handle rating click on single evidence popup
    # close popup, update database, have cell updated
    saveEvidenceRating = (that, ev) ->
      console.log 'saveEvidenceRating'
      clearErrors()
      checkPriorityEvents(ev)
      onlySaveEvidenceRating(ev)
      # clearAllPopups(ev)
      turn_on_comment_hover(ev)
      puRate1Evid.hide()
      $('table.tracker-table td.highlight-cell').removeClass('highlight-cell')
      ev.stopPropagation()


    onlySaveEvidenceRating = (ev) ->
      console.log 'onlySaveEvidenceRating'
      clearErrors()
      # $('table.tracker-table td.highlight-cell').removeClass('highlight-cell')
      # selected_rating = $(that).data('selection')

      comment = puRate1Evid.find('#popup-comment').val()
      console.log 'comment: '+comment
      selected_student_id = puRate1Evid.data('student-id')
      console.log 'selected_student_id: '+selected_student_id
      selected_eso_id = puRate1Evid.data('eso-id')
      console.log 'selected_eso_id: '+selected_eso_id
      selected_esor_id = puRate1Evid.data('esor-id')
      console.log 'selected_esor_id: '+selected_esor_id
      selected_id = puRate1Evid.data('id')
      console.log 'selected_id: '+selected_id
      cell_section = $(".tbody-section[data-eso-id='#{selected_eso_id}']")
      console.log "cell_section.length = #{cell_section.length}"
      cell_evidence_row = $("tr[data-eso-id='#{selected_eso_id}']")
      original_cell = cell_evidence_row.find("[data-student-id='#{selected_student_id}']")
      # original_cell = cell_section.find("[data-student-id='#{selected_student_id}']")
      # original_cell = $("[data-id='#{selected_id}']")
      console.log "original_cell.data('rating') = #{original_cell.data('rating')}"
      console.log "original_cell.data('comment') = #{original_cell.data('comment')}"
      eso_reassess = original_cell.parents('tr').find('.tracker-firstcol .tracker-cell-title span.reassess-icon').length
      console.log 'eso_reassess: '+eso_reassess
      reassess = puRate1Evid.find('#reassess-flag').prop('checked')
      console.log "reassess = #{reassess}"
      number_selected = puRate1Evid.find('li.active a').length
      console.log 'number_selected: '+number_selected
      if number_selected == 0
        if reassess
          # set the default rating if this student is to be reassessed
          selected_rating = 'U'
      else
        if eso_reassess && !reassess
          # clear the rating if the student is not to be reassessed on reassessment
          selected_rating = null
        else
          selected_rating = puRate1Evid.find('li.active a').data('selection')
      console.log 'selected_rating: '+selected_rating
      changed = false
      changed = true if original_cell.data('rating') != selected_rating
      changed = true if original_cell.data('comment') != comment
      console.log "changed = #{changed}"

      if changed
        # Update changed comment, rating or reassessment flag
        if puRate1Evid.hasClass('bulk-rate')
          console.log 'change individual rating in bulk rating page'
          setBeforeUnload() # warn user of changes made before moving off page
          # sor created, update display
          original_cell.data('changed', true)
          original_cell.data('rating', selected_rating)
          console.log "changed flag = #{changed} = #{original_cell.data('changed')}"
          console.log "updated rating = #{selected_rating} = #{original_cell.data('rating')}"
          if typeof comment == 'undefined'
            comment = ''
          if comment == ''
            original_cell.data('comment', '')
            original_cell.removeClass('commented')
          else
            original_cell.data('comment', comment)
            original_cell.addClass('commented')
          window.trackerCommonCode.updateEvidenceCellRating(original_cell, selected_rating)
        else
          console.log 'process as single rate with update'
          createUpdateEsor(selected_id, selected_student_id, selected_eso_id, selected_rating, comment, false)


    # Bulk Update all ratings for all students for Evidence
    saveAllEvid = (that, ev) ->
      # $('#modal_waiting').modal({keyboard: false}) # not working
      console.log 'saveAllEvid'
      clearErrors()
      checkPriorityEvents(ev)
      changed_elements = $(".evid-cell > .esor") #[data-changed='true'] this does not work properly ??
      console.log "changed_elements.length = #{changed_elements.length}"
      changed_elements.each (i, elem) ->
        element = $(elem)
        console.log "changed = #{element.attr('data-changed')},  #{element.prop('data-changed')}, #{element.data('changed')}"
        if element.data('changed')
          esor_id = element.data('id')
          esor_student_id = element.data('student-id')
          esor_eso_id = element.parents('tr').data('eso-id')
          rating = element.data('rating')
          comment = element.data('comment')
          createUpdateEsor(esor_id, esor_student_id, esor_eso_id, rating, comment, true)
        return
      clearBeforeUnload() # no longer warn user of changes made before moving off page
      # console.log 'saveAllEvid done'
      # go back to tracker page for current section_id
      subsection_val = $('#subsection-select').val()
      console.log 'subsection_val: '+subsection_val
      if subsection_val
        subsection_qs = "?subsection=#{subsection_val}"
      else
        subsection_qs = ""
      console.log 'saveAllEvid done'
      # go back to tracker page for current section_id
      window.location.href = "/sections/#{$('#tracker-header').data('section-id')}.html"+subsection_qs

    # update esor called from onlySaveEvidenceRating
    createUpdateEsor = (selected_id, selected_student_id, selected_eso_id, selected_rating, comment, bulk_rate) ->
      console.log "createUpdateEsor id= #{selected_id}, student_id= #{selected_student_id}, eso_id= #{selected_eso_id}, rating= #{selected_rating}, comment= #{comment}, bulk_rate= #{bulk_rate}"
      if (typeof selected_id == 'undefined')
        # dont update anything that is undefined
      else if selected_rating == ''
        #don't bother to update rating, there was and still is none
      else if ''+selected_id == '0'
        $.ajax "/e_s_o_r",
          type: 'post'
          data: {
            source_controller: 'evidence_section_outcome_ratings',
            source_action: 'create',
            evidence_section_outcome_rating: { student_id: selected_student_id, evidence_section_outcome_id: selected_eso_id, rating: selected_rating, comment: comment },
            bulk: bulk_rate
          }
          dataType: 'script'
          async: false # make sure updates before page refresh
      else
        $.ajax "/e_s_o_r/#{selected_id}",
          type: 'put'
          data: {
            source_controller: 'evidence_section_outcome_ratings',
            source_action: 'update',
            evidence_section_outcome_rating: { rating: selected_rating, comment: comment },
            student_id: selected_student_id,
            bulk: bulk_rate
          }
          dataType: 'script'
          async: false # make sure updates before page refresh


    ###################################
    # UTILITY FUNCTIONS (ERROR HANDLING, ...)

    # Display an error
    displayError = (err_msg) ->
      err_element.html("<span class='flash_error'>#{err_msg}</span>")

    # Clear the errors
    clearErrors = () ->
      err_element.html("<span></span>")


    ###################################
    # BULK LEARNING OUTCOME RATING PROCESSING

    # Selected rating for Bulk ratings
    setBatchDefaultLo = (that, ev) ->
      console.log 'setBatchDefaultLo'
      clearErrors()
      checkPriorityEvents(ev)
      $(that).parent().find('td.bulk-rate.active').removeClass('active')
      $(that).addClass('active') if $(that).hasClass('bulk-rate')
      ev.stopPropagation()

    setBatchDefaultEvid = (that, ev) ->
      console.log 'setBatchDefaultEvid'
      clearErrors()
      checkPriorityEvents(ev)
      $(that).parent().find('td.bulk-rate.active').removeClass('active')
      $(that).addClass('active') if $(that).hasClass('bulk-rate')
      ev.stopPropagation()


    # Apply selected rating to all unrated students for LO
    setBatchApplyToUnratedLo = (that, ev) ->
      console.log 'setBatchApplyToUnratedLo'
      clearErrors()
      checkPriorityEvents(ev)
      console.log 'check for selection'
      active_selection = $('#batch-rating').find('td.active')
      console.log "active_selection.length = #{active_selection.length}"
      switch active_selection.length
        when 0
          displayError('ERROR: Missing Selected Rating.')
        when 1
          new_rating = active_selection.data('rate')
          sor_cells = $('.s_o_r')
          console.log 'sor_cells.length = '+sor_cells.length
          if new_rating == 'S'
            console.log 'copy selected evidence rating to all.'
            # evid_cells = $("[name='evid_selector']:checked").parent().find('td.evid-cell a i')
            evid_cells_p = $("[name='evid_selector']:checked").parents('tr')
            console.log 'evid_cells_p.length = '+evid_cells_p.length
            console.log 'evid_cells_p.prop(tagName) = '+evid_cells_p.prop('tagName')
            evid_cells = evid_cells_p.find('td.evid-cell a i')
            console.log 'evid_cells.length = '+evid_cells.length
            if sor_cells.length == evid_cells.length
              console.log "matching cell copy length"
              len = evid_cells.length
              for i in [0...len]
                evid_cell = $(evid_cells[i])
                sor_cell = $(sor_cells[i])
                if sor_cell.hasClass('unrated')
                  # copy evidence value for student if currently unrated (even if reassess!)
                  console.log("sor_cell is unrated")
                  if evid_cell.hasClass('text-blue2')
                    window.trackerCommonCode.updateLoCellRating(sor_cell, 'H')
                  else if evid_cell.hasClass('text-green2')
                    window.trackerCommonCode.updateLoCellRating(sor_cell, 'P')
                  else if evid_cell.hasClass('text-yellow2') || evid_cell.hasClass('text-red2')
                    window.trackerCommonCode.updateLoCellRating(sor_cell, 'N')
                  else
                    window.trackerCommonCode.updateLoCellRating(sor_cell, 'U')
            else
              console.log 'mismatched lengths'
          else
            console.log 'apply selected rating to all.'
            console.log 'new rating is: '+new_rating
            sor_cells.each (i, elem) ->
              update_rate = ($(elem).hasClass('unrated')) ? true : false
              if update_rate
                window.trackerCommonCode.updateLoCellRating($(elem), new_rating)
              return
        else
          displayError('ERROR: Too Many Ratings Selected !!')
      ev.stopPropagation()


    # unrate all students for LO
    unrateAllLo = (that, ev) ->
      console.log 'unrateAllLo'
      clearErrors()
      checkPriorityEvents(ev)
      sor_cells = $('.s_o_r')
      console.log 'sor_cells.length = '+sor_cells.length
      sor_cells.each (i, elem) ->
        window.trackerCommonCode.updateLoCellRating($(elem), 'U')
      ev.stopPropagation()


    # Bulk Update all ratings for all students for LO
    saveAllLo = (that, ev) ->
      # $('#modal_waiting').modal({keyboard: false}) # not working
      console.log 'saveAllLo count: '+$('s_o_r').length
      clearErrors()
      checkPriorityEvents(ev)
      $('.s_o_r').each (i, elem) ->
        element = $(elem)
        sor_id = element.data('id')
        sor_student_id = element.data('student-id')
        sor_so_id = element.data('so-id')
        rating = element.data('rating')
        createUpdateSor(sor_id, sor_student_id, sor_so_id, rating, true)
        return
      clearBeforeUnload() # no longer warn user of changes made before moving off page
      # clearAllPopups(ev)
      subsection_val = $('#subsection-select').val()
      console.log 'subsection_val: '+subsection_val
      if subsection_val
        subsection_qs = "?subsection=#{subsection_val}"
      else
        subsection_qs = ""
      console.log 'saveAllLo done'
      # go back to tracker page for current section_id
      window.location.href = "/sections/#{$('#tracker-header').data('section-id')}.html"+subsection_qs


    ###################################
    # BULK EVIDENCE RATING PROCESSING

    # Selected rating for Bulk ratings
    setBatchDefaultEvid = (that, ev) ->
      console.log 'setBatchDefaultEvid'
      clearErrors()
      checkPriorityEvents(ev)
      $(that).parent().find('td.bulk-rate.active').removeClass('active')
      $(that).addClass('active') if $(that).hasClass('bulk-rate')
      ev.stopPropagation()


    # Apply selected rating to all students for Evidence
    setBatchApplyToUnratedEvid = (that, ev) ->
      console.log 'setBatchApplyToUnratedEvid'
      clearErrors()
      checkPriorityEvents(ev)
      eso_reassess = $('#tracker-header').data('reassessment')
      console.log "eso_reassess = #{eso_reassess}"
      active_selection = $('#batch-rating-evid td.active')
      switch active_selection.length
        when 0
          displayError('ERROR: Missing Selected Rating.')
        when 1
          selected_los = $('input.select-so:checkbox:checked')
          console.log "checked #{selected_los.length} learning outcomes"
          if selected_los.length == 0
            displayError('ERROR: No Learning Outcomes selected to apply to.')
          else
            new_rating = active_selection.data('rate')
            console.log 'new rating is: '+new_rating
            selected_los.each () ->
              console.log "apply selected rating to #{$(this).data('eso-id')}."
              eso_id = $(this).data('eso-id')
              console.log "eso_id = #{eso_id}"
              console.log 'returned ratings to change: '+$("tbody.bulk-rate[data-eso-id='#{eso_id}'] a.esor").length
              $("tbody.bulk-rate[data-eso-id='#{eso_id}'] a.esor").each (i, elem) ->
                rating = $(elem).data('rating')
                if eso_reassess
                  console.log "eso_reassess is true"
                  update_rate = (rating == 'U') ? true : false
                else
                  console.log "eso_reassess is false"
                  update_rate = (rating == 'U' || rating == '') ? true : false
                if update_rate
                  window.trackerCommonCode.updateEvidenceCellRating($(elem), new_rating)
        else
          displayError('ERROR: Too Many Ratings Selected')
      ev.stopPropagation()


    # unrate all all students for Evidence of selected LOs
    unrateAllEvid = (that, ev) ->
      console.log 'unrateAllEvid'
      clearErrors()
      checkPriorityEvents(ev)
      eso_reassess = $('#tracker-header').data('reassessment')
      console.log "eso_reassess = #{eso_reassess}"
      selected_los = $('input.select-so:checkbox:checked')
      console.log "checked #{selected_los.length} learning outcomes"
      if selected_los.length == 0
        displayError('ERROR: No Learning Outcomes selected to apply to.')
      else
        selected_los.each () ->
          console.log "apply selected rating to #{$(this).data('eso-id')}."
          eso_id = $(this).data('eso-id')
          console.log "eso_id = #{eso_id}"
          console.log 'returned ratings to change: '+$("tbody.bulk-rate[data-eso-id='#{eso_id}'] a.esor").length
          $("tbody.bulk-rate[data-eso-id='#{eso_id}'] a.esor").each (i, elem) ->
            rating = $(elem).data('rating')
            console.log "rating = #{rating}"
            console.log "(rating == '') = #{(rating == '')}"
            update_rate = false
            if !eso_reassess
              update_rate = true
            else if rating != ''
              update_rate = true
            console.log "update_rate = #{update_rate}"
            if update_rate
              window.trackerCommonCode.updateEvidenceCellRating($(elem), 'U')
      ev.stopPropagation()

    selectAllLos = (that, ev) ->
      console.log 'selectAllLos'
      console.log 'that on tag: '+$(that).get(0).tagName
      clearErrors()
      current_state = $(that).prop('checked')
      $('.select-so').prop('checked', current_state)




    #######################################################################
    # Event Handlers & immediate calls to functions
    #######################################################################

    # Toggle table sections on link click
    $(".tbody-header .tracker-cell-title > a").on "click", (event, state) ->
      toggleTableSections(this, event)

    # # Select/Deselect all checkboxes of a tbody-section
    # $(".tbody-header input:checkbox").on 'click', (event, state) ->
    #   tbodyToggleAllCheckboxes(this, event)

    # On previous pagination button click
    gbPgPrev.on "click", (event, state) ->
      previousPagination(this, event)

    # On next pagination button click
    gbPgNext.on "click", (event, state) ->
      nextPagination(this, event)

    # Set mini, midi or max cell size mode, display page, and disable/enable prev next.
    trSetThinnerMode.on 'click', (event, state) ->
      setThinnerMode(this)
    trSetThinMode.on 'click', (event, state) ->
      setThinMode(this)
    trSetRegMode.on 'click', (event, state) ->
      setRegMode(this)
    trSetWideMode.on 'click', (event, state) ->
      setWideMode(this)
    trSetWiderMode.on 'click', (event, state) ->
      setWiderMode(this)

    # close popup when clicking on any child element that has a class of close
    $('.popup .close').on "click", (event, state) ->
      clearAllPopups(event)
    # close popup when clicking on any child element that has a class of cancel
    $('.popup .cancel').on "click", (event, state) ->
      clearAllPopups(event)

    $("li.mp-filter").on 'click', (event, state) ->
      loShowHideByMarkingPeriod(this, event)

    $(".tracker-cell-toggle").on 'click', (event, state) ->
      toggleEvidenceShow(this, event)

    $("#collapse-all-los-button").on 'click', (event, state) ->
      collapseAllEvidences(this, event)

    $("#expand-all-los-button").on 'click', (event, state) ->
      expandAllEvidences(this, event)

    $("#subsection-select").on 'change', (event, state) ->
      updateSubsectionDisplay(this, event)


    # ###################################
    # # GENERAL POSITIONED POPUP CODE

    # # not working, probably because button is not getting focus
    # $("#popup-rate-single-evid").on 'keypress', (event, state) ->
    #   submit_popup_on_enter(this, event)


    ###################################
    # COMMENT HOVER CODE

    turn_on_comment_hover()

    ###################################
    # HANDLING CLICKS OUTSIDE OF POSITIONED POPUP

    # Click not captured by any event.  clear popups just in case.
    $(document).click (event) ->
      clickOutOfDialog(this, event)


    ###################################
    # SECTION OUTCOME RATING POSITIONED POPUP

    # Click on Section Outcome Rating cell
    $(".s_o_r").on "click", (event, state) ->
      sectionOutcomeCellClick(this, event)

    # Click on a Rating in LO positioned popup
    $("#popup-rate-single-lo > .popup-links a.btn-rate-lo").on "click", (event, state) ->
      setLoRating(this, event)

    # Click on a Save Button in LO positioned popup
    $('#save-single-lo').on 'click', (event, state) ->
      saveLoRating(event)

    # Click on a Cancel Button in Evidence positioned popup
    $('#cancel-bulk-lo').on 'click', (event, state) ->
      cancelLoRating(event)


    ###################################
    # EVIDENCE RATING POSITIONED POPUP

    # Click on Evidence Rating cell
    $(".evid-cell > a.esor").on "click", (event, state) ->
      evidenceCellClick(this, event)
      event.preventDefault()

    # Click on a Rating in Evidence positioned popup
    $("#popup-rate-single-evid > .popup-links a.esor").on "click", (event, state) ->
      setEvidenceRating(this, event)

    $("#popup-rate-single-evid #popup-comment").on "change", (event, state) ->
      setEvidPopupChanged(this, event)

    $("#popup-rate-single-evid #reassess-flag").on "change", (event, state) ->
      setEvidPopupChanged(this, event)

    # $("#popup-rate-single-evid textarea").on "change", ->
    #   console.log '#popup-rate-single-evid textarea changed'
    #   setEvidenceComment(this)

    # Click on a Save Button in Evidence positioned popup
    $('#save-single-evid').on 'click', (event, state) ->
      saveEvidenceRating(this, event)


    ###################################
    # BULK LEARNING OUTCOME RATING PROCESSING

    $('#batch-rating td').on "click", (event, state) ->
      setBatchDefaultLo(this, event)

    $('#apply-bulk-to-unrated-lo').on "click", (event, state) ->
      setBatchApplyToUnratedLo(this, event)

    $('#unrate-all-lo').on "click", (event, state) ->
       unrateAllLo(this, event)

    $('#save-bulk-lo').on "click", (event, state) ->
      saveAllLo(this, event)


    ###################################
    # BULK EVIDENCE RATING PROCESSING

    $('#batch-rating-evid td').on "click", (event, state) ->
      setBatchDefaultEvid(this, event)

    $('#apply-bulk-to-unrated-evid').on "click", (event, state) ->
      setBatchApplyToUnratedEvid(this, event)

    $('#unrate-all-evid').on "click", (event, state) ->
      unrateAllEvid(this, event)

    $('#save-bulk-evid').on "click", (event, state) ->
      saveAllEvid(this, event)

    $('#select_all_los').on 'click', (event, state) ->
      selectAllLos(this, event)






    #######################################################################
    # PAGE INITIALIZATIONS
    #######################################################################

    console.log 'initialize cell size selector default highlight'
    initializeCellSizeSelectors()

    initializeLoDragDrop()

    checkSingleBulkEvid()

    checkSingleBulkLO()


  return



