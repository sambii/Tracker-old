window.boxy = () ->
  unless $('#boxy').length
    $("<div id='boxy'></div>").css({
      backgroundColor: '#333',
      bottom:   '0',
      height:   '100%',
      position: 'fixed',
      opacity:  '0.6',
      top:      '0',
      width:    '100%',
      zIndex:   '11'
    }).appendTo($('body'))
    $('#boxy').click () ->
      if $("#popup_form").attr('confirm_exit')
        if confirm("Are you sure you want to close this form?")
          $(this).remove()
          $("#popup_form").remove()
      else
        $(this).remove()
        $("#popup_form").remove()