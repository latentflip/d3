require ['jquery', 'd3'], ($, d3) ->
  
  getParams = ->
    {
      p: window.location.hash.substr(1)
    }

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

    spin: =>
      origin = @projection.origin()
      origin[0]++
      @projection.origin(origin)
      @circle.origin(origin)
      @redraw()
      return false

    redraw: =>
      @countries.attr('d', @clip)
      @flights.attr('d', @arc)
              .style('stroke-dasharray', (d) -> "#{@getTotalLength()},#{@getTotalLength()}")

    drawCountries: =>
      d3.json '/data/world-countries.json', (collection) =>
        @countries = @countries_g.selectAll('path')
                    .data(collection.features)
                  .enter().append('svg:path')
                    .attr('d', @clip)

        @drawArcs()
        @startSpin()

    drawArcs: =>
      arc = d3.geo.greatArc()
                .source( (d) -> d.source )
                .target( (d) -> d.target )
      @arc = (d) => @path(@circle.clip(arc(d)))
      arcs = [
        { source: [-3.22, 53], target: [-10, 0] }
        { source: [-3.22, 53], target: [-100, 0] }
      ]

      @flights = @svg.selectAll('path.flight')
                        .data(arcs)
      @flights.enter().append('svg:path')
          .attr('class', 'flight')
          .attr('d', @arc)
          .attr('height', (d) -> console.log @getTotalLength())
          .style('stroke-dasharray', (d) -> "#{@getTotalLength()},#{@getTotalLength()}")
          .style('stroke-dashoffset', (d) -> @getTotalLength())
        .transition().duration(2000)
          .style('stroke-dashoffset', 0)


  start = ->
    window.spin = new Spin

  $ ->
    start()
