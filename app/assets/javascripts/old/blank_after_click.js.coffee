$ ->
  $(".blank_on_click").on "click", (e) ->
    # blank out the page to let the user know we are done with it
    # apparently no assets can load in the middle of a link click.
    $('#wrapper').html('')

