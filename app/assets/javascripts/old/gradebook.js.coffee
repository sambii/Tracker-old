# UJS for data-templates! DOM elements with data_template and json_url attributes will trigger AJAX
# calls and render the appropriate Handlebars templates.
$ ->
  AjaxLoader.initialize()
  chartUJS = new ChartUJS()
  # UJS for select_url
  for select in $("[select_url]")
    populate_select($(select))
  # Datepickers that are loaded at the start...
  $(".datepicker").datepicker({ dateFormat: 'yy-mm-dd'}).val()   #  for yyyy-mon-dd use: 'yy-M-dd'
  $(".datepicker-rusure-submit").datepicker({ dateFormat: 'yy-mm-dd', onSelect: datepicker_rusure_onSelect })
  $("#ui-datepicker-div").hide()
  today = new Date()
  year  = today.getFullYear()
  month = (today.getMonth() + 1).toString()
  month = "0" + month if month.length < 2
  day   = (today.getDate()).toString()
  day   = "0" + day if day.length < 2


  $("body").on "click", "[data_template]", (e) ->
    render_data_template e.currentTarget
  $("body").on "click", ".cloner", (e) ->
    clone(e.currentTarget)
  $("body").on "loaded", "#popup_form", (e) ->
    chartUJS.go()
    target = $(e.currentTarget)
    # UJS for chosen
    $(target).find("[chosen]").chosen()
    # UJS for datepicker
    $(target).find(".datepicker").datepicker({ dateFormat: 'yy-mm-dd'}).val()   #  for yyyy-mon-dd use: 'yy-M-dd'
    $("#ui-datepicker-div").hide()
    today = new Date()
    year  = today.getFullYear()
    month = (today.getMonth() + 1).toString()
    month = "0" + month if month.length < 2
    day   = (today.getDate()).toString()
    day   = "0" + day if day.length < 2
    # UJS for select_url
    for select in $(target).find("[select_url]")
      populate_select($(select))
    # UJS for sel
    for select in $(target).find("[sel]")
      select_option(select)
    for checkbox in $(target).find("input[type=checkbox][toggle_class]")
      $(checkbox).click () ->
        toggle_checkboxes(this)

render_data_template = (target) ->
  # Precompiled templates in templates.js!
  template    = Handlebars.templates[$(target).attr('data_template')]
  json_urls   = $(target).attr('data_url') # Not guaranteed to exist!!
  if json_urls?
    json_urls = json_urls.split(" ")
    i = 0
    cumulative_data = {}
    # Make JSON request.
    for json_url in json_urls
      $.getJSON "/#{json_url}", (data) ->
        $.extend cumulative_data, data
        i += 1
        if i == json_urls.length
          rendered = template(cumulative_data)
          render_popup rendered
  else
    # Render template without making a request to the server.
    rendered = template()
    render_popup rendered

window.render_popup = (rendered) ->
  rendered_id = $(rendered).attr('id')
  boxy()
  $("#popup_form").remove() if $("#popup_form")
  $('body').append $(rendered)

  # Move the DIV to the center of the screen
  div_width = parseInt($("##{rendered_id}").css('width'), 10)
  window_width = $(window).width()
  left_position = (window_width - div_width) / 2
  $("##{rendered_id}").css('left', "#{left_position}px")

  # Shadows, fading!
  cssSandpaper.setBoxShadow(document.getElementById(rendered_id), "5px 5px 15px #333")
  $("##{rendered_id}").fadeIn '100'

  # Set listener to remove DIV if area outside of form is clicked or if the form is submitted.
  $("##{rendered_id} > form:not([data-remote]").submit () ->
    if $.isEmptyObject(validator.errors)
      $('#boxy').remove()
      $("##{rendered_id}").hide "fade", {}, 200, () ->
        $(this).remove()

  $("form[data-remote]").live "submit", () ->
    $("input[type=submit]").attr("disabled", "disabled")
    $("input[type=submit]").attr("value", "Submitting. Please wait...")

  $("##{rendered_id} > form[data-remote]").live "ajax:complete", () ->
    $('#boxy').remove()
    $("##{rendered_id}").hide "fade", {}, 200, () ->
    $(this).remove()

  $("##{rendered_id}").trigger('loaded', this)  # Trigger a custom event so that any UJS can be activated for the form elements.

# UJS for a button for cloning a previous element. The button is created by giving it a class
# of 'cloner' and a 'clone_type' attribute. The element selector is specified by the
# clone_type attribute. It *should* accept any valid jQuery selector.
clone = (target) ->
  parent_type = ""
  clone_type = $(target).attr('clone_type')
  if $(target).attr("parent_type") != undefined
    parent_type = $(target).attr('parent_type')
  if parent_type == ""
    b = $(target).prevAll(clone_type + ":first").clone()
  else
    b = $($(target).parents(parent_type)[0]).prevAll(clone_type + ":first").clone()
  if $(b).attr('type') == 'text'
    $(b).val('')
  $(b).find('input[type=text]').attr('value', '')
  a = $("<div></div>").append(b).html()
  # $('<br>').insertBefore(target) unless $(target).prev('br').length > 0
  a    = a.replace /([_\[])(\d+)([_\]])/gi, (match, a, b, c) ->
    d = (Number) b                    # Use a regex to increment numbers as appropriate. i.e.)
    d++                               # _0_ & [0] are incremented to _1_ & [1]
    a + d + c                         # Other numbers are left alone!
  if parent_type == ""
    $(a).insertBefore(target)           # Insert the modified clone after the element we are duplicating.
  else
    $(a).insertBefore($(target).parents(parent_type)[0])

toggle_checkboxes = (checkbox) ->
  toggle_class = $(checkbox).attr('toggle_class')
  if toggle_class.length > 0
    if $(checkbox).is(":checked")
      $("input.#{toggle_class}[type=checkbox]").attr('checked', true)
    else
      $("input.#{toggle_class}[type=checkbox]").attr('checked', false)

datepicker_rusure_onSelect = (dateInput, inst) ->
  ok = confirm('Are you sure you want to change the date?  Note: any changes not saved will be lost.')
  if ok
    $(this).parent().parent().submit()
