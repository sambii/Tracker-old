$ ->
  $("span.section_outcome_x").click (e) ->
    remove_section_outcome(e.currentTarget);
  $("span.evidence_x").live "click", (e) ->
    remove_evidence(e.currentTarget);

remove_section_outcome = (target) ->
  section_outcome_id = $(target).parents("table").attr('id').replace("section_outcome_table_left_", "")
  $.ajax({
    url: "/section_outcomes/#{section_outcome_id}.js",
    data: {
      section_outcome: {active: 'false'}
    },
    type: 'put'
    success: () ->
      right_id = $(target).parents("table").attr('id').replace("left", "right")
      $(target).parents("table").fadeOut 500, () ->
        $(target).parents("table").remove()
      $("##{right_id}").fadeOut 500, () ->
        $("##{right_id}").remove()
  })

remove_evidence = (target) ->
  controller = $("#current_controller").html()
  action     = $("#current_action").html()
  evidence_id = $(target).siblings(".evidence_name").attr('data_url').replace("evidences/","").replace("/rate.json", "")
  $.ajax({
    url: "/evidences/#{evidence_id}.js",
    data: {
      evidence: {active: 'false' },
      source_controller: controller,
      source_action: action
    },
    type: 'put',
    success: () ->
      for span in $("span.evidence_name[data_url*='#{evidence_id}']")
        right_id = $(span).parents('tr').attr('id').replace('left', 'right')
        $(span).parents('tr').fadeOut 500, () ->
          $(span).parents('tr').remove()
        $("##{right_id}").fadeOut 500, () ->
          $("##{right_id}").remove()
  })
