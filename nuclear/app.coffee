require ['jquery', 'd3', 'underscore'], ($, d3, _) ->

  _.random = (max) ->
      min = 0
      range = max - min
      0 | (min + Math.random() * (range + 1))

  _.mixin(
    randomItem: (list) ->
      list[_.random(list.length - 1)]
  )


  getParams = ->
    {
      p: window.location.hash.substr(1)
    }

  mapCoords = (coords) ->
    coords.map (c) ->
      if typeof c[0] == 'number'
        [
          c[0] + Math.random() - 0.5
          c[1] + Math.random() - 0.5
        ]
      else
        mapCoords(c)


  class Spin
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

      @svg.append('circle')
          .attr('class', 'earth')
          .attr('r', 250)
          .attr('cx', @c.width/2)
          .attr('cy', @c.height/2)

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

    startSpin: =>
      d3.timer(@spin)


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

    spins: 0
    spin: =>
      origin = @projection.origin()
      origin[0] = origin[0] + 0.5
      @projection.origin(origin)
      @circle.origin(origin)
      @redraw()
      return false

    redraw: =>
      @mutateCountryData()
      @countries
        .data(@data, (d) -> d.properties.name)
        .attr('d', @clip)
      if @flights
        @flights.attr('d', @arc)
              .style('stroke-dasharray', (d) -> "#{@getTotalLength()},#{@getTotalLength()}")

    mutateCountry: (co) =>
      co.geometry.coordinates = co.geometry.coordinates.map (parts) ->
        mapCoords(parts)
      co


    mutating: {}
    mutateCountryData: =>
      @data = @data.map (d) =>
        if @mutating && @mutating[d.properties.name]
          @mutateCountry(d)
        else
          d

    drawCountries: =>
      d3.json '../data/world-countries.json', (collection) =>
        @data = collection.features
        @countries = @countries_g.selectAll('path')
                    .data(@data, (d) -> d.properties.name)
                  .enter().append('svg:path')
                    .attr('d', @clip)
                    .attr('class', (d) -> d.properties.name)

        @startSpin()
        @randomArc()

    randomArc: =>
      from = _.randomItem @data
      to = _.randomItem @data
      
      findCoords = (array) ->
        if typeof array[0] == 'number'
          array
        else
          findCoords(array[0])

      arc = {
        id: "#{from.properties.name}-#{to.properties.name}"
        source: findCoords(from.geometry.coordinates)
        target: findCoords(to.geometry.coordinates)
        targetCountry: to
      }
      @drawArcs([arc])

    drawArcs: (arcs) =>
      arc = d3.geo.greatArc()
                .source( (d) -> d.source )
                .target( (d) -> d.target )

      @arc = (d) => @path(@circle.clip(arc(d)))

      @flights = @svg.selectAll('path.flight')
                        .data(arcs, (d)->d.id)
      @flights.exit().remove()
      @flights.enter().append('svg:path')
          .attr('class', 'flight')
          .attr('d', @arc)
          .style('stroke-dasharray', (d) -> "#{@getTotalLength()},#{@getTotalLength()}")
          .style('stroke-dashoffset', (d) -> @getTotalLength())
        .transition().duration(1000)
          .style('stroke-dashoffset', 0)
          .each('end', (d)=>
            @mutating[d.targetCountry.properties.name] = true
            @randomArc())

  start = ->
    window.spin = new Spin

  $ ->
    start()
