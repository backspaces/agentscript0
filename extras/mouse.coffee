# A NetLogo-like mouse handler.
# See: [addEventListener](http://goo.gl/dq0nN)
u = ABM.util

class ABM.Mouse
  # Create and start mouse obj, args: a model, and a callback method.
  constructor: (@model, @callback) ->
    @lastX = Infinity; @lastY = Infinity
    @div = @model.div
    @lastAgentsHovered = []
    @draggingAgents = []
    @divOffset = @model.div.getBoundingClientRect()
    @start()
  # Start/stop the mouseListeners.  Note that NetLogo's model is to have
  # mouse move events always on, rather than starting/stopping them
  # on mouse down/up.  We may want do make that optional, using the
  # more standard down/up enabling move events.
  start: -> # Note: multiple calls safe
    @div.addEventListener("mousedown", @handleMouseDown, false)
    document.body.addEventListener("mouseup", @handleMouseUp, false)
    @div.addEventListener("mousemove", @handleMouseMove, false)
    @model.on('step', @handleStep)
    @lastX=@lastY=@x=@y=@pixX=@pixY=NaN; @moved=@down=false
  stop: -> # Note: multiple calls safe
    @div.removeEventListener("mousedown", @handleMouseDown, false)
    document.body.removeEventListener("mouseup", @handleMouseUp, false)
    @div.removeEventListener("mousemove", @handleMouseMove, false)
    @model.off('step', @handleStep)
    @lastX=@lastY=@x=@y=@pixX=@pixY=NaN; @moved=@down=false
  # Handlers for eventListeners
  handleMouseDown: (e) =>
    @down = true
    @moved = false
    @handleMouseEvent(e)
  handleMouseUp: (e) =>
    @down = false
    @moved = false    
    @handleMouseEvent(e)
  handleMouseMove: (e) =>
    @setXY(e)
    @moved = true
    @handleMouseEvent(e)
  handleStep: () =>
    @delegateMouseOverAndOutEvents(@x, @y) if not isNaN(@x)
  handleMouseEvent: (e) =>
    eventTypes = @computeEventTypes()
    @delegateEventsToAllAgents(eventTypes, e)
    @callback(e) if @callback?

  getEventPos: (e) ->
    # modified from http://www.quirksmode.org/js/events_properties.html
    # previously used e.offsetX, e.offsetY, which was less robust
    # (failed in tiledroplets.html, for example)
    xPos = 0
    yPos = 0
    if (e.pageX or e.pageY)
      xPos = e.pageX
      yPos = e.pageY
    else if (e.clientX or e.clientY)
      xPos = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft
      yPos = e.clientY + document.body.scrollTop + document.documentElement.scrollTop
    return { x: xPos - @divOffset.left, y: yPos - @divOffset.top }

  setXY: (e) ->
    eventPos = @getEventPos(e)
    @lastX = @x; @lastY = @y
    @pixX = eventPos.x; @pixY = eventPos.y
    [@x, @y] = @model.patches.pixelXYtoPatchXY(@pixX,@pixY)
    @dx = @lastX - @x; @dy = @lastY - @y

  computeEventTypes: () =>
    eventTypes = []

    if @down and not @moved
      eventTypes.push 'mousedown'

    if not @down and not @moved
      eventTypes.push 'mouseup'

    if @down and @moved
      if not @dragging
        eventTypes.push 'dragstart'
      @dragging = true

    if not @down and @dragging
      @dragging = false
      @dragEnd = true

    if @moved
      eventTypes.push 'mousemove'

    return eventTypes

  delegateEventsToAllAgents: (types, e) ->
    delegatedAgent = @delegateEventsToTurtlesAtPoint(types, @x, @y, e)
    if not delegatedAgent
      delegatedAgent = @delegateEventsToLinksAtPoint(types, @x, @y, e)
    if not delegatedAgent
      @delegateEventsToPatchAtPoint(types, @x, @y, e)
    @delegateDragEvents(@x, @y, e)
    @delegateMouseOverAndOutEvents(@x, @y, e)

  delegateEventsToPatchAtPoint: (eventTypes, x, y, e) ->
    curPatch = @model.patches.patch(x, y)
    @emitAgentEvent(type, curPatch, @mouseEvent(curPatch, e)) for type in eventTypes

  delegateEventsToTurtlesAtPoint: (eventTypes, x, y, e) ->
    curPatch = @model.patches.patch(x, y)

    # iterate through all turtles in this patch and its neighbors
    for patch in curPatch.n.concat(curPatch)
      for turtle in patch.turtlesHere()
        if turtle.hitTest(x, y)
          @emitAgentEvent(type, turtle, @mouseEvent(turtle, e)) for type in eventTypes
          return turtle

  delegateEventsToLinksAtPoint: (eventTypes, x, y, e) ->
    for link in @model.links
      if link.hitTest(x, y)
        mouseEvent = @mouseEvent(link, e)
        @emitAgentEvent(type, link, mouseEvent) for type in eventTypes
        return link

  emitAgentEvent: (eventType, agent, mouseEvent) ->
    if eventType == 'dragstart'
      @draggingAgents.push(agent)
    agent.breed.emit(eventType, mouseEvent)
    if agent.breed.mainSet?
      agent.breed.mainSet.emit(eventType, mouseEvent)

  delegateDragEvents: (x, y, e) =>
    for agent in @draggingAgents
      mouseEvent = @mouseEvent(agent, e)
      if @moved then @emitAgentEvent('drag', agent, mouseEvent)
      if @dragEnd then @emitAgentEvent('dragend', agent, mouseEvent)
    if @dragEnd
      @draggingAgents = []
      @dragEnd = false

  delegateMouseOverAndOutEvents: (x, y, e) =>
    agentsHere = {}
    agents = []
    curPatch = @model.patches.patch(x, y)
    
    agents = u.clone(@model.links)
    for patch in curPatch.n.concat(curPatch)
      agents = agents.concat(patch.turtlesHere())

    # mouseover
    for agent in agents
      if agent.hitTest(x, y)
        agentsHere[agent.breed.name] ?= {}
        agentsHere[agent.breed.name][agent.id] = agent
        if (not @lastAgentsHovered[agent.breed.name] or agent.id not of @lastAgentsHovered[agent.breed.name])
          @emitAgentEvent('mouseover', agent, @mouseEvent(agent, e))

    # mouseout
    for breedname of @lastAgentsHovered
      for agentId of @lastAgentsHovered[breedname]
        if (not agentsHere[breedname] or agentId not of agentsHere[breedname])
          agent = @lastAgentsHovered[breedname][agentId]
          @emitAgentEvent('mouseout', agent, @mouseEvent(agent, e))

    @lastAgentsHovered = agentsHere

  mouseEvent: (agent, e) -> 
    return {target: agent, patchX: @x, patchY: @y, dx: @dx, dy: @dy, originalEvent: e}
