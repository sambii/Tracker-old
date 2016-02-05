# UJS and accompanying functions for updating the marking periods associated with a
# learning outcome. Rather than using the 'on' or 'live' jQuery library, we'll manually
# hook and unhook event handlers. It should provide better performance.
# TODO Go back and refactor other jQuery 'live' event handlers?
$ ->
  $("span.include_mp").click (event) -> toggle_mp_off(event)
  $("span.exclude_mp").click (event) -> toggle_mp_on(event)


toggle_mp_off = (event) ->
  target = event.currentTarget
  if $(target).parent().children(".include_mp").length > 1
    $(target).off('click')
    $(target).attr('class', 'exclude_mp')
    $(target).click (event) -> toggle_mp_on(event)
    update_section_outcome(target)
  else
    alert('Each Outcome must have at least one marking period.')

toggle_mp_on  = (event) ->
  target = event.currentTarget
  $(target).off('click')
  $(target).attr('class', 'include_mp')
  $(target).click (event) -> toggle_mp_off(event)
  update_section_outcome(target)

update_section_outcome = (target) ->
  included_marking_periods = ($(child).html() for child in $(target).parent().children(".include_mp"))
  section_outcome_id = $(target).parent().siblings('.section_outcome_name').attr('id').replace('section_outcome_','')
  $.ajax {
    url:"/section_outcomes/#{section_outcome_id}.js",
    data: {"mp[]": included_marking_periods},
    type: 'put'
  }
