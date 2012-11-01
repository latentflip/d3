require ['d3', 'jquery', 'underscore'], (d3, $, _) ->
  log = (args...) -> console.log args...

  geoSeparation = (from, to) ->
    b_2 = Math.pow (from.lat - to.lat), 2
    c_2 = Math.pow (from.lat - to.lat), 2
    Math.pow (b_2+c_2), 0.5

  do ->
    window.data = {};
    data.raw = Stops;
    data.stops = [];
    data.links = [];

    stops_found = {}

    services = data.raw
    group_n = -1
    for num,stops of services
      do (num, stops) ->
        last_stop = null

        group_n++
        for s in stops
          do (s) ->
            if stops_found[s.code]
              stop = stops_found[s.code]
            else
              stop = s
              stop.index = data.stops.length
              data.stops.push stop
              stop.group = group_n
              stops_found[stop.code] = stop

            if last_stop
              link =
                source: last_stop.index
                target: stop.index
                value: 1
              data.links.push link

            last_stop = stop
    
    data
  
  class Buses
    render: ->
      @buildSVG()
      @renderGeo()
      @renderStops()

    c:
      width: 1250
      height: 650

    buildSVG: =>
      @svg = d3.select('body').append('svg')
                  .attr('width', @c.width)
                  .attr('height', @c.height)
      @color = d3.scale.category20()
  
    renderGeo: =>
      edinburgh = [-3.22, 55.925]
      @xy = d3.geo.mercator()
                  .scale(1000000)
                  .translate([@c.width*0.5, @c.height*0.5])
      
      current_edinburgh = @xy(edinburgh)
      current_center = @xy.translate()
      error = [
        current_edinburgh[0] - current_center[0]
        current_edinburgh[1] - current_center[1]
      ]
      @xy.translate([
        current_center[0] - error[0]
        current_center[1] - error[1]
      ])
      
      @path = d3.geo.path().projection(@xy)
      @states = @svg.append('g')
                    .attr('id', 'states')

      d3.json '../data/world-countries.json', (coll) =>
        @states.selectAll('path')
                .data(coll.features)
              .enter().append('path')
                .attr('d', @path)

    renderStops: =>
      @stops = @svg.selectAll('circle.stop')
                  .data(data.stops)
      
      stopToLatLong = (stop) =>
        ll = @xy([parseFloat(stop.longitude), parseFloat(stop.latitude)])
        ll

      @stops.enter()
              .append('circle')
                .attr('class', 'stop')
                .attr('r', 3)
                .attr('cx', (d) -> stopToLatLong(d)[0])
                .attr('cy', (d) -> stopToLatLong(d)[1])
                .attr('fill', (d) => @color(d.group))
  $ ->
    window.buses = new Buses
    buses.render()
