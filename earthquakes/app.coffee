require ['jquery', 'd3'], ($, d3) ->


  class Earthquakes
    c:
      width: 1024
      height: 580

    constructor: ->
      @svg = d3.select('body').append('svg')
                .attr('width', @c.width)
                .attr('height', @c.height)
                .on('mousedown', @onMouseDown)

      @projection = d3.geo.azimuthal()
                      .scale(250)
                      .origin([-71.03, 42.37])
                      .mode('orthographic')
                      .translate([@c.width/2, @c.height/2])

      @path = d3.geo.path()
                  .projection(@projection)
                  .pointRadius(3)

      @circle = d3.geo.greatCircle()
                .origin(@projection.origin())

      d3.select(window)
          .on('mousemove', @onMouseMove)
          .on('mouseup', @onMouseUp)

      @clip = (d) =>
        @path(@circle.clip(d))

      @countries_g = @svg.append('svg:g')
                      .attr('class', 'countries')
      @drawCountries()

      @earthquakes_g = @svg.append('svg:g')
                      .attr('class', 'earthquakes')

    m0: null
    o0: null
    onMouseDown: =>
      @m0 = [d3.event.pageX, d3.event.pageY]
      @o0 = @projection.origin()
      d3.event.preventDefault()
    onMouseMove: =>
      if @m0
        m0 = @m0
        o0 = @o0
        m1 = [d3.event.pageX, d3.event.pageY]
        o1 = [o0[0] + (m0[0] - m1[0])/8, o0[1] + (m1[1] - m0[1])/8]
        @projection.origin(o1)
        @circle.origin(o1)
        @redraw()
    onMouseUp: =>
      if @m0
        @onMouseMove()
        @m0 = null
    redraw: (duration) =>
      if duration
        @countries.transition().duration(duration).attr('d', @clip)
      else
        @countries.attr('d', @clip)
        circle = @circle
        @earthquakes.attr('cx', (d) =>
                        @projection(d.geometry.coordinates[0..1])[0]
                      )
                    .attr('cy', (d) =>
                        @projection(d.geometry.coordinates[0..1])[1]
                      )
                    .attr('r', (d) ->
                      if circle.clip(d)
                        d3.select(@).attr('r')
                      else
                        0
                    )


    drawCountries: =>
      d3.json 'world-countries.json', (collection) =>
        @countries = @countries_g.selectAll('path')
                    .data(collection.features)
                  .enter().append('svg:path')
                    .attr('d', @clip)

    onDataCircles: (data) =>
      @earthquakes = @earthquakes_g.selectAll('circle')
                      .data(data.features)

      entered = @earthquakes.enter()
                    .append('svg:circle')
                    .attr('r', 0)
                    .attr('cx', (d) => 
                      @projection(d.geometry.coordinates[0..1])[0]
                    )
                    .attr('cy', (d) =>
                      @projection(d.geometry.coordinates[0..1])[1]
                    )
                    .on('mouseover', (d) -> console.log d.properties)
                  .transition().duration(50).delay( (d,i)->i*25)
                    .ease('elastic', 20, 5)
                    .attr('r', (d) =>
                      if @circle.clip(d)
                        d.properties.mag
                      else
                        0
                    )
                    

    onDataPaths: (data) =>
      @earthquakes = @earthquakes_g.selectAll('path')
                      .data(data.features)

      entered = @earthquakes.enter()
                  .append('svg:path')
                  .attr('d', @clip)

  start = ->
    earthquakes = new Earthquakes

    window.eqfeed_callback = earthquakes.onDataCircles

    $.ajax
      url: 'http://earthquake.usgs.gov/earthquakes/feed/geojsonp/2.5/month'
      dataType: 'jsonp'

  $ ->
    start()
