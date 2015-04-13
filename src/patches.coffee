# ### Patches

# Class Patches is a singleton 2D matrix of Patch instances, each patch
# representing a 1x1 square in patch coordinates (via 2D coord transforms).
#
# From @model.world, set in Model:
#
# * size:         pixel h/w of each patch.
# * minX/maxX:    min/max x coord in patch coords
# * minY/maxY:    min/max y coord in patch coords
# * numX/numY:    width/height of grid.
# * isTorus:      true if coord system wraps around at edges
# * hasNeighbors: true if each patch caches its neighbors
# * isHeadless:   true if not using canvas drawing
class Patches extends AgentSet
  # Constructor: super creates the empty AgentSet instance and installs
  # the agentClass (breed) variable shared by all the Patches in this set.
  # Patches are created from top-left to bottom-right to match data sets.
  constructor: -> # model, agentClass, name, mainSet
    super # call super with all the args I was called with
    @monochrome = false # set to true to optimize patches all default color
    @[k] = v for own k,v of @model.world # add world items to patches
    @populate() unless @mainSet?

  # Setup patch world from world parameters.
  # Note that this is done as separate method so like other agentsets,
  # patches are started up empty and filled by "create" calls.
  populate: -> # TopLeft to BottomRight, exactly as canvas imagedata
    for y in [@maxY..@minY] by -1
      for x in [@minX..@maxX] by 1
        @add new @agentClass x, y
    @setNeighbors() if @hasNeighbors
    @setPixels() if @model.div? # setup off-page canvas for pixel ops

  # Have patches cache the agents currently on them.
  # Optimizes p.agentsHere method.
  # Call before first agent is created.
  cacheAgentsHere: -> p.agents = [] for p in @; null

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support smoothing flags.
  usePixels: (@drawWithPixels=true) ->
    ctx = @model.contexts.patches
    u.setCtxSmoothing ctx, not @drawWithPixels

  # Optimization: Cache a single set by modeler for use by patchRect,
  # inCone, inRect, inRadius.  Ex: flock demo model's vision rect.
  cacheRect: (radius, meToo=true) ->
    for p in @
      p.pRect = @patchRect p, radius, radius, meToo
      p.pRect.radius = radius
    null # avoid CS returning huge array!

  # Install neighborhoods in patches
  setNeighbors: ->
    for p in @
      p.n =  @patchRect p, 1, 1, false
      p.n4 = @asSet (n for n in p.n when n.x is p.x or n.y is p.y)
    null # radius # avoid CS returning huge array!

  # Setup pixels used for `drawScaledPixels` and `importColors`
  #
  setPixels: ->
    if @size is 1
    then @usePixels(); @pixelsCtx = @model.contexts.patches
    else @pixelsCtx = u.createCtx @numX, @numY
    @pixelsImageData = @pixelsCtx.getImageData(0, 0, @numX, @numY)
    @pixelsData = @pixelsImageData.data
    if @pixelsData instanceof Uint8Array # Check for typed arrays
      @pixelsData32 = new Uint32Array @pixelsData.buffer
      @pixelsAreLittleEndian = u.isLittleEndian()

  # Draw patches.  Three cases:
  #
  # * Pixels: use pixel manipulation rather than canvas draws
  # * Monochrome: just fill canvas w/ patch default
  # * Otherwise: just draw each patch individually
  draw: (ctx) ->
    if @monochrome then u.fillCtx ctx, @agentClass::color
    else if @drawWithPixels then @drawScaledPixels ctx else super ctx

# #### Patch grid coord system utilities:

  # Return the patch id/index given integer x,y in patch coords
  patchIndex: (x,y) -> x-@minX + @numX*(@maxY-y)
  # Return the patch at matrix position x,y where
  # x & y are both valid integer patch coordinates.
  patchXY: (x,y) -> @[@patchIndex x,y]

  # Return x,y float values to be between min/max patch coord values
  clamp: (x,y) -> [u.clamp(x, @minXcor, @maxXcor), u.clamp(y, @minYcor, @maxYcor)]

  # Return x,y float values to be modulo min/max patch coord values.
  wrap: (x,y) -> [u.wrap(x, @minXcor, @maxXcor), u.wrap(y, @minYcor, @maxYcor)]

  # Return x,y float values to be between min/max patch values
  # using either clamp/wrap above according to isTorus topology.
  coord: (x,y) -> #returns a valid world coord (real, not int)
    if @isTorus then @wrap x,y else @clamp x,y
  # Return true if on world or torus, false if non-torus and off-world
  isOnWorld: (x,y) -> @isTorus or (@minXcor<=x<=@maxXcor and @minYcor<=y<=@maxYcor)

  # Return patch at x,y float values according to topology.
  patch: (x,y) ->
    [x,y]=@coord x,y
    x = u.clamp Math.round(x), @minX, @maxX
    y = u.clamp Math.round(y), @minY, @maxY
    @patchXY x, y

  # Return a random valid float x,y point in patch space
  randomPt: -> [u.randomFloat2(@minXcor,@maxXcor), u.randomFloat2(@minYcor,@maxYcor)]

