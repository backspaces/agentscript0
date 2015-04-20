# ### Turtles

# Class Turtles is a subclass of AgentSet which stores instances of Turtle or
# Breeds, which are subclasses of Turtle
class Turtles extends AgentSet
  # Constructor creates the empty AgentSet instance and installs
  # the agentClass (breed) variable shared by all the turtles in this set.
  constructor: -> # model, agentClass, name, mainSet
    super # call super with all the args I was called with
    #@useSprites = false

  # Have turtles cache the links with them as a node.
  # Optimizes Turtle a.myLinks method. Call before any turtles created.
  cacheLinks: -> @agentClass::cacheLinks = true # all turtles, not individual breeds

  # Use sprites rather than drawing
  setUseSprites: (useSprites=true) ->
    u.deprecated 'Turtles.setUseSprites: use turtles.setDefault("useSprites",bool)'
    @setDefault("useSprites", useSprites)

  # Factory: create num new turtles stored in this agentset. The optional init
  # function is called on the new turtle after inserting in its agentset.
  create: (num, init = ->) -> # returns array of new turtles too
    ((o) -> init(o); o) @add new @agentClass for i in [1..num] by 1 # too tricky?

  # Remove all turtles from set via turtle.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list

  # Filter to return all instances of this breed.  Note: if used by
  # the mainSet, returns just the turtles that are not subclassed breeds.
  breedsIn: (array) -> @asSet (o for o in array when o.breed is @)

  # Return an agentset of this breed within the patch array
  inPatches: (patches) ->
    array = []
    array.push p.turtlesHere()... for p in patches # concat measured slower
    # Possibly faster to filter by breed in p.breedsHere?
    if @mainSet? then @breedsIn array else @asSet array

  # Return an agentset of turtles/breeds within the patchRect, dx/y integers
  inRect: (p, dx, dy=dx) ->
    rect = @model.patches.patchRect p, dx, dy #, true
    @inPatches rect

  # Return the members of this agentset that are within radius distance
  # from me, using patch topology
  inRadius: (agent, radius) ->
    as = @inRect( (agent.p ? agent), Math.ceil(radius) )
    as.inRadius agent, radius

  # Return the members of this agentset that are within radius distance
  # from agent, and within cone of angle, heading from agent
  # using patch topology
  inCone: (agent, radius, angle, heading) ->
    as = @inRect( (agent.p ? agent), Math.ceil(radius) )
    as.inCone agent, radius, angle, heading

  setDraggable: ->
    @on 'dragstart', (mouseEvent) =>
      mouseEvent.target.dragging = true

    @on 'dragend', (mouseEvent) =>
      mouseEvent.target.dragging = false

    @on 'drag', (mouseEvent) =>
      mouseEvent.target.setXY(mouseEvent.patchX, mouseEvent.patchY)
