$ ->
  $("div.progress").each () ->
    total_width = $(this).width()
    total_count = 0 # Used to hold the count of total ratings.
    $(this).children("div.progress_bar").each () ->
      total_count += parseInt($(this).attr('count'))
    if total_count > 0
      $(this).children("div.progress_bar").each () ->
        percentage = parseFloat($(this).attr('count') / total_count)
        $(this).width(percentage * total_width)
        $(this).tooltip(title: "#{Math.round(percentage * 100)}% #{$(this).attr('rating')}")