# #### Patch metrics

  # Convert patch measure to pixels
  toBits: (p) -> p*@size
  # Convert bit measure to patches
  fromBits: (b) -> b/@size

# #### Patch utilities

  # Return an array of agentset items in a rectangle centered on the given
  # agent's patch - dx, dy units to the right/left and up/down, integers.
  # The agent will be in the results if in the agentSet and rectangle.
  agentRect: (agentSet, agent, dx, dy=dx) ->
    p =  agent.p ? agent
    rect = [];
    # Note: we do not "clip" the min/max/X/Y to be within the patches.
    # For non-torus, this is OK: the x,y test is still valid.
    # For torus, it allows us to adjust the x,y to be wrapped appropriately.
    minX = p.x-dx; maxX = p.x+dx
    minY = p.y-dy; maxY = p.y+dy
    # Is the p,dx,dy entirely inside the patches?
    inside = (minX >= @minX) and (maxX <= @maxX) and
             (minY >= @minY) and (maxY <= @maxY)
    checkTorus = @isTorus and not inside
    for a in agentSet
      # x,y values are patch integer x,y
      if a.p? then x = a.p.x; y = a.p.y else x = a.x; y = a.y
      # Adjust torus x,y if appropriate
      if checkTorus
        if x < minX then x += @numX else if x > maxX then x -= @numX
        if y < minY then y += @numY else if y > maxY then y -= @numY
      # Test x,y inside rect
      rect.push a if (minX <= x <= maxX and minY <= y <= maxY)
    @asSet rect
  # Return a rectangle of patches centered on p, with dx,dy to the right/left
  # of p, integers. Default to square.
  # Exclude p from results if meToo is false.
  # Performance: If the rect is in the pRect cache for this patch, return it.
  # See cacheRect()
  patchRect: (p, dx, dy=dx, meToo=true) ->
    return p.pRect if p.pRect? and (p.pRect.radius is dx) and (dx is dy)
    rect = []; # REMIND: optimize if no wrapping, rect inside patch boundaries
    for y in [p.y-dy..p.y+dy] by 1 # by 1: perf: avoid bidir JS for loop
      for x in [p.x-dx..p.x+dx] by 1
        if @isTorus or (@minX<=x<=@maxX and @minY<=y<=@maxY)
          if @isTorus
            if x < @minX then x += @numX else if x > @maxX then x -= @numX
            if y < @minY then y += @numY else if y > @maxY then y -= @numY
          pnext = @patchXY x, y # much faster than coord()
          rect.push pnext if (meToo or p isnt pnext)
    @asSet rect
  # Return all the agents contained in the patchRect.
  agentsOnRect: (p, dx, dy=dx) ->
    @agentsOnPatches @patchRect(p, dx, dy, true)
  agentsOnPatches: (patches) ->
    array = []
    if patches.length isnt 0
      u.error "agentsInPatches: no cached agents." if not patches[0].agents?
      # Use push.apply, not concat, see:
      # [jsPerf](http://jsperf.com/apply-push-vs-concat-array)
      Array.prototype.push.apply(array, p.agents) for p in patches
    @asSet array
  # Return all the unique patches the agentset or agent is on.
  patchesOf: (aset) ->
    return @asSet([aset.p ? aset]) unless aset.length?
    @asSet( ((a.p ? a) for a in aset) ).sortById().uniq()
  agentsOf: (aset) -> @agentsOnPatches(@patchesOf(aset))

  # Draws, or "imports" an image URL into the drawing layer.
  # The image is scaled to fit the drawing layer.
  #
  # This is an async load, see this
  # [new Image()]
  # (http://javascript.mfields.org/2011/creating-an-image-in-javascript/)
  # tutorial.  We draw the image into the drawing layer as
  # soon as the onload callback executes.
  importDrawing: (imageSrc, f) ->
    u.importImage imageSrc, (img) => # fat arrow, this context
      @installDrawing img
      f() if f?
  # Direct install image into the given context, not async.
  installDrawing: (img, ctx=@model.contexts.drawing) ->
    u.setIdentity ctx
    ctx.drawImage img, 0, 0, ctx.canvas.width, ctx.canvas.height
    ctx.restore() # restore patch transform

  # Utility function for pixel manipulation.  Given a patch, returns the
  # native canvas index i into the pixel data.
  # The top-left order simplifies finding pixels in data sets
  pixelByteIndex: (p) -> 4*p.id # Uint8
  pixelWordIndex: (p) -> p.id   # Uint32
  # Convert pixel location (top/left offset i.e. mouse) to patch coords (float)
  pixelXYtoPatchXY: (x,y) -> [@minXcor+(x / @size), @maxYcor-(y / @size)]
  # Convert patch coords (float) to pixel location (top/left offset i.e. mouse)
  patchXYtoPixelXY: (x,y) -> [(x-@minXcor)*@size, (@maxYcor-y)*@size]


  # Draws, or "imports" an image URL into the patches as their color property.
  # The drawing is scaled to the number of x,y patches, thus one pixel
  # per patch.  The colors are then transferred to the patches.
  # Map is a color map, only for gray for now
  importColors: (imageSrc, f, map) ->
    u.importImage imageSrc, (img) => # fat arrow, this context
      @installColors(img, map)
      f() if f?
  # Direct install image into the patch colors, not async.
  installColors: (img, map) ->
    u.setIdentity @pixelsCtx
    @pixelsCtx.drawImage img, 0, 0, @numX, @numY # scale if needed
    data = @pixelsCtx.getImageData(0, 0, @numX, @numY).data
    for p in @
      i = @pixelByteIndex p
      # promote initial default
      p.color = if map? then map[i] else [data[i++],data[i++],data[i]]
    @pixelsCtx.restore() # restore patch transform

  # Draw the patches via pixel manipulation rather than 2D drawRect.
  # See Mozilla pixel [manipulation article](http://goo.gl/Lxliq)
  drawScaledPixels: (ctx) ->
    # u.setIdentity ctx & ctx.restore() only needed if patch size
    # not 1, pixel ops don't use transform but @size>1 uses
    # a drawimage
    u.setIdentity ctx if @size isnt 1
    if @pixelsData32? then @drawScaledPixels32 ctx else @drawScaledPixels8 ctx
    ctx.restore() if @size isnt 1
  # The 8-bit version for drawScaledPixels.  Used for systems w/o typed arrays
  drawScaledPixels8: (ctx) ->
    data = @pixelsData
    for p in @
      i = @pixelByteIndex p; c = p.color
      a = if c.length is 4 then c[3] else 255
      data[i+j] = c[j] for j in [0..2]; data[i+3] = a
    @pixelsCtx.putImageData @pixelsImageData, 0, 0
    return if @size is 1
    ctx.drawImage @pixelsCtx.canvas, 0, 0, ctx.canvas.width, ctx.canvas.height
  # The 32-bit version of drawScaledPixels, with both little and big endian hardware.
  drawScaledPixels32: (ctx) ->
    data = @pixelsData32
    for p in @
      i = @pixelWordIndex p; c = p.color
      a = if c.length is 4 then c[3] else 255
      if @pixelsAreLittleEndian
      then data[i] = (a << 24) | (c[2] << 16) | (c[1] << 8) | c[0]
      else data[i] = (c[0] << 24) | (c[1] << 16) | (c[2] << 8) | a
    @pixelsCtx.putImageData @pixelsImageData, 0, 0
    return if @size is 1
    ctx.drawImage @pixelsCtx.canvas, 0, 0, ctx.canvas.width, ctx.canvas.height

  # Diffuse the value of patch variable `p.v` by distributing `rate` percent
  # of each patch's value of `v` to its neighbors.
  # If a color map `cMap` is given, scale the patch color via variable's value
  # If the patch has less than 8 neighbors, return the extra to the patch.
  diffuse: (v, rate, color) -> # variable name, diffusion rate, cMap (optional)
    # zero temp variable if not yet set
    unless @[0]._diffuseNext?
      p._diffuseNext = 0 for p in @
    # pass 1: calculate contribution of all patches to themselves and neighbors
    # if cMap
    #   minVal = Infinity; maxVal = -Infinity
    #   unless cMap.scaleColor?
    #     u.deprecated "Patch.diffuse: convert to ColorMap usage, using Jet"
    #     cMap = ColorMaps.Jet
    for p in @
      dv = p[v]*rate; dv8 = dv/8; nn = p.n.length
      p._diffuseNext += p[v] - dv + (8-nn)*dv8
      n._diffuseNext += dv8 for n in p.n
      # if cMap
      #   minVal = Math.min minVal, p[v]
      #   maxVal = Math.max maxVal, p[v]
    # pass 2: set new value for all patches, zero temp, modify color if c given
    for p in @
      p[v] = p._diffuseNext
      p._diffuseNext = 0
      p.color = ColorMaps.scaleColor color, p[v] if color?

    null # avoid returning copy of @
