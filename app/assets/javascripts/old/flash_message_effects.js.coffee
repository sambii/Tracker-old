$ ->
  if $("#notice").html() == ""
    $("#notice").remove()
  else
    $("#notice").click () ->
      $("#notice").remove()
    $("#notice").delay(5000).fadeOut 1000, () ->
      $("#notice").remove()

  if $("#alert").html() == ""
    $("#alert").remove()
  else
    $("#alert").click () ->
      $("#alert").remove()
    $("#alert").delay(8000).fadeOut 1000, () ->
      $("#alert").remove()