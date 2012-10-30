require ['jquery', 'd3'], ($, d3) ->
  
  getParams = ->
    {
      p: window.location.hash.substr(1)
    }

  class Earthquakes
    c:
      width: 1024
      height: 580

    constructor: ->
      @date = d3.select('h2')

      @svg = d3.select('body').append('svg')
                .attr('width', @c.width)
                .attr('height', @c.height)
                .on('mousedown', @onMouseDown)

      if getParams().p
        origin = getParams().p.split(',').map (p)->parseFloat(p)
      else
        origin = [-71.03, 42.37]
      @projection = d3.geo.azimuthal()
                      .scale(250)
                      .origin(origin)
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

        window.location.hash = o1
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

    drawSlider: (extents) =>
      renderAt = @renderAt
      @slider = d3.select('body')
        .append('input')
          .attr('class', 'timeslider')
          .attr('type', 'range')
          .attr('min', extents[0])
          .attr('max', extents[1])
          .attr('value', extents[1])
          .attr('step', 1)
          .on('change', ->
            renderAt @value
          )

    drawCountries: =>
      d3.json '../data/world-countries.json', (collection) =>
        @countries = @countries_g.selectAll('path')
                    .data(collection.features)
                  .enter().append('svg:path')
                    .attr('d', @clip)



    animateEarthquakes: (data) =>
      @features = data.features
      @onDataCircles(@features)
    

    renderAt: (time) =>
      @date.html new Date(time*1000).toString()
      features = @features.filter (d) ->
                  d.properties.time <= time

      es = @earthquakes_g.selectAll('circle')
                      .data(features)

      exited = es.exit()
      exited.remove()

      entered = es.enter()
      entered
        .append('svg:circle')
          .attr('r', 0)
          .attr('cx', (d) => 
            @projection(d.geometry.coordinates[0..1])[0]
          )
          .attr('cy', (d) =>
            @projection(d.geometry.coordinates[0..1])[1]
          )
        .transition().duration(@c.durations.in)
          .attr('r', (d) =>
            if @circle.clip(d)
              0.0001*Math.pow(10,d.properties.mag)
            else
              0
          )
        .transition().duration(@c.durations.out).delay(@c.durations.in)
          .attr('r', (d) =>
            if @circle.clip(d)
              d.properties.mag
            else
              0
          )

    onDataCircles: (features) =>
      @earthquakes = @earthquakes_g.selectAll('circle')
                      .data(features, (d)->d.id)

      @c.durations =
        in: 200
        out: 200
        spacing: 25
        length: 15000
      durations = @c.durations
      
      extent = d3.extent(features, (d) -> d.properties.time)
      @drawSlider extent
      
      @timeScale = d3.scale.linear()
                    .domain(extent)
                    .range([0, durations.length])

      entered = @earthquakes.enter()
                    .append('svg:circle')
                    .attr('r', 0)
                    .attr('cx', (d) => 
                      @projection(d.geometry.coordinates[0..1])[0]
                    )
                    .attr('cy', (d) =>
                      @projection(d.geometry.coordinates[0..1])[1]
                    )
                  .transition().duration(durations.in).delay( (d,i)=>@timeScale(d.properties.time))
                    .attr('r', (d) =>
                      if @circle.clip(d)
                        0.0001*Math.pow(10,d.properties.mag)
                      else
                        0
                    )
                  .transition().duration(durations.out).delay( (d,i)=>@timeScale(d.properties.time)+durations.in)
                    .attr('r', (d) =>
                      if @circle.clip(d)
                        d.properties.mag
                      else
                        0
                    )
                  .each('end', (d) =>
                    @date.html new Date(d.properties.time*1000).toString()
                    @slider.attr 'value', d.properties.time
                  )
                    

    onDataPaths: (data) =>
      @earthquakes = @earthquakes_g.selectAll('path')
                      .data(data.features)

      entered = @earthquakes.enter()
                  .append('svg:path')
                  .attr('d', @clip)

  start = ->
    window.earthquakes = new Earthquakes
    window.eqfeed_callback = earthquakes.animateEarthquakes

    $.ajax
      url: 'http://earthquake.usgs.gov/earthquakes/feed/geojsonp/2.5/month'
      dataType: 'jsonp'

  $ ->
    start()
