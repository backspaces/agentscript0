# ### Patches
  
# Class Patches is a singleton 2D matrix of Patch instances, each patch 
# representing a 1x1 square in patch coordinates (via 2D coordinate transforms).
#
# From ABM.world, set in Model:
#
# * patchSize:     pixel h/w of each patch
# * min:           .x & .y, minimum patch coordinate, integer
# * max:           .x & .y, maximum patch coordinate, integer
# * width:         width of grid
# * height:        height of grid
# * isTorus:       true if coordinate system wraps around at edges
# * isHeadless:    true if not using canvas drawing
# * minCoordinate: .x & .y, maximum float coordinate (calculated)
# * maxCoordinate: .x & .y, maximum float coordinate (calculated)

# TODO
# minX
# maxX
# minY
# maxY
# numX, width
# numY, height
# minXcor, etc

class ABM.Patches extends ABM.BreedSet
  # Constructor: super creates the empty Set instance and installs
  # the agentClass (breed) variable shared by all the Patches in this set.
  # Patches are created from top-left to bottom-right to match data sets.
  constructor: -> # agentClass, name, mainSet
    super # call super with all the args I was called with
    @monochrome = false # set to true to optimize patches all default color
    # add world items to patches
    for own key, value of @model.world
      @[key] = value
  
  # Setup patch world from world parameters.
  # Note that this is done as separate method so like other agentsets,
  # patches are started up empty and filled by "create" calls.
  create: -> # TopLeft to BottomRight, exactly as canvas imagedata
    for y in [@max.y..@min.y] by -1
      for x in [@min.x..@max.x] by 1
        @add new @agentClass x: x, y: y
    @setPixels() unless @isHeadless # setup off-page canvas for pixel ops
    @
    
  # #### Patch grid coordinate system utilities:
  
  # Return patch at x, y float values according to topology.
  patch: (point) ->
    if @isCoordinate(point, @min, @max)
      coordinate = point
    else
      coordinate = @coordinate(point, @min, @max)

    rounded = x: Math.round(coordinate.x), y: Math.round(coordinate.y)

    @[@patchIndex rounded]

  # Return x, y float values to be between min/max patch values
  # using either clamp/wrap above according to isTorus topology.
  # returns a valid world coordinate (real, not int)
  coordinate: (point, minPoint = @minCoordinate, maxPoint = @maxCoordinate) ->
    if @isTorus
      @wrap point, minPoint, maxPoint
    else
      @clamp point, minPoint, maxPoint

  # Return x, y float values to be between min/max patch coordinate values
  clamp: (point, minPoint = @minCoordinate, maxPoint = @maxCoordinate) ->
    {
      x: u.clamp(point.x, minPoint.x, maxPoint.x),
      y: u.clamp(point.y, minPoint.y, maxPoint.y)
    }
  
  # Return x, y float values to be modulo min/max patch coordinate values.
  wrap: (point, minPoint = @minCoordinate, maxPoint = @maxCoordinate) ->
    {
      x: u.wrap(point.x, minPoint.x, maxPoint.x),
      y: u.wrap(point.y, minPoint.y, maxPoint.y)
    }
  
  # Returns true if the points x, y float values are between min/max
  # patch values
  isCoordinate: (point, minPoint = @minCoordinate, maxPoint = @maxCoordinate) ->
    minPoint.x <= point.x <= maxPoint.x and minPoint.y <= point.y <= maxPoint.y

  # Return true if on world or torus, false if non-torus and
  # off-world. Because toruses wrap.
  isOnWorld: (point) ->
    @isTorus or @isCoordinate(point)

  # Return the patch id/index given integer x, y in patch coordinates
  patchIndex: (point) ->
    point.x - @min.x + @width * (@max.y - point.y)

  # Return a random valid float {x, y} point in patch space
  randomPoint: ->
    {x: u.randomFloat(@minCoordinate.x, @maxCoordinate.x), y: u.randomFloat(@minCoordinate.y, @maxCoordinate.y)}

  # #### Patch metrics
  
  # Convert patch measure to pixels
  toBits: (patch) ->
    patch * @patchSize

  # Convert bit measure to patches
  fromBits: (bit) ->
    bit / @patchSize

  # #### Patch utilities
  
  # Return an array of patches in a rectangle centered on the given 
  # patch `patch`, dx, dy units to the right/left and up/down. 
  # Exclude `patch` unless meToo is true, default false.
  patchRectangle: (patch, dx, dy, meToo = false) ->
    rectangle = @patchRectangleNullPadded(patch, dx, dy, meToo)

    rectangle.remove(null)

  patchRectangleNullPadded: (patch, dx, dy, meToo = false) ->
    rectangle = new @model.Set
    # REMIND: optimize if no wrapping, rectangle inside patch boundaries
    for y in [(patch.position.y - dy)..(patch.position.y + dy)] by 1 # by 1: perf: avoid bidir JS for loop
      for x in [(patch.position.x - dx)..(patch.position.x + dx)] by 1
        nextPatch = null
        if @isTorus
          if x < @min.x
            x += @width
          if x > @max.x
            x -= @width
          if y < @min.y
            y += @height
          if y > @max.y
            y -= @height
          nextPatch = @patch x: x, y: y
        else if x >= @min.x and x <= @max.x and
            y >= @min.y and y <= @max.y
          nextPatch = @patch x: x, y: y

        if (meToo or patch isnt nextPatch)
          rectangle.push nextPatch

    return rectangle

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
  installDrawing: (img, context = @model.contexts.drawing) ->
    u.setIdentity context
    context.drawImage img, 0, 0, context.canvas.width, context.canvas.height
    context.restore() # restore patch transform
  
  # Utility function for pixel manipulation.  Given a patch, returns the 
  # native canvas index i into the pixel data.
  # The top-left order simplifies finding pixels in data sets
  pixelByteIndex: (patch) ->
    4 * patch.id # Uint8

  pixelWordIndex: (patch) ->
    patch.id   # Uint32

  # Convert pixel location (top/left offset i.e. mouse) to patch coordinates (float)
  pixelXYtoPatchXY: (x, y) ->
    [@minCoordinate.x + (x / @patchSize), @maxCoordinate.y - (y / @patchSize)]

  # TODO refactor
  # Convert patch coordinates (float) to pixel location (top/left offset i.e. mouse)
  patchXYtoPixelXY: (x, y) ->
    [(x - @minCoordinate.x) * @patchSize, (@maxCoordinate.y - y) * @patchSize]
    
  # Draws, or "imports" an image URL into the patches as their color property.
  # The drawing is scaled to the number of x, y patches, thus one pixel
  # per patch.  The colors are then transferred to the patches.
  # Map is a color map, only for gray for now
  importColors: (imageSrc, f, map) ->
    u.importImage imageSrc, (img) => # fat arrow, this context
      @installColors(img, map)
      f() if f?

  # Direct install image into the patch colors, not async.
  installColors: (img, map) ->
    u.setIdentity @pixelsContext
    @pixelsContext.drawImage img, 0, 0, @width, @height # scale if needed
    data = @pixelsContext.getImageData(0, 0, @width, @height).data
    for patch in @
      i = @pixelByteIndex patch
      # promote initial default
      patch.color = if map? then map[i] else [data[i++], data[i++], data[i]]
    @pixelsContext.restore() # restore patch transform

  # Draw the patches via pixel manipulation rather than 2D drawRect.
  # See Mozilla pixel [manipulation article](http://goo.gl/Lxliq)
  drawScaledPixels: (context) ->
    # u.setIdentity context & context.restore() only needed if patchSize 
    # not 1, pixel ops don't use transform but @patchSize > 1 uses
    # a drawimage
    u.setIdentity context if @patchSize isnt 1
    if @pixelsData32? then @drawScaledPixels32 context else @drawScaledPixels8 context
    context.restore() if @patchSize isnt 1

  # The 8-bit version for drawScaledPixels.  Used for systems w/o typed arrays
  drawScaledPixels8: (context) ->
    data = @pixelsData
    for patch in @
      i = @pixelByteIndex patch
      c = patch.color
      if c.length is 4
        a = c[3]
      else
        a = 255
      data[i + j] = c[j] for j in [0..2]
      data[i + 3] = a
    @pixelsContext.putImageData @pixelsImageData, 0, 0
    return if @patchSize is 1
    context.drawImage @pixelsContext.canvas, 0, 0, context.canvas.width, context.canvas.height

  # The 32-bit version of drawScaledPixels, with both little and big endian hardware.
  drawScaledPixels32: (context) ->
    data = @pixelsData32
    for p in @
      i = @pixelWordIndex p
      c = patch.color
      a = if c.length is 4 then c[3] else 255
      if @pixelsAreLittleEndian
      then data[i] = (a << 24) | (c[2] << 16) | (c[1] << 8) | c[0]
      else data[i] = (c[0] << 24) | (c[1] << 16) | (c[2] << 8) | a
    @pixelsContext.putImageData @pixelsImageData, 0, 0
    return if @patchSize is 1
    context.drawImage @pixelsContext.canvas, 0, 0, context.canvas.width, context.canvas.height

  floodFillOnce: (aset, fCandidate, fJoin, fCallback, fNeighbors = ((patch) -> patch.n),
      asetLast = []) ->
    super aset, fCandidate, fJoin, fCallback, fNeighbors, asetLast

  # Diffuse the value of patch variable `patch.v` by distributing `rate` percent
  # of each patch's value of `v` to its neighbors. If a color `c` is given,
  # scale the patch's color to be `patch.v` of `c`. If the patch has
  # less than 8 neighbors, return the extra to the patch.
  diffuse: (v, rate, c) -> # variable name, diffusion rate, max color (optional)
    # zero temp variable if not yet set
    unless @[0]._diffuseNext?
      patch._diffuseNext = 0 for patch in @
    # pass 1: calculate contribution of all patches to themselves and neighbors
    for patch in @
      dv = patch[v] * rate
      dv8 = dv / 8
      nn = patch.neighbors().length
      patch._diffuseNext += patch[v] - dv + (8 - nn) * dv8
      for neighbor in patch.neighbors()
        neighbor._diffuseNext += dv8
    # pass 2: set new value for all patches, zero temp, modify color if c given
    for patch in @
      patch[v] = patch._diffuseNext
      patch._diffuseNext = 0
      if c
        patch.color = u.fractionOfColor c, patch[v]
    null # avoid returning copy of @

  # ### Drawing

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support smoothing flags.
  usePixels: (@drawWithPixels = true) ->
    context = @model.contexts.patches
    u.setContextSmoothing context, not @drawWithPixels

  # Setup pixels used for `drawScaledPixels` and `importColors`
  # 
  setPixels: ->
    if @patchSize is 1
      @usePixels()
      @pixelsContext = @model.contexts.patches
    else
      @pixelsContext = u.createContext @width, @height

    @pixelsImageData = @pixelsContext.getImageData(0, 0, @width, @height)
    @pixelsData = @pixelsImageData.data

    if @pixelsData instanceof Uint8Array # Check for typed arrays
      @pixelsData32 = new Uint32Array @pixelsData.buffer
      @pixelsAreLittleEndian = u.isLittleEndian()
  
  # Draw patches.  Three cases:
  #
  # * Pixels: use pixel manipulation rather than canvas draws
  # * Monochrome: just fill canvas w/ patch default
  # * Otherwise: just draw each patch individually
  draw: (context) ->
    if @monochrome
      u.fillContext context, @agentClass::color
    else if @drawWithPixels
      @drawScaledPixels context
    else
      super context
