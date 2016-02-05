window.AjaxLoader = {
  cssAttributes: {
    "background-color": "white",
    "background-image": "url('/assets/ajax.gif')",
    "background-repeat": "no-repeat",
    "background-position": "center",
    "height": "48px",
    "opacity": "0.9"
    "position": "fixed",
    "border-radius": "8px",
    "width": "48px",
    "z-index": "14"
  }

  initialize: () ->
    $('body').append("<div id='loading_div'></div>")
    $("#loading_div")
      .css(@cssAttributes)
      .hide()
      .ajaxError(@onAjaxError)
      .ajaxStart(@onAjaxStart)
      .ajaxStop(@onAjaxStop)
    return true

  onAjaxError: (ev, jqxhr, settings, err) ->
    $("#loading_div").hide()
    if jqxhr.status == 401
      # window.location.href = "/?unauthorized_alert="+encodeURIComponent(I18n.translate('errors.timeout_or_unauthorized'))
      window.location.href = "/?unauthorized_alert="+encodeURIComponent('Your session timed out or you are unauthorized to access this page.')
    else
      window.location.href = "/?flash_alert="+encodeURIComponent(err)
    return false

  onAjaxStart: () ->
    AjaxLoader.setPosition()
    $(window).bind 'resize', AjaxLoader.onWindowResize
    $("#loading_div").show()
    return true

  onAjaxStop: () ->
    $(window).unbind 'resize', AjaxLoader.onWindowResize
    $("#loading_div").hide()
    return true

  onWindowResize: () =>
    AjaxLoader.setPosition()
    return true

  setPosition: () ->
    windowWidth  = $(window).width()
    windowHeight = $(window).height()
    divWidth     = parseInt(@cssAttributes["width"], 10)
    divHeight    = parseInt(@cssAttributes["height"], 10)
    divLeft      = (windowWidth - divWidth) / 2
    divTop       = (windowHeight - divHeight) / 2
    $("#loading_div").css {left: divLeft, top: divTop}
    return true
}