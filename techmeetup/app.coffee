require ['jquery', 'd3', 'underscore'], ($,d3,_) ->

  c =
    width: $(document).width()*0.98
    height: $(document).height()*0.97
    transitionLength: 2000

  svg = d3.select('body').append('svg')
            .attr('width', c.width)
            .attr('height', c.height)

  svg.append("svg:defs")
    .append("svg:marker")
      .attr("id", 'special')
      .attr("viewBox", "0 0 10 10")
      .attr("refX", 5)
      .attr("refY", 0)
      .attr("markerWidth", 6)
      .attr("markerHeight", 12)
      .attr("orient", "auto")
    .append("svg:path")
      .attr("d", "M 0,-5 L 10,0 L0,5");
  svg.append("svg:defs")
    .append("svg:marker")
      .attr("id", 'special-start')
      .attr("viewBox", "0 0 10 10")
      .attr("refX", 5)
      .attr("refY", 0)
      .attr("markerWidth", 6)
      .attr("markerHeight", 12)
      .attr("orient", "auto")
    .append("svg:path")
      .attr("d", "M 10,-5 L 0,0 L10,5");

  links_g = svg.append('svg:g')
                .attr('class', 'links')

  countries_g = svg.append('svg:g')
                  .attr('class', 'countries')

  users = svg.selectAll('g.user')
                .data([], (d)->d.user_id)
  users = null
  stats = {}

  nextSlide = null

  
  listUsers = ->
    perColumn = 10
    padding = 40
    spacing = (c.height-padding*2)/perColumn
    columnSpacing = (c.width-padding*2)/5
    users.append('circle')
            .attr('class', 'user')
            .attr('r', 24)
            .attr('cy', (d,i)->padding+(i%perColumn)*spacing)
            .attr('cx', -100)
            .style('stroke', '#FF6600')
            .style('stroke-width', 2)
          .transition().duration(100).delay( (d,i)->i*100 - 50)
            .attr('cx', (d,i)->
              colN = Math.floor(i/perColumn)
              padding+colN*columnSpacing
            )

    clip = svg.append('clipPath')
                .attr('id', 'clipcircle')
                .attr('clipPathUnits', 'objectBoundingBox')
              .append('circle')
                .attr('r', 0.5)
                .attr('cx', 0.5)
                .attr('cy', 0.5)

    users.append('image')
            .attr('class', 'user')
            .attr('xlink:href', (d)->d.avatar)
            .attr('clipPath', (d)->d.avatar)
            .attr('width', 48)
            .attr('height', 48)
            .attr('y', (d,i)->padding+(i%perColumn)*spacing - 24)
            .attr('x', -100)
            .style('fill', '#FF6600')
            .style('clip-path', 'url(#clipcircle)')
          .transition().duration(100).delay( (d,i)->i*100 - 50)
            .attr('x', (d,i)->
              colN = Math.floor(i/perColumn)
              padding+colN*columnSpacing - 24
            )

    users.append('text')
            .attr('class', 'user')
            .text( (d)->d.screen_name)
            .attr('y', (d,i)->padding+(i%perColumn)*spacing)
            .attr('x', c.width + 500)
            .style('fill', (d)->d.color)
            .style('dominant-baseline', 'middle')
          .transition().duration(100).delay( (d,i)->i*100 - 50)
            .attr('x', (d,i)->
              colN = Math.floor(i/perColumn)
              padding+colN*columnSpacing + 35
            )

  force = null
  forceGraph = ->
    d3.json 'twitterdata/links.json', (links) ->
      force = d3.layout.force()
                .charge(-100)
                .linkDistance(400)
                .size([c.width, c.height])
                .gravity(0.05)


      find = (coll, test) ->
        for i in [0...coll.length]
          return i if test(coll[i])
        return -1
      
      links = links.map (link) ->
        link.source = find users.data(), (u)->u.id == link.source
        link.target = find users.data(), (u)->u.id == link.target
        link.weight = link.value
        link

      force.nodes(users.data())
            .links(links)
            .linkStrength( (d)-> strength = d.value / d3.max(links, (d)->d.value) )
            .start()
      
      thickness = d3.scale.linear()
                      .range([1,5])
                      .domain([0, d3.max(links, (d)->d.value)])
           
      linksToNodes = {}
      nodesToNodes = {}
      link = links_g.selectAll('line.link')
                  .data(links)
                .enter().append('line')
                    .attr('class', 'link')
                    .attr('stroke-width', (d)->thickness(d.value))
                    .attr('stroke', '#ccc')
                    .each( (l) ->
                      linksToNodes[l.source.id] ||= []
                      linksToNodes[l.source.id].push this

                      linksToNodes[l.target.id] ||= []
                      linksToNodes[l.target.id].push this

                      nodesToNodes[l.source.id] ||= [l.source.id]
                      nodesToNodes[l.source.id].push l.target.id
                      nodesToNodes[l.target.id] ||= [l.target.id]
                      nodesToNodes[l.target.id].push l.source.id
                    )

      szscale = d3.scale.log()
                    .domain([1, 30])
                    .range([32, 64])

      node = svg.selectAll('image.user')
                    .attr('width', (d)-> szscale(d.weight||1))
                    .attr('height', (d)-> szscale(d.weight||1))

      node.on('mouseover', (d) ->
        if ls = linksToNodes[d.id]
          ls.forEach (link) ->
            d3.select(link).style('stroke', '#66FF00')

        if ns = nodesToNodes[d.id]
          ns.forEach (n) ->
            svg.select("circle.user-#{n}").style('stroke-width', 5).style('stroke', '#66FF00')
      )
      node.on('mouseout', (d) ->
        if ls = linksToNodes[d.id]
          ls.forEach (link) ->
            d3.select(link).style('stroke', '')
        if ns = nodesToNodes[d.id]
          ns.forEach (n) ->
            svg.select("circle.user-#{n}").style('stroke-width', '').style('stroke', '')
      )

      nodeC = svg.selectAll('circle.user')
                    .attr('r', (d)-> szscale(d.weight||1)/2)
                    .attr('class', (d)->"user user-#{d.id}")

      nodetext = svg.selectAll('text.user')
                    .attr('class', 'nodetext')
                    .text( (d)->d.screen_name)

      
      force.on 'tick', ->
        node.attr('x', (d) -> d.x - szscale(d.weight||1)/2)
            .attr('y', (d) -> d.y - szscale(d.weight||1)/2)

        nodeC.attr('cx', (d) -> d.x)
            .attr('cy', (d) -> d.y)

        nodetext.attr('x', (d) -> d.x + 30)
                .attr('y', (d) -> d.y)

        link.attr('x1', (d) -> d.source.x)
            .attr('y1', (d) -> d.source.y)
            .attr('x2', (d) -> d.target.x)
            .attr('y2', (d) -> d.target.y)

  chords = ->
    force.stop()
    chordRadius = 250
    chordRadius2 = 280
    
    ul = users[0].length

    xmath = (d,i) -> 
      c.width/2 + chordRadius*Math.cos((i/ul)*2*Math.PI)
    ymath = (d,i) -> 
      c.height/2 + chordRadius*Math.sin((i/ul)*2*Math.PI)
    xmath2 = (d,i) -> 
      c.width/2 + chordRadius2*Math.cos((i/ul)*2*Math.PI)
    ymath2 = (d,i) -> 
      c.height/2 + chordRadius2*Math.sin((i/ul)*2*Math.PI)

    isize = 32
    users.select('image')
          .transition().duration(c.transitionLength)
            .attr('width', isize)
            .attr('height', isize)
            .attr('x', (d,i)->xmath(d,i)-isize/2)
            .attr('y', (d,i)->ymath(d,i)-isize/2)

    users.select('circle')
          .transition().duration(c.transitionLength)
            .attr('r', isize/2)
            .attr('cx', xmath)
            .attr('cy', ymath)

    users.select('text')
          .transition().duration(c.transitionLength)
            .attr('x', xmath2)
            .attr('y', ymath2)
            .style('text-anchor', (d,i) -> 
              if xmath2(d,i) < c.width/2
                'end'
              else
                'start'
            )
            .attr('transform', (d,i)->
              deg = (i/ul)*360
              x = xmath2(d,i)
              y = ymath2(d,i)
              if xmath2(d,i) < c.width/2
                deg = deg - 180
              "rotate(#{deg},#{x},#{y})"
            )

    svg.selectAll('line.link')
          .transition().duration(c.transitionLength)
            .attr('x1', (d) -> xmath(d,d.source.index))
            .attr('x2', (d) -> xmath(d,d.target.index))
            .attr('y1', (d) -> ymath(d,d.source.index))
            .attr('y2', (d) -> ymath(d,d.target.index))

  countDown = ->
    s = svg.append('svg:g')
                .attr('class', 'slide')

    arc = (start, end) ->
      start = (start/180)*Math.PI
      end = (end/180)*Math.PI
      d3.svg.arc()
        .innerRadius(0)
        .outerRadius(1000)
        .startAngle(start)
        .endAngle(end)()

    pie = s.append('path')
          .attr('d', arc(0,0))
          .attr('fill', '#787878')
          .attr('transform', "translate(#{c.width/2},#{c.height/2})")

    s.append('circle')
        .attr('cx', c.width/2)
        .attr('cy', c.height/2)
        .attr('r', 200)
        .style('stroke', 'rgba(255,255,255,0.8)')
        .style('stroke-width', 5)

    s.append('circle')
        .attr('cx', c.width/2)
        .attr('cy', c.height/2)
        .attr('r', 230)
        .style('stroke', 'rgba(255,255,255,0.5)')
        .style('stroke-width', 5)

    s.append('line')
        .attr('x1', 0)
        .attr('x2', c.width)
        .attr('y1', c.height/2)
        .attr('y2', c.height/2)
        .attr('stroke', '#000')
        .attr('stroke-width', 5)

    s.append('line')
        .attr('x1', c.width/2)
        .attr('x2', c.width/2)
        .attr('y1', 0)
        .attr('y2', c.height)
        .attr('stroke', '#000')
        .attr('stroke-width', 5)

    num = s.append('text')
            .text('5')
            .style('fill', '#000')
            .style('font-size', 300)
            .style('text-anchor', 'middle')
            .style('dominant-baseline', 'central')
            .attr('x', c.width/2)
            .attr('y', c.height/2)


    l = 1000
    d3.timer (n) ->
      deg = (n/l)*360
      
      count = Math.floor( n / l )
      if count % 2 == 0
        updown = 'up'
      else
        updown = 'down'

      if count >= 5
        s.transition().duration(1000)
            .attr('transform', 'translate(-5000,0)')
            .each('end', ->
              d3.selectAll('g.slide').remove()
              nextSlide()
            )
        return true
      else
        num.text(5-count)
        if updown == 'up'
          pie.attr('d', arc(0, deg%360))
        else
          pie.attr('d', arc(deg%360, 359))
        return false



  axis = svg.append('svg:g')
              .attr('class', 'axis')
  
  circleTweetCount = ->
    force.stop()
    svg.selectAll('line.link').remove()
    r = d3.scale.log()
            .domain(stats.statuses_count)
            .range([0, c.height*0.75])

    axis.append('line')
          .attr('class', 'xaxis')
          .attr('x1', c.width/2+0.5)
          .attr('y1', c.height*0.75)
          .attr('x2', c.width/2+0.5)
          .attr('y2', c.height*0.75)
        .transition().duration(c.transitionLength)
          .attr('x2', c.width - 150)
          .attr('y2', 150)
          .attr('marker-start', 'url(#special-start)')
          .attr('marker-end', 'url(#special)')

    axis.append('text')
          .text('Loads a tweets')
          .style('text-anchor', '')
          .attr('x', c.width/2)
          .attr('y', c.height*0.75)
          .attr('transform', ->
            deg = -2*Math.tan(c.height/c.width)*(90/Math.PI)
            "rotate(#{deg},#{c.width/2},#{c.height*0.75})"
          )
        .transition().duration(c.transitionLength)
          .attr('x', c.width-120)
          .attr('y', 145)
          .attr('transform', ->
            deg = -2*Math.tan(c.height/c.width)*(90/Math.PI)
            "rotate(#{deg},#{c.width-145},#{120})"
          )

    users.select('image')
          .style('opacity', 0)

    users.select('circle')
          .transition().duration(c.transitionLength)
            .style('fill', 'none')
            .attr('r', (d)->r(d.statuses_count))
            .attr('cx', c.width/2)
            .attr('cy', c.height*0.75)

    users.select('text')
        .transition().duration(c.transitionLength)
          .text( (d)->d.screen_name)
          .style('text-anchor', 'middle')
          .attr('x', c.width/2)
          .attr('y', (d) -> (c.height*0.75)-r(d.statuses_count) )
          .attr('transform', (d,i) ->
            d = ((i*5)%90) - 45
            cx = c.width/2
            cy = c.height*0.75
            "rotate(#{d},#{cx},#{cy})"
          )
    
  scaleTweetCount = ->
    _y = d3.scale.log()
            .domain(stats.statuses_count)
            .range([40, c.height-40])
    y = (d,i) -> c.height - _y(d,i)
            
    users.select('image')
        .transition().duration(c.transitionLength)
          .style('opacity', 1)
          .attr('y', (d)->y(d.statuses_count) - 24)
          .attr('x', c.width/2 - 24 + 50 )

    users.select('circle')
        .transition().duration(c.transitionLength)
          .style('opacity', 0)
          .attr('r', 24)
          .attr('cy', (d)->y(d.statuses_count) )

    users.select('text')
        .transition().duration(c.transitionLength)
          .attr('x', (c.width/2)+80)
          .attr('y', (d)->y(d.statuses_count) )
          .style('text-anchor', 'start')
          .attr('transform', (d)->"rotate(0)")

    axis.select('line.xaxis')
          .transition().duration(c.transitionLength)
            .attr('x1', c.width/2+0.5)
            .attr('x2', c.width/2+0.5)
            .attr('y2', 35)
            .attr('y1', c.height-45)

    axis.select('text')
          .transition().duration(c.transitionLength)
          .attr('y', 20)
          .attr('x', c.width/2)
          .attr('transform', '')
          .style('text-anchor', 'middle')


  addAxes = ->
    _y = d3.scale.linear()
            .domain(stats.statuses_count)
            .range([0, c.height])
    y = (d,i) -> c.height - _y(d,i)

    x = d3.time.scale()
            .domain(stats.signed_up)
            .range([0, c.width])


    axis.append('text')
          .text('Joined recently')
          .style('text-anchor', 'end')
          .attr('x', c.width - 20)
          .attr('y', c.height/2 - 10)

    axis.append('text')
          .text('Joined ages ago')
          .style('text-anchor', 'start')
          .attr('x', 20)
          .attr('y', c.height/2 - 10)


    axis.append('text')
          .text('Nay tweets')
          .style('text-anchor', 'middle')
          .attr('y', c.height - 20)
          .attr('x', c.width/2)

    axis.append('line')
          .attr('y1', c.height/2+0.5)
          .attr('y2', c.height/2+0.5)
          .attr('x1', 20)
          .attr('x2', c.width-20)
          .attr('marker-start', 'url(#special-start)')
          .attr('marker-end', 'url(#special)')

    axis.append('line')
          .attr('x1', c.width/2+0.5)
          .attr('x2', c.width/2+0.5)
          .attr('y1', 35)
          .attr('y2', c.height-45)
          .attr('marker-start', 'url(#special-start)')
          .attr('marker-end', 'url(#special)')

  addAxesAnnotations = ->
    maxis = svg.append('svg:g')
                .attr('class', 'axisan')
    note = (text, xp, yp, delay, duration) ->
      r=maxis.append('rect')
              .style('fill', '#66FF00')

      t=maxis.append('text')
              .text(text)
      t.attr('x', c.width*xp)
        .attr('y', c.height*yp)
        .style('text-anchor', 'middle')
        .style('opacity', 0)
      .transition().duration(duration).delay(delay)
        .style('opacity', 1)
        
      r.attr('width', t[0][0].clientWidth+10)
        .attr('height', t[0][0].clientHeight+10)
        .attr('x', c.width*xp - (t[0][0].clientWidth+10)/2)
        .attr('y', c.height*yp - (t[0][0].clientHeight+20)/2)
        .style('opacity', 0)
      .transition().duration(duration).delay(delay)
        .style('opacity', 1)

    note('Old Bores', 0.25, 0.25, 0, 1000)
    note('A bit Keen', 0.75, 0.25, 1000, 1000)
    note('Learning the ropes', 0.75, 0.75, 2000, 1000)
    note('Stalkers', 0.25, 0.75, 3000, 1000)


  removeAxes = ->
    svg.selectAll('g.axis').remove()
    svg.selectAll('g.axisan').remove()


  scatterPlot = ->
    addAxes()
    _y = d3.scale.log()
            .domain(stats.statuses_count)
            .range([20, c.height-20])
    y = (d,i) -> c.height - _y(d,i)

    x = d3.time.scale()
            .domain(stats.signed_up)
            .range([20, c.width-20])

    users.select('image')
        .transition().duration(c.transitionLength)
          .attr('width', 48)
          .attr('height', 48)
          .attr('y', (d)->y(d.statuses_count) - 24)
          .attr('x', (d)->x(d.signed_up) - 24)

    users.select('circle')
        .transition().duration(c.transitionLength)
          .attr('cx', (d)->x(d.signed_up) )
          .attr('cy', (d)->y(d.statuses_count) )

    users.select('text')
        .transition().duration(c.transitionLength)
          .attr('x', (d)->x(d.signed_up) + 30 )
          .attr('y', (d)->y(d.statuses_count) )

  geoTweet = ->
    removeAxes()
    origin = [-3.22, 55.95]
    projection = d3.geo.azimuthal()
                    .scale(100)
                    .origin(origin)
                    .mode('orthographic')
                    .translate([c.width/2, c.height/2])

    path = d3.geo.path()
                .projection(projection)
                .pointRadius(3)

    circle = d3.geo.greatCircle()
              .origin(projection.origin())

    clip = (d) =>
      path(circle.clip(d))


    d3.json 'world-countries.json', (collection) =>
      redraw = ->
        countries_g.selectAll('path')
                    .attr('d', clip)
        users.select('circle')
                .style('opacity', 1)
                .attr('cx', (d)->
                  projection(d.geocoords)[0]
                )
                .attr('cy', (d)->
                  projection(d.geocoords)[1]
                )
        users.select('text')
                  .attr('x', (d)->
                    projection(d.geocoords)[0]
                  )
                  .attr('y', (d)->
                    projection(d.geocoords)[1]
                  )
                  .style('text-anchor', 'start')
                  .attr('transform', (d,i) ->
                    angle = (i*10)%360
                    p = projection(d.geocoords)
                    "rotate(#{angle},#{p[0]},#{p[1]})translate(15,0)"
                  )

      spun = 0
      delta = 40
      spinTimeLength = 6000
      scaleTimeLength = 6000
      originalOrigin = projection.origin()
      originalScale = projection.scale()
      ease = d3.ease('elastic')
      sease = d3.ease('cubic-in')


      spin = (timestep) ->
        spun = 360*ease(timestep/spinTimeLength)
        scale = originalScale+20000*sease(timestep/scaleTimeLength)

        origin = [originalOrigin[0] + spun, originalOrigin[1]]
        projection.origin origin
        circle.origin origin
        projection.scale scale
        redraw()

        if timestep >= spinTimeLength and timestep >= scaleTimeLength
          true
        else
          false

      startSpin = ->
        d3.timer spin

      countries = countries_g.selectAll('path')
                  .data(collection.features)
                .enter().append('svg:path')
                  .attr('d', clip)

      users.select('image')
              .transition().duration(200)
              .style('opacity', 0)
      users.select('text')
              .transition().duration(2000)
                .attr('x', (d)->
                  projection(d.geocoords)[0]
                )
                .attr('y', (d)->
                  projection(d.geocoords)[1]
                )
                .attr('transform', (d,i) ->
                  angle = (i*10)%360
                  p = projection(d.geocoords)
                  "rotate(#{angle},#{p[0]},#{p[1]})translate(25,0)"
                )
                .style('font-size', '20px')

      users.select('circle')
          .transition().duration(2000)
            .style('opacity', 1)
            .attr('r', 3)
            .attr('cx', (d)->
              projection(d.geocoords)[0]
            )
            .attr('cy', (d)->
              projection(d.geocoords)[1]
            )
            .each('end', startSpin)

  slide = (text) ->
    ->
      s = svg.append('svg:g')
                  .attr('class', 'slide')
      
      s.append('text')
              .text(text)
              .style('text-anchor', 'middle')
              .attr('y', c.height/2)
              .attr('x', c.width+500)
              .attr('width', c.width*0.75)
              .attr('height', c.width*0.75)
            .transition().duration(c.transitionLength/2)
              .attr('x', c.width/2)
      return s
  slide2 = (text1,text2) ->
    ->
      s = svg.append('svg:g')
                  .attr('class', 'slide')
      
      s.append('text')
              .text(text1)
              .style('text-anchor', 'middle')
              .attr('y', c.height*0.4)
              .attr('x', c.width+500)
              .attr('width', c.width*0.75)
              .attr('height', c.width*0.75)
            .transition().duration(c.transitionLength/2)
              .attr('x', c.width/2)
      s.append('text')
              .text(text2)
              .style('text-anchor', 'middle')
              .attr('y', c.height*0.65)
              .attr('x', c.width+500)
              .attr('width', c.width*0.75)
              .attr('height', c.width*0.75)
              .style('font-size', '80px')
            .transition().duration(c.transitionLength/2)
              .attr('x', c.width/2)
      return s

  philSlide = ->
    slide('@philip_roberts')()

    svg.select('g.slide').append('text')
        .text('<-')
        .attr('x', c.width+500)
        .attr('y', c.height*0.8)
        .style('text-anchor', 'middle')
        .style('font-size', 200)
        .style('fill', '#FF6600')
      .transition().duration(5000).delay(500).ease('elastic', 10,10)
        .attr('x', c.width*0.2)

  explode = ->
    svg.selectAll('text')
          .transition().duration(c.transitionLength)
            .attr('x', -500)
          .remove()
    svg.selectAll('path')
          .transition().duration(c.transitionLength)
            .attr('transform', "translate(-50000,0)")
          .remove()
    svg.selectAll('circle')
          .transition().duration(c.transitionLength)
            .attr('cx', -500)
          .remove()

  d3.json 'twitterdata/users.json', (coll) ->
    #coll = coll.filter (u) -> u.coords
    coll = coll.map (u) ->
      u.geocoords = u.coords || [-3.22, 55.95]
      u.signed_up = new Date Date.parse(u.signed_up)
      u

    
    users = svg.selectAll('g.user')
                  .data(coll, (d)->d.user_id)
    users.enter()
            .append('svg:g')
            .attr('class', 'user')

    stats.statuses_count = d3.extent(coll, (d)->d.statuses_count)
    stats.signed_up = d3.extent(coll, (d)->d.signed_up)
    
    currSlide=0
    slides = []
    nextSlide = ->
      s = svg.selectAll('g.slide')
      if s[0].length > 0
        s.selectAll('text')
            .transition().duration(500)
              .attr('x', -500)
            .remove()
        slides[currSlide]()
      else
        slides[currSlide]()
      currSlide++

    slides.push slide("hello")
    slides.push philSlide
    slides.push slide("d3.js")
    slides.push slide("data")
    slides.push slide("html/svg")
    slides.push slide("it's a bit, wat?")
    slides.push slide("and a bit wow")
    slides.push slide("concepts:")
    slides.push slide("declarative")
    slides.push slide("data binding")
    slides.push slide("scales/projections")
    slides.push slide("good for")
    slides.push slide("not for")
    slides.push slide("who's using it?")
    slides.push slide("demo")
    slides.push countDown
    slides.push listUsers
    slides.push forceGraph
    slides.push chords
    slides.push circleTweetCount
    slides.push scaleTweetCount
    slides.push scatterPlot
    slides.push addAxesAnnotations
    slides.push geoTweet
    slides.push explode
    slides.push slide("so, like, holy cow!")
    slides.push slide2("questions?", "@philip_roberts")
    
    nextSlide()

    nextS = _.debounce nextSlide, 200
    svg.on('click', nextS)
    $('body').on('keypress', -> nextS(); false)
