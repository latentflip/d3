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
    nodes = tree.nodes(json)
    link = vis.selectAll('path.link')
            .data(tree.links(nodes))
          .enter().append('path')
            .attr('class', 'link')
            .attr('d', diagonal)

    nodes = vis.selectAll('g.node')
              .data(nodes, (d)->d.id)

    newNodes = nodes.enter()

    newNodes.append('g')
      .attr('class', 'node')

  

    newNodes.append('circle')
          .attr('r', 4.5)

    newNodes.append('text')
          .attr('dy', '0.31em')
          .attr('text-anchor', (d) -> if d.x < 180 then 'start' else 'end' )
          .attr('transform', (d) -> if d.x < 180 then 'translate(8)' : 'rotate(180)translate(-8)')
          .text( (d) -> d.name )

    nodes.attr('transform', (d) -> "rotate(#{d.x-90})translate(#{d.y})")


  render(json)

  id = 6
  window.addNode = ->
    json.children.push {
      id: id
      name: 'goo'
    }
    id++
    render(json)
