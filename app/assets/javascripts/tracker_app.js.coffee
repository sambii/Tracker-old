# dom_ready.js.coffee
#
# DOM ready initialization javascript

# This contains the javascript handling for DOM element click to go to a controller#action
#
# 1) To have the controller action generate a modal popup from a dom element:
# - { data: {url: "/<pathToController>/<action>.js", toggle: 'modal', target: '#modal_popup'}
# - have a <action>.js.erb view that contains:
#   $('#modal_content').html("<%= escape_javascript(render('<name_of_view>._file') ) %>");
# - have a _<name_of_view>.haml file to populate the dialog box

$(document).ready ->

  # data-url and data_url to make an ajax call to controller/method
  $("[data-url]").click (e) -> data_url_click(e, this) # make ajax call for standard data-url
  $("[data-url]").css('cursor','pointer') # put pointer on element to indicate it is clickable
  $('.pointer-cursor').css('cursor','pointer')
  $('.arrow-cursor').css('cursor', 'default')


  $(document).ajaxError (event, xhr, settings, error) ->
    console.log "on document ajaxError xhr.status: "+xhr.status
    console.log "on document ajaxError xhr.statusText: "+xhr.statusText
    console.log "on document ajaxError error: "+error
    # console.log "on document ajaxError xhr.responseText: "+xhr.responseText
    # console.log "on document ajaxError settings.url: "+settings.url
    # $("#modal-message").after "<p>#{xhr.textStatus} #{xhr.status} - #{xhr.responseText} </p>"
    # close out dialog box in case it is open
    $('#modal_popup').modal('hide')
    $('#breadcrumb-flash-msgs').html("<span class='flash_error'>#{xhr.textStatus} #{xhr.status} - #{xhr.responseText} #{error}</span>")
    if xhr.status == 401
      window.location.href = "/?unauthorized_alert="+encodeURIComponent('Your session timed out or you are unauthorized to access this page.')
    return false


data_url_click = (ev, that) ->
  # stop further processing (don't follow link, ...)
  ev.preventDefault()
  # make an ajax call to the data-url
  data_url = $(that).data('url')
  $.ajax(data_url)

# set_popup_message = () ->
#   # $('#modal-message').append("<p>This is an error!</p>")




