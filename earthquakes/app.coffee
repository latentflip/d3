require ['jquery'], ($) ->

  window.eqfeed_callback = (data) ->
    console.log data

  $.ajax
    url: 'http://earthquake.usgs.gov/earthquakes/feed/geojsonp/2.5/month'
    dataType: 'jsonp'

  $ ->
    svg = d3.get('body').append('svg')
    
    svg.append(
