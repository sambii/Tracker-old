  # This code provides general error handling for ajax events.
  # To be specific, it captures ajax error/success events, then displays 
  # *something* to the user. This was added because there was no 
  # notification when ajax requests failed.
  
  $(document).ajaxError () ->
    $('#alert').html("<%= escape_javascript(flash[:alert]) %>")

  $(document).ajaxSuccess () ->
    $('#notice').html("<%= escape_javascript(flash[:notice]) %>")

  