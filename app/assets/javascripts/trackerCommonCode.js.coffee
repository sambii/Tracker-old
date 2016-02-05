#
#  Document   : tracker_app.js.coffee
#  Description: Code to customize the app.js code
#
# custom code for Tracker Application that can be called from anywhere

# contains the following code:
#
# showPage to calculate and set up student pagination.
#
# resizePageContent to handle Tracker Page resizing.
#        - code to handle position of tracker-table containers on window resizing.
#        - code to handle redisplay after pagination of students.
#
# updateEvidenceCellRating
# - code to do all display changes necessary when changing a rating.
#

# create global variable to place this code within
window.trackerCommonCode = {};

# init code
window.trackerCommonCode.init = ->
  console.log "trackerCommonCode.init called"
  return


# This contains custom code for resizing the page.
# It is called from the ProUI app resizing function (see below for details).
# the proui app.js code (vendor/assets/javascripts/proui-vN.N/app.js)
# must contain the following lines of code when proui version is updated:
#
# 1) The resizePageContent function
#     // custom code for Tracker page resizing
#     window.trackerCommonCode.resizePageContent();
#
# 2) the handleSidebar function, inside the else statement, right after all of the modes are checked.
#     // custom code for Tracker page resizing
#     window.trackerCommonCode.resizePageContent();
#
window.trackerCommonCode.resizePageContent = ->
  # position of tracker-table containers when page resizes.
  trackerPage = $("#page-content.tracker-page")
  if trackerPage.length > 0
    sidebarW = $("#sidebar").outerWidth()
    trackerHeader = $("#tracker-header")
    trackerHeader.css "left", sidebarW
    # update tracker page pagination
    window.trackerCommonCode.showPage 0
  return


# Function for showing specific page of students
# - should be called whenever page is resized, cell widths are changed, or pagination done
window.trackerCommonCode.showPage = (paging) ->
  trTable = $(".tracker-table")
  console.log "showPage called"
  cellWidth = 37
  cellWidth = 27 if trTable.hasClass("thinner-mode")
  cellWidth = 32 if trTable.hasClass("thin-mode")
  cellWidth = 37 if trTable.hasClass("regular-mode")
  cellWidth = 42 if trTable.hasClass("wide-mode")
  cellWidth = 47 if trTable.hasClass("wider-mode")
  trackerPage = $("#page-content.tracker-page")
  trackerTableW = $("#tracker-header").width()
  sidebarW = $("#sidebar").width()
  cellsMaxWidth = trackerTableW - 470
  maxCols = Math.floor(cellsMaxWidth / cellWidth) - 1
  tableCols = 0
  $(".tracker-table thead th").each ->
    tableCols += 1
    return
  i = 2
  firstCol = 0
  wasShownCount = 0
  # What is the first column shown, and number shown
  # console.log "tableCols = #{tableCols}"
  while i < tableCols
    elem = $("th:nth-child(" + i + ")", trTable)
    if elem.css("display") is "table-cell"
      wasShownCount += 1
      firstCol = i if firstCol is 0
    i++
  # pagination calculations
  # console.log "paging = #{paging}"
  if paging == -9999  # go to first page of students
    firstCol = 2
  else if paging < 0 # go to previous page of students
    firstCol -= maxCols
  else if paging > 0 # go to next page of students
    firstCol += wasShownCount
    firstCol = tableCols - maxCols if firstCol + maxCols > tableCols
  firstCol = 2 if firstCol < 2
  # see if we need to update the display
  # console.log "wasShownCount = #{wasShownCount}"
  # console.log "maxCols = #{maxCols}"
  if wasShownCount != maxCols || paging != 0
    # console.log "prepare for loop"
    i = firstCol
    j = 0
    # hide all currently displayed students
    $("tr > th:not(:first), tr > td:not(:first)", trTable).hide()
    # delete all currently displayed students rotated html (hack for safari and chrome not moving them)
    $('th > div.clone', trTable).remove()
    # always show first column
    $(".tracker-firstcol", trTable).show()
    while i < tableCols && i >= firstCol && j < maxCols
      if j < maxCols
        # show the number of columns possible
        $("tr > td:nth-child(" + i + "),  tr > th:nth-child(" + i + ")", trTable).show()
        $("th:nth-child(" + i + ") > div.cloner > div.clone", trTable).clone().appendTo("th:nth-child(" + i + ")", trTable)
        j++
      i++
  # Disable pagination buttons
  gbPgPrev = $("#gb-pg-prev")
  gbPgPrev.parent("li").addClass "disabled"
  gbPgPrev.parent("li").removeClass "disabled"  if firstCol > 2
  gbPgNext = $("#gb-pg-next")
  gbPgNext.parent("li").addClass "disabled"
  gbPgNext.parent("li").removeClass "disabled"  if (firstCol + maxCols) < tableCols
  return

# Function to update an evidence cell after a popup update
window.trackerCommonCode.updateEvidenceCellRating = (cell, new_rating) ->
  console.log "update cell #{$(cell).attr('id')}"
  $(cell).data('changed', true)
  $(cell).data('rating', new_rating)
  console.log "Updated Rating - student ID: #{$(cell).data('student-id')} = #{$(cell).data('rating')}"
  iElem = $(cell).find('i')
  iElem.removeClass('fa-asterisk')
  iElem.removeClass('fa-circle')
  iElem.removeClass('fa-adjust')
  iElem.removeClass('fa-circle-o')
  iElem.removeClass('fa-ban')
  iElem.removeClass('text-blue2')
  iElem.removeClass('text-green2')
  iElem.removeClass('text-yellow2')
  iElem.removeClass('text-red2')
  iElem.removeClass('text-unrated2')
  iElem.removeClass('text-empty2')
  iElem.removeClass('text-missing2')
  switch new_rating
    when 'B'
      console.log 'matched B'
      iElem.addClass('fa-asterisk')
      iElem.addClass('text-blue2')
    when 'G'
      console.log 'matched G'
      iElem.addClass('fa-circle')
      iElem.addClass('text-green2')
    when 'Y'
      console.log 'matched Y'
      iElem.addClass('fa-adjust')
      iElem.addClass('text-yellow2')
    when 'R'
      console.log 'matched R'
      iElem.addClass('fa-circle-o')
      iElem.addClass('text-red2')
    when 'M'
      console.log 'matched M'
      iElem.addClass('fa-ban')
      iElem.addClass('text-unrated2')
    when 'U'
      console.log 'matched U'
      iElem.addClass('fa-circle')
      iElem.addClass('text-missing2')
    else
      console.log 'not matched'
      # leave it empty


window.trackerCommonCode.updateLoCellRating = (original_cell, new_rating) ->
  iElem = $(original_cell)
  console.log 'ID: '+iElem.attr('id')+', original value: '+iElem.data('rating')+', '+iElem.text()+', new value: '+new_rating
  iElem.removeClass('blue')
  iElem.removeClass('green')
  iElem.removeClass('red')
  iElem.removeClass('unrated')
  iElem.data('changed', true)
  iElem.data('rating', new_rating)
  iElem.text(new_rating)
  switch new_rating
    when 'H'
      iElem.addClass('blue')
    when 'P'
      iElem.addClass('green')
    when 'N'
      iElem.addClass('red')
    when 'U'
      iElem.addClass('unrated')

# Initialize app when page loads
$ ->
  window.trackerCommonCode.init()
  console.log "call trackerCommonCode.init"
  return
