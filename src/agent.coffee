
# Class Agent instances represent the dynamic, behavioral element of modeling.
# Each agent knows the patch it is on, and interacts with that and other
# patches, as well as other agents.
class Agent
  # Constructor & Class Variables:
  #
  # * id:         unique identifier, promoted by agentset create() factory method
  # * breed:      the agentset this agent belongs to
  # * x,y:        position on the patch grid, in patch coordinates, default: 0,0
  # * size:       size of agent, in patch coords, default: 1
  # * color:      the color of the agent, default: randomColor
  # * shape:      the shape name of the agent, default: "default"
  # * label:      a text label drawn on my instances
  # * labelColor: the color of my label text
  # * labelOffset:the x,y offset of my label from my x,y location
  # * heading:    direction of the agent, in radians, from x-axis
  # * hidden:     whether or not to draw this agent
  # * p:          patch at current x,y location
  # * penDown:    true if agent pen is drawing
  # * penSize:    size in pixels of the pen, default: 1 pixel
  # * sprite:     an image of the agent if non null
  # * cacheLinks: if true, keep array of links in/out of me
  # * links:      array of links in/out of me.  Only used if @cacheLinks is true
  #
  # These class variables are "defaults" and many are "promoted" to instance variables.
  # To have these be set to a constant for all instances, use breed.setDefault.
  # This can be a huge savings in memory.
  id: null            # unique id, promoted by agentset create factory method
  breed: null         # my agentSet, set by the agentSet owning me
  x: 0; y:0; p: null  # my location and the patch I'm on
  size: 1             # my size in patch coords
  color: null         # default color, overrides random color if set
  strokeColor: null   # color of the border of an agent
  shape: "default"    # my shape
  hidden: false       # draw me?
  label: null         # my text
  labelColor: [0,0,0] # its color
  labelOffset: [0,0]  # its offset from my x,y
  penDown: false      # if my pen is down, I draw my path between changes in x,y
  penSize: 1          # the pen thickness in pixels
  heading: null       # the direction I'm pointed in, in radians
  sprite: null        # an image of me for optimized drawing
  useSprites: false   # should I use sprites?
  cacheLinks: false   # should I keep links to/from me in links array?.
  links: null         # array of links to/from me as an endpoint; init by ctor
  constructor: -> # called by agentSets create factory, not user
    @x = @y = 0
    @p = @model.patches.patch @x, @y
    @color = u.randomColor() unless @color? # or @useSprites or @hidden
    @heading = u.randomFloat(Math.PI*2) unless @heading?
    @p.agents.push @ if @p.agents? # @model.patches.cacheAgentsHere
    @links = [] if @cacheLinks

  # Set agent color to `c` scaled by `s`. Usage: see patch.scaleColor
  scaleColor: (c, s) ->
    u.deprecated "Agent.scaleColor: use ColorMaps ramps or closestColor"
    @color = ColorMaps.scaleColor(c, s)
    # @color = u.clone @color unless @hasOwnProperty "color" # promote color to inst var
    # u.scaleColor c, s, @color

  scaleOpacity: (c, s) ->
    u.deprecated "Agent.scaleOpacity: use ColorMaps ramps"
    @color = u.scaleOpacity c, s, @color
    # @color = u.clone @color unless @hasOwnProperty "color"
    # u.scaleOpacity c, s, @color

  # Return a string representation of the agent.
  toString: -> "{id:#{@id} xy:#{u.aToFixed [@x,@y]} c:#{@color.css} h: #{h=@heading.toFixed 2}/#{Math.round(u.radToDeg(h))}}"

  # Place the agent at the given x,y (floats) in patch coords
  # using patch topology (isTorus)
  setXY: (x, y) -> # REMIND GC problem, 2 arrays
    [x0, y0] = [@x, @y] if @penDown
    [@x, @y] = @model.patches.coord x, y
    p = @p
    @p = @model.patches.patch @x, @y
    if p.agents? and p isnt @p # @model.patches.cacheAgentsHere
      u.removeItem p.agents, @
      @p.agents.push @
    if @penDown
      drawing = @model.drawing
      drawing.strokeStyle = @color.css # u.colorStr @color
      drawing.lineWidth = @model.patches.fromBits @penSize
      drawing.beginPath()
      drawing.moveTo x0, y0; drawing.lineTo x, y # REMIND: euclidean
      drawing.stroke()

  # Place the agent at the given patch/agent location
  moveTo: (a) -> @setXY a.x, a.y

  # Move forward (along heading) d units (patch coords),
  # using patch topology (isTorus)
  forward: (d) ->
    @setXY @x + d*Math.cos(@heading), @y + d*Math.sin(@heading)

  # Change current heading by rad radians which can be + (left) or - (right).
  # Returns new heading.
  rotate: (rad) -> @heading = u.wrap @heading + rad, 0, Math.PI*2
  right: (rad) -> @rotate -rad
  left: (rad) -> @rotate rad

  # Draw the agent, instanciating a sprite if required
  draw: (ctx) ->
    shape = Shapes[@shape]
    rad = if shape.rotate then @heading else 0 # radians
    if @sprite? or @useSprites # @breed.useSprites
      @setSprite() unless @sprite? # lazy evaluation of useSprites
      Shapes.drawSprite ctx, @sprite, @x, @y, @size, rad
    else
      Shapes.draw ctx, shape, @x, @y, @size, rad, @color, @strokeColor
    if @label?
      [x,y] = @model.patches.patchXYtoPixelXY @x, @y
      u.ctxDrawText ctx, @label,
        x+@labelOffset[0], y+@labelOffset[1], @labelColor

  # Set an individual agent's sprite, synching its color, shape, size
  setSprite: (sprite)->
    if (s=sprite)?
      @sprite = s; @color = s.color; @strokeColor = s.strokeColor
      @shape = s.shape; @size = @model.patches.fromBits(s.size)
    else
      # @color = u.randomColor() unless @color? # not needed if lazy evaluation
      @sprite = Shapes.shapeToSprite @shape, @color,
        @model.patches.toBits(@size), @strokeColor

  # Draw the agent on the drawing layer, leaving permanent image.
  stamp: -> @draw @model.drawing

  # Return distance in patch coords from me to x,y
  # using patch topology (isTorus)
  distanceXY: (x,y) ->
    if @model.patches.isTorus
    then u.torusDistance @x, @y, x, y, @model.patches.numX, @model.patches.numY
    else u.distance @x, @y, x, y

  # Return distance in patch coords from me to given agent/patch using patch topology.
  distance: (o) -> # o any object w/ x,y, patch or agent
    @distanceXY o.x, o.y

  # Return the closest torus topology point of given x,y relative to myself.
  # Used internally to determine how to draw links between two agents.
  # See util.torusPt.
  torusPtXY: (x, y) ->
    u.torusPt @x, @y, x, y, @model.patches.numX, @model.patches.numY

  # Return the closest torus topology point of given agent/patch
  # relative to myself. See util.torusPt.
  torusPt: (o) ->
    @torusPtXY o.x, o.y

  # Set my heading towards given agent/patch using patch topology.
  face: (o) -> @heading = @towards o

  # Return heading towards x,y using patch topology.
  towardsXY: (x, y) ->
    if (ps=@model.patches).isTorus
    then u.torusRadsToward @x, @y, x, y, ps.numX, ps.numY
    else u.radsToward @x, @y, x, y

  # Return heading towards given agent/patch using patch topology.
  towards: (o) -> @towardsXY o.x, o.y

  # Return patch ahead of me by given distance and heading.
  # Returns null if non-torus and off patch world.
  # Heading is + for left, - for right.
  patchAtHeadingAndDistance: (h,d) ->
    [dx,dy] = u.polarToXY d, h + @heading
    @patchAt dx,dy
  patchLeftAndAhead: (dh, d) -> @patchAtHeadingAndDistance dh, d
  patchRightAndAhead: (dh, d) -> @patchAtHeadingAndDistance -dh, d
  patchAhead: (d) -> @patchAtHeadingAndDistance 0, d
  canMove: (d) -> @patchAhead(d)?
  patchAt: (dx,dy) ->
    x=@x+dx; y=@y+dy
    if (ps=@model.patches).isOnWorld x,y then ps.patch x,y else null

  # Remove myself from the model.  Includes removing myself from the agents
  # agentset and removing any links I may have.
  die: ->
    @breed.remove @
    l.die() for l in @myLinks() by -1
    u.removeItem @p.agents, @ if @p.agents?
    null

  # Factory: create num new agents at this agents location. The optional init
  # proc is called on the new agent after inserting in its agentSet.
  hatch: (num = 1, breed = @breed, init = ->) ->
    breed.create num, (a) => # fat arrow so that @ = this agent
      a.setXY @x, @y # for side effects like patches.agentsHere
      a.color = @color
      a[k] = @[k] for k in breed.ownVariables when a[k] is null # hatched agent inherits parents' breed properties
      # possible alternative: a[k] = @[k] for k, v in a when v is null
      init(a); a # Important: init called after object inserted in agent set

  # Return the members of the given agentset that are within radius distance
  # from me, using patch topology
  inRadius: (aset, radius) ->
    aset.inRadius(@, radius)

  # Return the members of the given agentset that are within distance
  # from me, and within angle radians of my heading using patch topology
  inCone: (aset, distance, angle) ->
    aset.inCone @, distance, angle, @heading

  # Return true if world coordinate falls on agent sprite
  hitTest: (x, y) ->
    @distanceXY(x, y) < @size

  # Return other end of link from me
  otherEnd: (l) -> if l.end1 is @ then l.end2 else l.end1

  # Return all links linked to me
  myLinks: ->
    @links ? (l for l in @model.links when (l.end1 is @) or (l.end2 is @))

  # Return all agents linked to me.
  linkNeighbors: -> # return all agents linked to me
    @otherEnd l for l in @myLinks()

  # Return links where I am the "to" agent in links.create
  myInLinks: ->
    l for l in @myLinks() when l.end2 is @

  # Return other end of myInLinks
  inLinkNeighbors: ->
    l.end1 for l in @myLinks() when l.end2 is @

  # Return links where I am the "from" agent in links.create
  myOutLinks: ->
    l for l in @myLinks() when l.end1 is @

  # Return other end of myOutinks
  outLinkNeighbors: ->
    l.end2 for l in @myLinks() when l.end1 is @

# use colorMixin to setup colors
colorMixin(Agent, "color", null)
colorMixin(Agent, "strokeColor", null)
colorMixin(Agent, "labelColor", "black")
