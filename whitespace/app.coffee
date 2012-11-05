require ['d3', 'underscore'], (d3, _) ->
  
  notedata = [
    id: 1
    x: 50
    y: 50
    text: 'foo'
  ,
    id: 2
    x: -1000
    y: -1000
    text: 'bar'
  ]

  config =
    initialFontSize: 5

  whiteboard = d3.select('.whiteboard')

  _x = d3.scale.linear()
          .range([0, parseInt(whiteboard.style('width'))])
          .domain([-10000,10000])

  _y = d3.scale.linear()
          .range([0, parseInt(whiteboard.style('height'))])
          .domain([-10000,10000])

  x = (d)->
    _x(d.x)

  y = (d)->
    _y(d.y)

  notes = whiteboard.selectAll('.note')
                      .data(notedata, (d)->d.id)

  notes.enter().append('div')
                .attr('class', 'note')
                .html( (d)->d.text )
                .style('left', x)
                .style('top', y)
                .attr('contentEditable', true)
  
  whiteboard.on('mousewheel', -> zoomIn -1*d3.event.wheelDelta)
  whiteboard.on('mousedown', -> whiteboard.on('mousemove', pan))
  whiteboard.on('mouseup', -> whiteboard.on('mousemove', null))

  moveNote = (d) ->
    move = [
      _x.invert(0) - _x.invert(d3.event.webkitMovementX)
      _y.invert(0) - _y.invert(d3.event.webkitMovementY)
    ]
    d.x -= move[0]
    d.y -= move[1]
    updateNotePositions()

  notes.on 'mousedown', (d) ->
    d3.event.stopPropagation()
    whiteboard.on('mousemove', -> moveNote(d))
  notes.on('mouseup', -> d3.select(this).on('mousemove', null))


  updateNotePositions = ->
    notes.data(notedata, (d)->d.id)
          .style('left', x)
          .style('top', y)

    ydom = _y.domain()
    fontSize = 1000/((ydom[1] - ydom[0]) * 0.0025)
    whiteboard.style('font-size', fontSize)

  bumpDomain = (scale, bump) ->
    d = scale.domain()
    scale.domain [ d[0]+bump[0], d[1]+bump[1] ]
  
  zoomIn = (n) ->
    bumpDomain(_x, [n, -n])
    bumpDomain(_y, [n, -n])
    updateNotePositions()


  pan = ->
    move = [
      _x.invert(0) - _x.invert(d3.event.webkitMovementX)
      _y.invert(0) - _y.invert(d3.event.webkitMovementY)
    ]

    bumpDomain(_x, [move[0], move[0]])
    bumpDomain(_y, [move[1], move[1]])
    updateNotePositions()
