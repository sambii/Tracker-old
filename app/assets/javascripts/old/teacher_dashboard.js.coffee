$ ->
  $("ul#active_sections").sortable({
    axis: 'y',
    update: (event, ui) ->  sort_update('section', ui)  # Called if the order is changed at the end of the sort.
  })

sort_update = () ->
  teacher_id = $("#teacher_dashboard").attr('teacher_id')
  section_ids = ($(child).attr('id').replace("section_", "") for child in $("#active_sections").children())
  $.get "/sections/sort", {teacher_id: teacher_id, 'sections[]': section_ids}, () ->