# Class CanvasTileView renders agents, links, and patches in canvas tiles

# ### Class CanvasTileView

class CanvasTileView
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

    # Initialize the Leaflet map
    @map = L.map(opts.div, {
      center: [90, -180],
      zoom: 0,
      crs: L.extend({}, L.CRS.EPSG3857, {
        wrapLat: null, wrapLng: null, infinite: true
      })
    })

    # Center the world
    @map.panTo(@map.unproject([@world.pxWidth / 2, @world.pxHeight / 2]))
    
    @createCtxs()
    u.waitOn((=> @model.modelReady), (=> @createTileLayer()))

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
    # for own k,v of @contextsInit
    #   @contexts[k] = @createTileLayer()

    # # One of the layers is used for drawing only, not an agentset:
    # @drawing = @contexts.drawing
    # @drawing.clear = => u.clearCtx @drawing
    # # Setup spotlight layer, also not an agentset:
    # @contexts.spotlight.globalCompositeOperation = "xor"
    return @contexts

  createTileLayer: () ->
    tileLayer = @tileLayer = new L.TileLayer.Canvas({
      continuousWorld: true
    })

    tileLayer.drawTile = @initTileRendering

    tileLayer.addTo(@map)

    return tileLayer

  initTileRendering: (canvas, tilePoint, zoom) =>
    renderTile = @getDrawTileClosure(canvas, tilePoint, zoom)

    if not renderTile?
      return

    @model.on('draw', renderTile)
    
    @map.on('zoomstart', () =>
      @model.off('draw', renderTile)
    )

    @map.on('layerremove', (e) =>
      if (e.layer is @tileLayer)
        @model.off('draw', renderTile)
    )

  getDrawTileClosure: (canvas, tilePoint, zoom) ->
    @zoom = zoom
    @zoomScale = zoomScale = Math.pow(2, zoom)
    
    ctx = canvas.getContext('2d')

    # world coordinates of tile corners
    tileTopLeft = [canvas.width * tilePoint.x, canvas.height * tilePoint.y]
    tileBottomRight = [tileTopLeft[0] + canvas.width, tileTopLeft[1] + canvas.height]

    # patch float coordinates of tile corners
    tileTopLeftPatchCoord = @pixelCoordToPatchCoord(tileTopLeft[0], tileTopLeft[1], zoom)
    tileBottomRightPatchCoord = @pixelCoordToPatchCoord(tileBottomRight[0], tileBottomRight[1], zoom)

    # integer coordinates of patches beneath tile corners
    leftPatchX = Math.floor(tileTopLeftPatchCoord[0])
    rightPatchX = Math.ceil(tileBottomRightPatchCoord[0])
    bottomPatchY = Math.floor(tileBottomRightPatchCoord[1])
    topPatchY = Math.ceil(tileTopLeftPatchCoord[1])

    # don't draw tiles that have no patches on them
    if leftPatchX > @world.maxX or topPatchY < @world.minY or rightPatchX < @world.minX or bottomPatchY > @world.maxY
      return

    return () =>
      ctx.clearRect(0, 0, canvas.width, canvas.height)

      ctx.save()
      ctx.translate(-tileTopLeft[0], -tileTopLeft[1])

      agentsToRender = []

      for x in [leftPatchX..rightPatchX]
        for y in [bottomPatchY..topPatchY]

          curPatch = @model.patches.patch(x, y)
          @renderPatch(ctx, curPatch)

          if @debugging then @renderPatchBorder(ctx, curPatch)

          agentsToRender = agentsToRender.concat(curPatch.agentsHere())

      for agent in agentsToRender
        @renderAgent(ctx, agent)

      ctx.restore()

      if @debugging then @drawCanvasTile(canvas, tilePoint)
          
  renderLink: (ctx, link) ->
    end1Pos = @patchCoordToPixelCoord(link.end1.x, link.end1.y, @zoom)
    end2Pos = @patchCoordToPixelCoord(link.end2.x, link.end2.y, @zoom)

    ctx.save()
    ctx.strokeStyle = u.colorStr link.color
    ctx.lineWidth = @model.patches.fromBits @thickness
    ctx.beginPath()
    if !@model.patches.isTorus
      ctx.moveTo end1Pos[0], end1Pos[1]
      ctx.lineTo end2Pos[0], end2Pos[1]
    else
      pt = @end1.torusPt @end2
      ptPos = @patchCoordToPixelCoord(pt[0], pt[1], @zoom)
      ctx.moveTo end1Pos[0], end1Pos[1]
      ctx.lineTo ptPos...
      if pt[0] isnt end2Pos[0] or pt[1] isnt end2Pos[1]
        pt = @end2.torusPt @end1
        ptPos = @patchCoordToPixelCoord(pt[0], pt[1], @zoom)
        ctx.moveTo end2Pos[0], end2Pos[1]
        ctx.lineTo ptPos...
    ctx.closePath()
    ctx.stroke()
    ctx.restore()

  renderAgent: (ctx, agent) ->
    shape = ABM.shapes[agent.shape]
    drawPos = @patchCoordToPixelCoord(agent.x, agent.y, @zoom)
    # Couple of weirdnesses here. In the default view, the canvas
    # is scaled by @world.size and the y-axis is inverted. Our canvas tiles
    # have not had these transformations applied, so we have to multiply by @world.size
    # manually, and we draw with -agent.heading instead of agent.heading
    scaledSize = agent.size * @world.size * @zoomScale
    ABM.shapes.draw(ctx, shape, drawPos[0], drawPos[1], scaledSize, -agent.heading, agent.color)

  renderPatch: (ctx, patch) ->
    patchSize = @world.size # without zoom, how many pixels in a patch
    zoomedPatchSize = @zoomScale * patchSize # at this zoom, how many pixels in a patch

    patchCenter = @patchCoordToPixelCoord(patch.x, patch.y, @zoom)
    patchTop = patchCenter[1] + zoomedPatchSize/2
    patchLeft = patchCenter[0] - zoomedPatchSize/2
    
    startX = patchLeft
    startY = patchTop

    ctx.beginPath()
    ctx.moveTo(startX, startY)
    ctx.lineTo(startX + zoomedPatchSize, startY)
    ctx.lineTo(startX + zoomedPatchSize, startY - zoomedPatchSize)
    ctx.lineTo(startX, startY - zoomedPatchSize)
    ctx.closePath()
    ctx.fillStyle = u.colorStr(patch.color)
    ctx.fill()

  pixelCoordToPatchCoord: (x, y, zoom) ->
    zoomScale = Math.pow(2, zoom)
    unzoomedX = x / zoomScale
    unzoomedY = y / zoomScale
    return @model.patches.pixelXYtoPatchXY(unzoomedX, unzoomedY)

  patchCoordToPixelCoord: (x, y, zoom) ->
    zoomScale = Math.pow(2, zoom)
    pixelCoord = @model.patches.patchXYtoPixelXY(x, y)
    zoomedX = pixelCoord[0] * zoomScale
    zoomedY = pixelCoord[1] * zoomScale
    return [zoomedX, zoomedY]

  # clear/resize canvas transforms
  reset: () ->
    # (v.restore(); @setCtxTransform v) for k,v of @contexts when v.canvas?

  # Call the agentset draw methods if either the first draw call or
  # their "refresh" flags are set.  The latter are simple optimizations
  # to avoid redrawing the same static scene. 
  draw: (force) ->
    # @model.patches.draw @contexts.patches  if force or @refreshPatches or @anim.draws is 1
    # @model.links.draw   @contexts.links    if force or @refreshLinks   or @anim.draws is 1
    # @model.agents.draw  @contexts.agents   if force or @refreshAgents  or @anim.draws is 1
    # @drawSpotlight @model.spotlightAgent, @contexts.spotlight  if @model.spotlightAgent?

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

  ## debugging drawing utilities

  debug: (@debugging = true) ->

  drawCanvasTile: (canvas, tilePoint) ->
    ctx = canvas.getContext('2d')
    ctx.strokeStyle = 'rgb(0,0,0)'
    ctx.fillStyle = 'rgb(0,0,0)'
    ctx.strokeRect(0, 0, canvas.width, canvas.height)
    ctx.textAlign = 'center'
    ctx.fillText("tile (#{tilePoint.x}, #{tilePoint.y})", canvas.width/2, canvas.height/2)

  renderPatchBorder: (ctx, patch) ->
    patchSize = @world.size # without zoom, how many pixels in a patch
    zoomedPatchSize = @zoomScale * patchSize # at this zoom, how many pixels in a patch

    patchCenter = @patchCoordToPixelCoord(patch.x, patch.y, @zoom)
    patchTop = patchCenter[1] + zoomedPatchSize/2
    patchLeft = patchCenter[0] - zoomedPatchSize/2
    
    startX = patchLeft
    startY = patchTop
    # startX = patchLeft - tileTopLeft[0]
    # startY = patchTop - tileTopLeft[1]

    ctx.beginPath()
    ctx.moveTo(startX, startY)
    ctx.lineTo(startX + zoomedPatchSize, startY)
    ctx.lineTo(startX + zoomedPatchSize, startY - zoomedPatchSize)
    ctx.lineTo(startX, startY - zoomedPatchSize)
    ctx.closePath()
    ctx.strokeStyle = 'rgb(0,0,255)'
    ctx.stroke()
