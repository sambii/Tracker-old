# Chosen Dropdown --- Pop out of box!
$ -> $(".chzn-done").live "liszt:showing_dropdown", () ->
  dropdown_id = $(this).attr('id') + "_chzn"
  top   = $("##{dropdown_id}").position().top + 24
  left  = $("##{dropdown_id}").offset()['left'] - $(window).scrollLeft();
  $("##{dropdown_id} > .chzn-drop").css({
    display: 'inline',
    left: left + "px",
    position: 'fixed',
    top: top + "px",
    zIndex: 99
  })

window.populate_select = (target) ->
  # Pull attributes from the select element.
  url       = $(target).attr('select_url')
  node      = $(target).attr('node')
  if typeof(url)      == "undefined"
    url       = ""
  if typeof(node)     == "undefined"
    node      = ""

  if $(target).attr('dependent_on')
    parent = $(target).attr('dependent_on')
    url = url.replace(/\$value\$/g, $("##{parent}").val())
  $.get "/#{url}.json", (data) ->
    if node != ""
      data = data[node]
    target_html = ""
    for datum in data
      target_html += ("<option value='#{datum.id}'>#{datum.name}</option>" )
    $(target).html(target_html)
    $(target).trigger('change')
    if $(target).attr('sel')
      $(target).val($(target).attr('sel'))

window.select_option = (target) ->
  if $(target).attr('sel')
    $(target).val($(target).attr('sel'))

$ ->
  $("select").live "change", (event) ->
    target = event.currentTarget
    target_id = $(target).attr('id')
    for select in $("select[dependent_on=\"#{target_id}\"]")
      populate_select(select)