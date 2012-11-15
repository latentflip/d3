require ['d3', 'underscore'], (d3, _) ->
  
  json = {
    id: 1
    name: "today",
    children: [
      {
        id: 2
        name: "foo",
        children: [
          {
            id: 3
            name: 'hats',
            children: []
          }
        ]
      },
      {
        id: 4
        name: "cheese",
        children: []
      },
      {
        id: 5
        name: 'potatoes'
      }
    ]
  }

  width = 960
  height = 600
  
  cluster = d3.layout.cluster()
              .size([height, width - 160])
  
  diagonal = d3.svg.diagonal()
                .projection( (d) -> [d.y, d.x] )
  
  vis = d3.select("body").append("svg")
            .attr("width", width)
            .attr("height", height)
          .append("g")
            .attr("transform", "translate(40, 0)")
  
  render = (json) ->
    nodes = cluster.nodes(json)
    
    link = vis.selectAll("path.link")
                  .data(cluster.links(nodes))
                .enter().append("path")
                  .attr("class", "link")
                  .attr("d", diagonal)
    
    node = vis.selectAll("g.node")
                .data(nodes)
              .enter().append("g")
                .attr("class", "node")
                .attr("transform", (d) -> "translate(" + d.y + "," + d.x + ")" )
    
    node.append("circle")
          .attr("r", 4.5)

    node.append("text")
        .attr("dx", (d) -> d.children ? -8 : 8 )
        .attr("dy", 3)
        .attr("text-anchor", (d) -> d.children ? "end" : "start" )
        .text( (d) -> d.name )

  render(json)
  window.addNode = ->
    json.children.push {
      name: 'goo'
    }
    render(json)

###

  c =
    height: 600
    width: 1024
    radius: 960/2


  tree = d3.layout.tree()
              .size([360, c.radius-200])
              .separation( (a,b) ->
                if a.parent == b.parent
                  1/a.depth
                else
                  2/a.depth
              )

  diagonal = d3.svg.diagonal.radial()
              .projection( (d) -> [d.y, d.x/180*Math.PI])


  vis = d3.select('body').append('svg')
            .attr('height', c.radius*2)
            .attr('width', c.radius*2-150)
          .append('g')
            .attr('transform', "translate(#{c.radius},#{c.radius})")

  

  link = null
  node = null
  nodes = null

  render = (data) ->
    d = {} 
    d.nodes = tree.nodes(data)
    d.links = tree.links(d.nodes)

    links = vis.selectAll('path.link')
            .data(d.links, (d)->"#{d.source.id}-#{d.target.id}")

    links.enter().append('path')
          .attr('class', 'link')

    links
      .transition().duration(500)
      .attr('d', diagonal)
        

    nodes = vis.selectAll('g.node')
              .data(d.nodes, (d)->d.id)


    new_nodes = nodes.enter()

    new_nodes
        .append('g')
          .attr('class', 'node')

    new_nodes
        .append('circle')
          .attr('r', 4.5)

    nodes
      .transition().duration(500)
      .attr('transform', (d) ->
        s = "rotate(#{d.x-90})translate(#{d.y})"
        console.log s
        s
      )

    #new_nodes
    #    .append('text')
    #      .attr('dy', '0.31em')
    #      .attr('text-anchor', (d) -> if d.x < 180 then 'start' else 'end' )
    #      .attr('transform', (d) -> if d.x < 180 then 'translate(8)' : 'rotate(180)translate(-8)')
    #      .text( (d) -> d.name )

    #nodes.selectAll('text')
    #      .transition().duration(500)
    #      .attr('text-anchor', (d) -> if d.x < 180 then 'start' else 'end' )
    #      .attr('transform', (d) -> if d.x < 180 then 'translate(8)' : 'rotate(180)translate(-8)')


  render(json)

  id = 6
  window.addNode = ->
    json.children.push {
      id: id
      name: 'goo'
    }
    id++
    render(json)
