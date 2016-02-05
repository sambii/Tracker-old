# Javascript for sorting Learning Outcomes by dragging and dropping.
$ ->
  $('div#grades_left').sortable({
    axis: 'y',
    handle: 'thead',
    opacity: 0.7,
    change: (event, ui) ->  sort_change(ui),        # Called each time the DOM order changes.
    sort: (event, ui) ->    sort_sort(ui),          # Called constantly while being dragged.
    start: (event, ui) ->   sort_start(ui),         # Called when the element is dragged 1 pixel or more.
    stop: (event, ui) ->    sort_stop(ui),          # Called when the user stops dragging.
    update: (event, ui) ->  sort_update('s_o', ui)  # Called if the order is changed at the end of the sort.
  })

# Javascript for Sorting evidences.
$ ->
  $("#grades_left > table.section_outcome > tbody").sortable({
    axis: 'y',
    opacity: 0.7,
    change: (event, ui) -> sort_change(ui),     # Called each time the DOM order changes.
    sort: (event, ui) ->    sort_sort(ui),      # Called constantly while being dragged.
    start: (event, ui) ->   sort_start(ui),     # Called when the element is dragged 1 pixel or more.
    stop: (event, ui) ->   sort_stop(ui),       # Called when the user stops dragging.
    update: (event, ui) -> sort_update('e', ui) # Called if the order is changed at the end of the sort.
  })

# Callback for #grades_left sortable event.
sort_change = (ui) ->
  # .sortable() moves around the placeholder (which has no ID!) rather than the helper;
  # because of this, we have to apply the helper's ID to the placeholder's position in the
  # DOM so that we can synchronize the corresponding grades#right tables! The current
  # implementation will leave one array element as undefined due to the unless clause. That
  # has to be accounted for when reordering the grades#right tables.
  #
  # Determine appropriate order:
  container = $(ui.placeholder).parent()
  right_container_id = $(container).attr('id').replace("left", "right")
  right_table_ids = for child in $(container).children()
    if $(child).attr('id')?
      right_id = $(child).attr('id').replace("left", "right")
      right_id unless right_id == $(ui.helper).attr('id').replace("left", "right")
    else
      right_id = $(ui.helper).attr('id').replace("left", "right")
  sort_right_side(right_container_id, right_table_ids)

# Callback for #grades_left sortable event.
# Creates a clone of the corresponding #grades_right table and makes the original invisible
# for the duration of the sorting.
sort_start = (ui) ->
  right_element_id = $(ui.helper).attr('id').replace("left", "right")
  right_element = $("##{right_element_id}")
  $(right_element).css('opacity', 0)
  right_helper = $("##{right_element_id}").clone()
  $(right_helper).attr('id', $(right_helper).attr('id').replace('right', 'right_helper'))
  $(right_helper).css({
    opacity: 0.7,
    position: 'absolute',
    left: '485px'
  })
  right_helper.appendTo('body')

# Callback for #grades_left sortable event.
# Keeps the grades_right table's position in sync.
sort_sort = (ui) ->
  right_helper_id = $(ui.helper).attr('id').replace("left", "right_helper")
  $("##{right_helper_id}").css('top', ui.position.top + 172)

# Callback for #grades_left sortable event.
sort_stop = (ui) ->
  right_helper_id  = $(ui.item).attr('id').replace("left", "right_helper")
  right_element_id = $(ui.item).attr('id').replace("left", "right")
  $("##{right_helper_id}").remove()
  $("##{right_element_id}").css('opacity', 1)

# Callback for #grades_left sortable event.
# Sends request to server to persist the sort.
sort_update = (request_type, ui) ->
  if request_type == 's_o'
    section_id = $("#tools").attr('section_id')
    section_outcome_ids = ($(child).attr('id').replace("section_outcome_table_left_", "") for child in $("#grades_left").children())
    $.get "/section_outcomes/sort", {'section_id': section_id, 'section_outcomes[]': section_outcome_ids},() ->
  if request_type == 'e'
    section_outcome_id = $(ui.item).parent().attr('id').replace("section_outcome_evidences_left_", "")
    evidence_section_outcome_ids = ($(child).attr('id').replace("evidence_left_row_", "") for child in $(ui.item).parent().children())
    $.get "/evidence_section_outcomes/sort", {section_outcome_id: section_outcome_id, 'evidence_section_outcomes[]': evidence_section_outcome_ids}, () ->

# Called by outcome_sort_update and outcome_sort_change.
# Detaches the tables in grades#right and reattaches them in the appropriate order.
# Has to evaluate whether the elements of the array are all defined because the current
# implementation of outcome_sort_change will always pass one undefined element.
sort_right_side = (right_container_id, right_table_ids) ->
  right_table_array = $("##{right_container_id}").children().detach()
  right_tables = {}
  (right_tables[$(table).attr('id')] = table for table in right_table_array)
  right_table_array = null
  for right_table_id in right_table_ids
    if right_table_id?
      $("##{right_container_id}").append(right_tables[right_table_id])
  right_tables = null

