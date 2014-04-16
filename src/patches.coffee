# ### Patch and Patches
  
# Class Patch instances represent a rectangle on a grid.  It holds variables\
# that are in the patches the agents live on.  The set of all patches (ABM.patches)
# is the world on which the agents live and the model runs.
class ABM.Patch
  # Constructor & Class Variables:
  #
  # Constructor & Class Variables:
  # * id:         unique identifier, promoted by agentset create() factory method
  # * breed:      the agentset this agent belongs to
  # * x,y:        position on the patch grid, in patch coordinates
  # * color:      the color of the patch as an RGBA array, A optional.
  # * hidden:     whether or not to draw this patch
  # * label:      text for the patch
  # * labelColor: the color of my label text
  # * labelOffset:the x,y offset of my label from my x,y location
  # * n,n4:       adjacent neighbors: n: 8 patches, n4: N,E,S,W patches.
  # * pRect:      cached rect for performance
  #
  # Patches may not need their neighbors, thus we use a default
  # of none.  n and n4 are promoted by the Patches agent set 
  # if world.neighbors is true, the default.

  id: null            # unique id, promoted by agentset create factory method
  breed: null         # set by the agentSet owning this patch
  x:null; y:null      # The patch position in the patch grid
  n:null; n4:null     # The neighbors, n: 8, n4: 4. null OK if model doesn't need them.
  color: [0,0,0]      # The patch color
  hidden: false       # draw me?
  label: null         # text for the patch
  labelColor: [0,0,0] # text color
  labelOffset: [0,0]  # text offset from the patch center
  pRect: null         # Performance: cached rect of neighborhood larger than n.
  
  # New Patch: Just set x,y. Neighbors set by Patches constructor if needed.
  constructor: (@x, @y) ->

  # Return a string representation of the patch.
  toString: -> "{id:#{@id} xy:#{[@x,@y]} c:#{@color}}"

  # Set patch color to `c` scaled by `s`. Usage:
  #
  #     p.scaleColor p.color, .8 # reduce patch color by .8
  #     p.scaleColor @foodColor, p.foodPheromone # ants model
  #
  # Promotes color if currently using the default.
  scaleColor: (c, s) -> 
    @color = u.clone @color unless @.hasOwnProperty("color")
    u.scaleColor c, s, @color
  
  # Draw the patch and its text label if there is one.
  draw: (ctx) ->
    ctx.fillStyle = u.colorStr @color
    ctx.fillRect @x-.5, @y-.5, 1, 1
    if @label? # REMIND: should be 2nd pass.
      [x,y] = @breed.patchXYtoPixelXY @x, @y
      u.ctxDrawText ctx, @label, x+@labelOffset[0], y+@labelOffset[1], @labelColor
  
  # Return an array of the agents on this patch.
  # If patches.cacheAgentsHere has created an @agents instance
  # variable for the patches, agents will add/remove themselves
  # as they move from patch to patch.
  agentsHere: ->
    @agents ? (a for a in ABM.agents when a.p is @)
  
  # Returns true if this patch is on the edge of the grid.
  isOnEdge: ->
    @x is @breed.minX or @x is @breed.maxX or \
    @y is @breed.minY or @y is @breed.maxY
  
  # Factory: Create num new agents on this patch. The optional init
  # proc is called on the new agent after inserting in its agentSet.
  sprout: (num = 1, breed = ABM.agents, init = ->) ->
    breed.create num, (a) => # fat arrow so that @ = this patch
      a.setXY @x, @y; init(a); a

# Class Patches is a singleton 2D matrix of Patch instances, each patch 
# representing a 1x1 square in patch coordinates (via 2D coord transforms).
#
# From ABM.world, set in Model:
#
# * size:         pixel h/w of each patch.
# * minX/maxX:    min/max x coord in patch coords
# * minY/maxY:    min/max y coord in patch coords
# * numX/numY:    width/height of grid.
# * isTorus:      true if coord system wraps around at edges
# * hasNeighbors: true if each patch caches its neighbors
# * isHeadless:   true if not using canvas drawing


