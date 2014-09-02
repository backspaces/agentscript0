# ### Link
  
# Class Link connects two agent endpoints for graph modeling.
class ABM.Link
  # Constructor initializes instance variables:
  #
  # * id:         unique identifier, promoted by agentset create() factory method
  # * breed:      the agentset this agent belongs to
  # * from:       two agents being connected
  # * to:
  # * color:      defaults to light gray
  # * thickness:  thickness in pixels of the link, default 2
  # * label:      a text label drawn on my instances
  # * labelColor: the color of my label text
  # * labelOffset:the x, y offset of my label from my x, y location
  # * hidden:     whether or not to draw this link

  id: null               # unique id, promoted by agentset create factory method
  breed: null            # my agentSet, set by the agentSet owning me
  from: null              # My two endpoints, using agents. Promoted by ctor
  to: null
  color: [130, 130, 130] # my color
  thickness: 2           # my thickness in pixels, default to 2
  hidden: false          # draw me?
  label: null            # my text
  labelColor: [0, 0, 0]  # its color
  labelOffset: [0, 0]    # its offset from my midpoint

  constructor: (@from, @to) ->
    @from.links.push @
    @to.links.push @
      
  # Draw a line between the two endpoints. Draws "around" the
  # torus if appropriate using two lines. As with Agent.draw,
  # is called with patch coordinate transform installed.
  draw: (context) ->
    context.save()
    context.strokeStyle = u.colorString @color
    context.lineWidth = @model.patches.fromBits @thickness
    context.beginPath()

    if !@model.patches.isTorus
      context.moveTo @from.position.x, @from.position.y
      context.lineTo @to.position.x, @to.position.y
    else
      point = u.closestTorusPoint @from.position, @to.position,
        @model.patches.numX, @model.patches.numY
      context.moveTo @from.position.x, @from.position.y
      context.lineTo point.x, point.y
      if point.x isnt @to.position.x or point.y isnt @to.position.y
        point = u.closestTorusPoint @to.position, @from.position,
          @model.patches.numX, @model.patches.numY
        context.moveTo @to.position.x, @to.position.y
        context.lineTo point.x, point.y

    context.closePath()
    context.stroke()
    context.restore()

    if @label?
      x0 = u.linearInterpolate @from.position.x, @to.position.x, .5
      y0 = u.linearInterpolate @from.position.y, @to.position.y, .5
      [x, y] = @model.patches.patchXYtoPixelXY x0, y0
      u.contextDrawText context, @label, x + @labelOffset[0], y + @labelOffset[1], @labelColor
  
  # Remove this link from the agent set
  die: ->
    @breed.remove @
    @from.links.remove @
    @to.links.remove @
    null
  
  # Return the two endpoints of this link
  bothEnds: ->
    new ABM.Array(@from, @to)
  
  # Return the distance between the endpoints with the current topology.
  length: ->
    @from.distance @to.position
  
  # Return the other end of the link, given an endpoint agent.
  # Assumes the given input *is* one of the link endpoint pairs!
  otherEnd: (a) ->
    if @from is a 
      @to
    else
      @from
