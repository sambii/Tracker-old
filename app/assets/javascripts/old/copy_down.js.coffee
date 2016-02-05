window.CopyDown = {
  initialize: (@context = "body") ->
    elements = $("#{context} [copy-down-selector]")
    $(elements).keydown (e) ->
      if e.keyCode is 40
        CopyDown.doCopy(this)
        CopyDown.jumpFocus(this)
    return true

  doCopy: (element) ->
    container = @setContainer(element)
    selector  = @setSelector(element)
    value = $(element).val()
    if value.length > 0
      for target in container.find(selector)
        $(target).val(value)

  jumpFocus: (element) ->
    value = $(element).val()
    if value.length > 0
      elements = $("#{@context} [copy-down-selector]")
      index = $(elements).index(element)
      if $(elements)[index + 1]?
        # Simply calling select wouldn't select all of the text in some browsers
        # due to the way events bubble. Using a callback with setTimeout, while
        # not elegant, works in all browsers.
        topDifference = $($(elements)[index + 1]).position()["top"] - $(element).position()["top"]
        container     = $("#popup_form")
        newScroll     =  $(container).scrollTop() + topDifference
        callback = () ->
          $(elements)[index + 1].select()
          $(container).stop().animate({scrollTop: newScroll}, 250)
        setTimeout(callback, 5)

  setContainer: (element) ->
    containerSelector = $(element).attr('copy-down-container')
    if !containerSelector?
      containerSelector = "body"
    container = $(element).closest(containerSelector)
    return container

  setSelector: (element) ->
    selector = $(element).attr('copy-down-selector')
    return selector
}