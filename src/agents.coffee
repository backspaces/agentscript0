# ### Agents

# Class Agents is a subclass of AgentSet which stores instances of Agent or
# Breeds, which are subclasses of Agent
class Agents extends AgentSet
  # Constructor creates the empty AgentSet instance and installs
  # the agentClass (breed) variable shared by all the Agents in this set.
  constructor: -> # model, agentClass, name, mainSet
    super # call super with all the args I was called with
    #@useSprites = false

  # Have agents cache the links with them as a node.
  # Optimizes Agent a.myLinks method. Call before any agents created.
  cacheLinks: -> @agentClass::cacheLinks = true # all agents, not individual breeds

  # Use sprites rather than drawing
  setUseSprites: (useSprites=true) ->
    u.deprecated 'Agents.setUseSprites: use agents.setDefault("useSprites",bool)'
    @setDefault("useSprites", useSprites)


  # Filter to return all instances of this breed.  Note: if used by
  # the mainSet, returns just the agents that are not subclassed breeds.
  breedsIn: (array) -> @asSet (o for o in array when o.breed is @)

  # Factory: create num new agents stored in this agentset.The optional init
  # proc is called on the new agent after inserting in its agentSet.
  create: (num, init = ->) -> # returns array of new agents too
    ((o) -> init(o); o) @add new @agentClass for i in [1..num] by 1 # too tricky?

  # Remove all agents from set via agent.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list

  # Return an agentset of this breed within the patch array
  inPatches: (patches) ->
    array = []
    array.push p.agentsHere()... for p in patches # concat measured slower
    # Possibly faster to filter by breed in p.breedsHere?
    if @mainSet? then @breedsIn array else @asSet array

  # Return an agentset of agents/breeds within the patchRect
  inRect: (a, dx, dy, meToo=false) ->
    rect = @model.patches.patchRect a.p, dx, dy, true
    rect = @inPatches rect
    u.removeItem rect, a unless meToo
    rect

  # Return the members of this agentset that are within radius distance
  # from me, and within cone radians of my heading using patch topology
  inCone: (a, heading, cone, radius, meToo=false) -> # heading? .. so p ok?
    as = @inRect a, radius, radius, true
    # super a, heading, cone, radius, meToo
    as.inCone a, heading, cone, radius, meToo

  # Return the members of this agentset that are within radius distance
  # from me, using patch topology
  inRadius: (a, radius, meToo=false)->
    as = @inRect a, radius, radius, true
    # super a, radius, meToo
    as.inRadius a, radius, meToo

  setDraggable: ->
    @on 'dragstart', (mouseEvent) =>
      mouseEvent.target.dragging = true

    @on 'dragend', (mouseEvent) =>
      mouseEvent.target.dragging = false

    @on 'drag', (mouseEvent) =>
      mouseEvent.target.setXY(mouseEvent.patchX, mouseEvent.patchY)
