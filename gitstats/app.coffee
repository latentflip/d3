console.jlog = (d) ->
  console.log JSON.stringify(d)


require ['d3', 'underscore'], (d3, _) ->
  config =
    width: 25000
    height: 500
    margin: 20
  
  svg = d3.select('body').append('svg')
            .attr('height', config.height)
            .attr('width', config.width)


  xaxis = d3.scale.linear()
          .range([config.margin,config.width-config.margin])

  yaxis = d3.scale.linear()
          .range([config.margin, config.height-config.margin])

  x = xaxis
  y = (args...) ->
    config.height - yaxis(args...)

  d3.json 'gitstats.json', (coll) ->
    data = []
    last = null
    for c in coll
      if data.length == 0
        c.cumulative_lines = (c.insertions||0) - (c.deletions||0)
        data.push c
        last = c
      else
        c.cumulative_lines = last.cumulative_lines + (c.insertions||0) - (c.deletions||0)
        data.push c
        last = c

    xaxis.domain [data[0].date, data[data.length-1].date]
    
    ymin = d3.min data, (d)->d.cumulative_lines - (d.deletions||0)
    ymax = d3.max data, (d)->d.cumulative_lines + (d.insertions||0)
    yaxis.domain [ymin, ymax]
    
    commits = svg.selectAll('g.commit')
                .data( data, (d)->d.sha)

    entered = commits.enter()
                .append('svg:g')
                .attr('class', 'commit')


    entered.append('circle')
              .attr('r', (d)->5)
              .attr('cx', (d)->x(d.date))
              .attr('cy', (d)->y(d.cumulative_lines))
              .on('mouseover', (d)->console.log(d))
    
    entered.append('line')
              .attr('class', 'added')
              .attr('x1', (d)->x(d.date))
              .attr('x2', (d)->x(d.date))
              .attr('y1', (d)->y(d.cumulative_lines))
              .attr('y2', (d)->
                if d.insertions
                  y(d.cumulative_lines) - 10*Math.log(10*d.insertions)
                else
                  y(d.cumulative_lines)

              )

    entered.append('line')
              .attr('class', 'deleted')
              .attr('x1', (d)->x(d.date))
              .attr('x2', (d)->x(d.date))
              .attr('y1', (d)->y(d.cumulative_lines))
              .attr('y2', (d)->
                if d.deletions
                  x = y(d.cumulative_lines)+10*Math.log(10*d.deletions)
                  console.log 'x', 10*Math.log(d.deletions*10), d.deletions
                  x
                else
                  y(d.cumulative_lines)
              )
              
    
