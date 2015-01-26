# Class CanvasView renders agents, links, and patches in a stack of canvases

# ### Class CanvasView

class CanvasView
  # Class variable for layers parameters.
  # Can be added to by programmer to modify/create layers, **before** starting your own model.
  # Example:
  #
  #     v.z++ for k,v of CanvasView::contextsInit # increase each z value by one
  contextsInit: { # Experimental: image:   {z:15,  ctx:"img"}
    patches:   {z:10, ctx:"2d"}
    drawing:   {z:20, ctx:"2d"}
    links:     {z:30, ctx:"2d"}
    agents:    {z:40, ctx:"2d"}
    spotlight: {z:50, ctx:"2d"}
  },

  constructor: (@model, opts) ->
    # Calculate world size in pixels
    @setWorld opts
    
    # Set drawing controls.  Default to drawing each agentset.
    # Optimization: If any of these is set to false, the associated
    # agentset is drawn only once, remaining static after that.
    @refreshLinks = @refreshAgents = @refreshPatches = true

    # Style the parent div and create rendering contexts 
    (@div=document.getElementById(opts.div)).setAttribute 'style',
        "position:relative; width:#{@world.pxWidth}px; height:#{@world.pxHeight}px"
    @createCtxs()

  createCtxs: () ->
    # * Create 2D canvas contexts layered on top of each other.
    # * Initialize a patch coord transform for each layer.
    #
    # Note: this transform is permanent .. there isn't the usual ctx.restore().
    # To use the original canvas 2D transform temporarily:
    #
    #     u.setIdentity ctx
    #       <draw in native coord system>
    #     ctx.restore() # restore patch coord system
    @contexts = {}
    for own k,v of @contextsInit
      @contexts[k] = ctx = u.createLayer @div, @world.pxWidth, @world.pxHeight, v.z, v.ctx
      @setCtxTransform ctx if ctx.canvas?
      if ctx.canvas? then ctx.canvas.style.pointerEvents = 'none'
      u.elementTextParams ctx, "10px sans-serif", "center", "middle"

    # One of the layers is used for drawing only, not an agentset:
    @drawing = @contexts.drawing
    @drawing.clear = => u.clearCtx @drawing
    # Setup spotlight layer, also not an agentset:
    @contexts.spotlight.globalCompositeOperation = "xor"
    return @contexts

  setCtxTransform: (ctx) ->
    ctx.canvas.width = @world.pxWidth; ctx.canvas.height = @world.pxHeight
    ctx.save()
    ctx.scale @world.size, -@world.size
    ctx.translate -(@world.minXcor), -(@world.maxYcor)

  # clear/resize canvas transforms
  reset: () ->
    (v.restore(); @setCtxTransform v) for k,v of @contexts when v.canvas?

  # Call the agentset draw methods if either the first draw call or
  # their "refresh" flags are set.  The latter are simple optimizations
  # to avoid redrawing the same static scene. 
  draw: (force) ->
    @model.patches.draw @contexts.patches  if force or @refreshPatches or @anim.draws is 1
    @model.links.draw   @contexts.links    if force or @refreshLinks   or @anim.draws is 1
    @model.agents.draw  @contexts.agents   if force or @refreshAgents  or @anim.draws is 1
    @drawSpotlight @model.spotlightAgent, @contexts.spotlight  if @model.spotlightAgent?

  # Direct install image into the given context, not async.
  installDrawing: (img, ctx=@contexts.drawing) ->
    u.setIdentity ctx
    ctx.drawImage img, 0, 0, ctx.canvas.width, ctx.canvas.height
    ctx.restore() # restore patch transform

  # Creates a spotlight effect on an agent, so we can follow it throughout the model.
  setSpotlight: (spotlightAgent) ->
    u.clearCtx @contexts.spotlight unless spotlightAgent?

  drawSpotlight: (agent, ctx) ->
    u.clearCtx ctx
    u.fillCtx ctx, [0,0,0,0.6]
    ctx.beginPath()
    ctx.arc agent.x, agent.y, 3, 0, 2*Math.PI, false
    ctx.fill()

  # Initialize/reset world parameters.
  setWorld: (opts) ->
    w = defaults = { size: 13, minX: -16, maxX: 16, minY: -16, maxY: 16, isTorus: false, hasNeighbors: true, isHeadless: false }
    for own k,v of opts
      w[k] = v
    {size, minX, maxX, minY, maxY, isTorus, hasNeighbors, isHeadless} = w
    numX = maxX-minX+1; numY = maxY-minY+1; pxWidth = numX*size; pxHeight = numY*size
    minXcor=minX-.5; maxXcor=maxX+.5; minYcor=minY-.5; maxYcor=maxY+.5
    @world = {size,minX,maxX,minY,maxY,minXcor,maxXcor,minYcor,maxYcor,
      numX,numY,pxWidth,pxHeight,isTorus,hasNeighbors,isHeadless}
