class window.ChartUJS
  constructor: (@selector = "canvas.Chart", @autorun = "true", @devMode = "off") ->
    @go() if @autorun == "true"
    return true

  cleanValues: (dataObject) ->
    for dataNode in dataObject
      dataNode["value"] = parseInt(dataNode["value"], 10)
    return dataObject

  getCanvasContext: (element) ->
    target   = $(element).get()[0]
    try
      context  = target.getContext('2d')
    catch error
      if @devMode == "on"
        console.log "Could not establish a valid 2d context for: "
        console.log $(element)
        console.log error
    return context

  getChartData: (element) ->
    dataString    = $(element).attr('chart-data')
    try
      rawDataObject = jQuery.parseJSON(dataString)
    catch error
      if @devMode == on
        console.log "The JSON data you provided could not be parsed."
        console.log error
    dataObject    = @cleanValues(rawDataObject)
    return dataObject

  getChartType: (element) ->
    chartType = $(element).attr('chart-type')
    return chartType

  renderChart: (canvasContext, chartType, chartData) ->
    switch chartType
      when "Doughnut"   then new Chart(canvasContext).Doughnut(chartData)
      when "Line"       then new Chart(canvasContext).Line(chartData)
      when "Pie"        then new Chart(canvasContext).Pie(chartData)
      when "PolarArea"  then new Chart(canvasContext).PolarArea(chartData)
      else
        console.log("No valid chart-type given.") if @devMode == "on"

  go: () ->
    for target in $(@selector)
      console.log @selector
      canvasContext = @getCanvasContext(target)
      chartType     = @getChartType(target)
      chartData     = @getChartData(target)
      @renderChart(canvasContext, chartType, chartData)