class ABM.Patches extends ABM.AgentSet
  # Constructor: super creates the empty AgentSet instance and installs
  # the agentClass (breed) variable shared by all the Patches in this set.
  # Patches are created from top-left to bottom-right to match data sets.
  constructor: -> # agentClass, name, mainSet
    super # call super with all the args I was called with
    @monochrome = false # set to true to optimize patches all default color
    @[k] = v for own k,v of ABM.world # add world items to patches
    @populate() unless @mainSet?
  
  # Setup patch world from world parameters.
  # Note that this is done as separate method so like other agentsets,
  # patches are started up empty and filled by "create" calls.
  populate: -> # TopLeft to BottomRight, exactly as canvas imagedata
    for y in [@maxY..@minY] by -1
      for x in [@minX..@maxX] by 1
        @add new @agentClass x, y
    @setNeighbors() if @hasNeighbors
    @setPixels() unless @isHeadless # setup off-page canvas for pixel ops
    
  # Have patches cache the agents currently on them.
  # Optimizes p.agentsHere method.
  # Call before first agent is created.
  cacheAgentsHere: -> p.agents = [] for p in @; null

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support smoothing flags.
  usePixels: (@drawWithPixels=true) ->
    ctx = ABM.contexts.patches
    u.setCtxSmoothing ctx, not @drawWithPixels

  # Optimization: Cache a single set by modeler for use by patchRect,
  # inCone, inRect, inRadius.  Ex: flock demo model's vision rect.
  cacheRect: (radius, meToo=false) ->
    for p in @
      p.pRect = @patchRect p, radius, radius, meToo
      p.pRect.radius = radius#; p.pRect.meToo = meToo
    radius

  # Install neighborhoods in patches
  setNeighbors: -> 
    for p in @
      p.n =  @patchRect p, 1, 1
      p.n4 = @asSet (n for n in p.n when n.x is p.x or n.y is p.y)

  # Setup pixels used for `drawScaledPixels` and `importColors`
  # 
  setPixels: ->
    if @size is 1
    then @usePixels(); @pixelsCtx = ABM.contexts.patches
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
  wrap: (x,y)  -> [u.wrap(x, @minXcor, @maxXcor),  u.wrap(y, @minYcor, @maxYcor)]
  
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
  
  # Return an array of patches in a rectangle centered on the given 
  # patch `p`, dx, dy units to the right/left and up/down. 
  # Exclude `p` unless meToo is true, default false.
  patchRect: (p, dx, dy, meToo=false) ->
    return p.pRect if p.pRect? and p.pRect.radius is dx # and p.pRect.radius is dy
    rect = []; # REMIND: optimize if no wrapping, rect inside patch boundaries
    for y in [p.y-dy..p.y+dy] by 1 # by 1: perf: avoid bidir JS for loop
      for x in [p.x-dx..p.x+dx] by 1
        if @isTorus or (@minX<=x<=@maxX and @minY<=y<=@maxY)
          if @isTorus
            x+=@numX if x<@minX; x-=@numX if x>@maxX
            y+=@numY if y<@minY; y-=@numY if y>@maxY
          pnext = @patchXY x, y # much faster than coord()
          unless pnext?
            u.error "patchRect: x,y out of bounds, see console.log"
            console.log "x #{x} y #{y} p.x #{p.x} p.y #{p.y} dx #{dx} dy #{dy}"
          rect.push pnext if (meToo or p isnt pnext)
    @asSet rect

  # Draws, or "imports" an image URL into the drawing layer.
  # The image is scaled to fit the drawing layer.
  #
  # This is an async load, see this
  # [new Image()](http://javascript.mfields.org/2011/creating-an-image-in-javascript/)
  # tutorial.  We draw the image into the drawing layer as
  # soon as the onload callback executes.
  importDrawing: (imageSrc, f) ->
    u.importImage imageSrc, (img) => # fat arrow, this context
      @installDrawing img
      f() if f?
  # Direct install image into the given context, not async.
  installDrawing: (img, ctx=ABM.contexts.drawing) ->
    u.setIdentity ctx
    ctx.drawImage img, 0, 0, ctx.canvas.width, ctx.canvas.height
    ctx.restore() # restore patch transform
  
  # Utility function for pixel manipulation.  Given a patch, returns the 
  # native canvas index i into the pixel data.
  # The top-left order simplifies finding pixels in data sets
  pixelByteIndex: (p) -> 4*p.id # Uint8
  pixelWordIndex: (p) -> p.id   # Uint32
  # Convert pixel location (top/left offset i.e. mouse) to patch coords (float)
  pixelXYtoPatchXY: (x,y) -> [@minXcor+(x/@size), @maxYcor-(y/@size)]
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

  floodFill: (aset, fCandidate, fJoin, fCallback, fNeighbors=((p)->p.n), asetLast=[]) ->
    super aset, fCandidate, fJoin, fCallback, fNeighbors, asetLast

  # Diffuse the value of patch variable `p.v` by distributing `rate` percent
  # of each patch's value of `v` to its neighbors. If a color `c` is given,
  # scale the patch's color to be `p.v` of `c`. If the patch has
  # less than 8 neighbors, return the extra to the patch.
  diffuse: (v, rate, c) -> # variable name, diffusion rate, max color (optional)
    # zero temp variable if not yet set
    unless @[0]._diffuseNext?
      p._diffuseNext = 0 for p in @
    # pass 1: calculate contribution of all patches to themselves and neighbors
    for p in @
      dv = p[v]*rate; dv8 = dv/8; nn = p.n.length
      p._diffuseNext += p[v] - dv + (8-nn)*dv8
      n._diffuseNext += dv8 for n in p.n
    # pass 2: set new value for all patches, zero temp, modify color if c given
    for p in @
      p[v] = p._diffuseNext
      p._diffuseNext = 0
      p.scaleColor c, p[v] if c
    null # avoid returning copy of @
