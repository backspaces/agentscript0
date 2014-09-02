# This documentation uses Jeremy Ashkenas's
# [docco](http://jashkenas.github.com/docco/) which allows
# [markdown](http://daringfireball.net/projects/markdown/syntax).

# Create the namespace **ABM** for our project.
# Note here `this` or `@` == window due to coffeescript wrapper call.
# Thus @ABM is placed in the global scope.
# Plain ABM is set for running tests on the command-line
@ABM = ABM = {}

root = @ # Keep a private copy of global object

# Global shim for not-yet-standard requestAnimationFrame.
# See: [Paul Irish Shim](https://gist.github.com/paulirish/1579671)
do ->
  @requestAnimFrame = @requestAnimationFrame or null
  @cancelAnimFrame = @cancelAnimationFrame or null
  for vendor in ['ms', 'moz', 'webkit', 'o'] when not @requestAnimFrame
    @requestAnimFrame or= @[vendor + 'RequestAnimationFrame']
    @cancelAnimFrame or= @[vendor + 'CancelAnimationFrame']
    @cancelAnimFrame or= @[vendor + 'CancelRequestAnimationFrame']
  @requestAnimFrame or= (callback) -> @setTimeout(callback, 1000 / 60)
  @cancelAnimFrame or= (id) -> @clearTimeout(id)

# **ABM.util** contains the general utilities for the project. Note that within
# **util** `@` referrs to ABM.util, *not* the global name space as above.
# Alias: u is an alias for ABM.util within the agentscript module (not outside)
#
#      u.clearContext(context) is equivalent to
#      ABM.util.clearContext(context)

# Extended with ABM.util.array

# TODO positions
ABM.util = u =
  # ### Language extensions
  
  # Shortcut for throwing an error.  Good for debugging:
  #
  #     error("wtf? foo=#{foo}") if fooProblem
  error: (string) ->
    throw new Error string
  
  # Two max/min int numbers. One for 2^53, largest int in float64, other for
  # bitwise ops which are 32 bit. See [discussion](http://goo.gl/WpAzT)
  MaxINT: Math.pow(2, 53)
  MinINT: -Math.pow(2, 53) # -@MaxINT fails, @ not defined yet
  MaxINT32: 0 | 0x7fffffff
  MinINT32: 0 | 0x80000000
  Colors: {
    black: [0, 0, 0], white: [255, 255, 255], gray: [128, 128, 128],
    red: [255, 0, 0], yellow: [255, 255, 0], green: [0, 128, 0],
    blue: [0, 0 ,255], purple: [128, 0, 128], brown: [165, 42, 42]
  }
  
  # Good replacements for Javascript's badly broken`typeof` and `instanceof`
  # See [underscore.coffee](http://goo.gl/L0umK)
  # TODO fix: Array.isArray or (object) ->
  isArray: (object) ->
    !!(object and object.concat and object.unshift and not object.callee)

  isFunction: (object) ->
    !!(object and object.constructor and object.call and object.apply)

  isString: (object) ->
    !!(object is '' or (object and object.charCodeAt and object.substr))

  isNumber: (object) ->
    !!(typeof object is "number")
  
  # ### Numeric operations

  # Replace Math.random with a simple seedable generator.
  # See [StackOverflow](http://goo.gl/FafN3z)
  randomSeed: (seed = 123456) ->
    Math.random = ->
      x = Math.sin(seed++) * 10000
      x - Math.floor(x)

  # Return random int in [0, max) or [min, max)
  randomInt: (minmax = 2, max = null) ->
    Math.floor(@randomFloat(minmax, max))

  # Return float in [0, max) or [min, max) or [-r / 2, r / 2)
  randomFloat: (minmax = 1, max = null) ->
    if max is null
      max = minmax
      min = 0
    else
      min = minmax

    min + Math.random() * (max - min)

  # Return float Gaussian normal with given mean, std deviation.
  randomNormal: (mean = 0.0, standardDeviation = 1.0) -> # Box-Muller
    u1 = 1.0 - Math.random()
    u2 = Math.random() # u1 in (0, 1]
    normal = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2)
    normal * standardDeviation + mean

  randomCentered: (r) ->
    @randomFloat -r / 2, r / 2

  onceEvery: (number = 100) ->
    @randomInt(number) is 1

  # Return log number where base is 10, base, e respectively.
  # Note ln: (n) -> Math.log number .. i.e. JS's log is log base e
  log10: (number) ->
    Math.log(number) / Math.LN10

  log2: (number) ->
    @logN number, 2

  logN: (number, base) ->
    Math.log(number) / Math.log(base)

  # Return true [modulo](http://goo.gl/spr24), % is remainder, not mod.
  mod: (number, moduloOf) ->
    ((number % moduloOf) + moduloOf) % moduloOf

  # Return number to be between min, max via modulo
  wrap: (number, min, max) ->
    min + @mod(number - min, max - min)

  # Return number to be between min, max via clamping with min/max
  clamp: (number, min, max) ->
    Math.max(Math.min(number, max), min)

  # Return sign of a number as +/- 1
  sign: (number) ->
    if number < 0
      -1
    else
      1

  # ### Color and angle operations

  # Basic colors from string # TODO make better, so accepts arrays
  colorFromString: (colorName) ->
    color = @Colors[colorName]
    if !@isArray color
      @error "unless you're using basic colors, specify an rgb array [nr, nr, nr]"
    color

  # Return a random RGB or gray color. Array passed to minimize garbage collection
  randomColor: () ->
    color = []
    for i in [0..2]
      color[i] = @randomInt(256)
    color

  # Note: if 2 args passed, assume they're min, max w/ default c
  randomGray: (min = 64, max = 192) ->
    color = []
    random = @randomInt min, max
    for i in [0..2]
      color[i] = random
    color

  # Random color from a colormap set of r, g, b values.
  # Default is one of 125 (5^3) colors
  randomMapColor: (set = [0, 63, 127, 191, 255]) ->
    [@array.sample(set), @array.sample(set), @array.sample(set)]

  randomBrightColor: () ->
    @randomMapColor [0, 127, 255]

  # Return new color, c, by scaling each value of the rgb color max.
  fractionOfColor: (maxColor, fraction) ->
    color = []
    for value, i in maxColor
      color[i] = @clamp(Math.round(value * fraction), 0, 255)
    color

  # lightens color with fraction of 0..255
  brightenColor: (color, fraction) ->
    newColor = []
    for value in color
      newColor.push @clamp(Math.round(value + fraction * 255), 0, 255)
    newColor

  # Return HTML color as used by canvas element. Can include Alpha
  colorString: (color) ->
    if not color.string?
      if color.length is 4 and color[3] > 1
        @error "alpha > 1"
      if color.length is 3
        color.string = "rgb(#{color})"
      else
        color.string = "rgba(#{color})"
    color.string

  # Compare two colors.  Alas, there is no array.Equal operator.
  colorsEqual: (color1, color2) ->
    color1.toString() is color2.toString()

  # Return little/big endian-ness of hardware. 
  # See Mozilla pixel [manipulation article](http://goo.gl/Lxliq)
  isLittleEndian: ->
    # convert 1-int array to typed array
    d32 = new Uint32Array [0x01020304]
    # return true if byte order reversed
    (new Uint8ClampedArray d32.buffer)[0] is 4

  # Convert between degrees and radians.  We/Math package use radians.
  degreesToRadians: (degrees) ->
    degrees * Math.PI / 180

  radiansToDegrees: (radians) ->
    radians * 180 / Math.PI

  # Return angle in (-pi, pi] that added to rad2 = rad1
  # See NetLogo's [subtract-headings](http://goo.gl/CjoHuV) for explanation
  substractRadians: (radians1, radians2) ->
    angle = radians1 - radians2
    PI = Math.PI
    if angle <= -PI
      angle += 2 * PI
    if angle > PI
      angle -= 2 * PI
    angle
  
  # ### Object operations
  
  # Return object's own key or variable values
  #
  ownKeys: (object) ->
    ABM.Array.from(key for own key, value of object)

  ownVariableKeys: (object) ->
    ABM.Array.from(key for own key, value of object when not @isFunction value)

  ownValues: (object) ->
    ABM.Array.from(value for own key, value of object)

  # ### Topology operations
  
  # Return angle in [-pi, pi] radians from point1 to point2
  # [See: Math.atan2](http://goo.gl/JS8DF)
  angle: (point1, point2, patches) ->
    if patches.isTorus
      @angleTorus point1, point2, patches
    else
      @angleEuclidian point1, point2

  # Euclidian radians toward
  angleEuclidian: (point1, point2) ->
    Math.atan2 point2.y - point1.y, point2.x - point1.x

  # Return the angle from x1, y1 to x2, y2 on torus using shortest reflection.
  angleTorus: (point1, point2, patches) ->
    closest = @closestTorusPoint point1, point2, patches.width, patches.height
    @angleEuclidian point1, closest

  # Return true if point2 is in cone radians around heading radians from 
  # point1.x, point2.x and within distance radius from point1.x,
  # point2.x. I.e. is point2 in cone/heading/radius from point1?
  inCone: (heading, cone, radius, point1, point2, patches) ->
    if patches.isTorus
      u.inConeTorus(heading, cone, radius, point1, point2, patches)
    else
      u.inConeEuclidian(heading, cone, radius, point1, point2)

  # inCone for euclidian distance
  inConeEuclidian: (heading, cone, radius, point1, point2) ->
    if radius < @distanceEuclidian point1, point2
      return false

    angle = @angleEuclidian point1, point2 # angle from 1 to 2
    cone / 2 >= Math.abs @substractRadians(heading, angle)

  # Return true if point2 is in cone radians around heading radians from 
  # point1.x, point2.x and within distance radius from point1.x, point2.x
  # considering all torus reflections.
  inConeTorus: (heading, cone, radius, point1, point2, patches) ->
    for point in @torus4Points point1, point2, patches.width, patches.height
      return true if @inConeEuclidian heading, cone, radius, point1, point
    false

  # Return the distance between point1 and 2
  distance: (point1, point2, patches) ->
    if patches.isTorus
      @distanceTorus(point1, point2, patches)
    else
      @distanceEuclidian(point1, point2)

  # Return the Euclidean distance between point1 and 2
  distanceEuclidian: (point1, point2) ->
    distanceX = point1.x - point2.x
    distanceY = point1.y - point2.y
    Math.sqrt distanceX * distanceX + distanceY * distanceY
  
  # Return the [torus distance](http://goo.gl/PgJ5N) between two points 
  # point1 (A) and point2 (B):
  #
  #     dx = |point2.x - point1.x|
  #     dy = |point2.y - point1.y|
  #     d = sqrt(min(dx, W - dx)^2 + min(dy, H - dy)^2)
  #
  # Torus note: ABMs often use a Torus topology where the right and left edges
  # fold to meet, and similarly for the top/bottom.
  # For points, this is easily handled with the mod function .. insuring the
  # point is within the rectangle modulo W & H.
  #
  # The relationship *between* points is more difficult.  The relationship between
  # A and B must also include the towards-reflections around A, thus 4 points.
  #
  #          |               |
  #          |      W        |
  #     -----+---------------+-----
  #      B1  |           B   |
  #          |               |  H
  #          |               |
  #          |  A            |
  #     -----+---------------+-----
  #      B3  |           B2  |
  #          |               |
  distanceTorus: (point1, point2, patches) ->
    xDistance = Math.abs point2.x - point1.x
    yDistance = Math.abs point2.y - point1.y
    minX = Math.min xDistance, patches.width - xDistance
    minY = Math.min yDistance, patches.height - yDistance
    Math.sqrt minX * minX + minY * minY

  # Return 4 torus point reflections of point2 around point1
  torus4Points: (point1, point2, width, height) ->
    [xReflected, yReflected] = @torusReflect(point1, point2, width, height)

    [point2, {x: xReflected, y: point2.y},
      {x: point2.x, y: yReflected}, {x: xReflected, y: yReflected}]

  # Return closest of 4 torus points from point1 to 2
  closestTorusPoint: (point1, point2, width, height) ->
    [xReflected, yReflected] = @torusReflect(point1, point2, width, height)

    if Math.abs(xReflected - point1.x) < Math.abs(point2.x - point1.x)
      x = xReflected
    else
      x = point2.x

    if Math.abs(yReflected - point1.y) < Math.abs(point2.y - point1.y)
      y = yReflected
    else
      y = point2.y

    {x: x, y: y}

  # Used in torus4Points
  torusReflect: (point1, point2, width, height) ->
    if point2.x < point1.x
      xReflected = point2.x + width
    else
      xReflected = point2.x - width

    if point2.y < point1.y
      yReflected = point2.y + height
    else
      yReflected = point2.y - height

    [xReflected, yReflected]

  # ### File I/O

  # Cache of file names used by file imports below
  fileIndex: {}

  # Import an image, executing (async) optional function call(image) on completion
  importImage: (name, call = ->) ->
    image = @fileIndex[name]
    if image?
      if image.isDone
        call(image)
    else
      image = new Image()
      image.isDone = false
      image.crossOrigin = "Anonymous"
      image.onload = ->
        call(image)
        image.isDone = true
      image.src = name
      @fileIndex[name] = image
    image
    
  # Use XMLHttpRequest to fetch data of several types. Data Types: text,
  # arraybuffer, blob, json, document, [See specification](http://goo.gl/y3r3h).
  # method is "GET" or "POST". f is function to call onload, default to no-op.
  xhrLoadFile: (name, method = "GET", type = "text", call = ->) -> # AJAX async request
    xhr = @fileIndex[name]
    if xhr?
      if xhr.isDone
        call(xhr.response)
    else
      xhr = new XMLHttpRequest()
      xhr.isDone = false
      xhr.open method, name # POST mainly for security and large files
      xhr.responseType = type
      xhr.onload = ->
        call(xhr.response)
        xhr.isDone = true
      @fileIndex[name] = xhr
      xhr.send()
    xhr
  
  # Return true if all files are loaded.
  filesLoaded: (files = @fileIndex) ->
    array = (object.isDone for object in (@ownValues files))
    array.reduce ((valueA, valueB) -> valueA and valueB), true

  # Wait for files to be loaded before executing callback call
  waitOnFiles: (call, files = @fileIndex) ->
    @waitOn (=> @filesLoaded files), call

  # Wait for function done() to return true before calling callback f
  waitOn: (done, call) ->
    if done()
      call()
    else
      setTimeout((=> @waitOn(done, call)), 1000)

  # ### Image data operations

  # Make a copy of an image.
  # Note: new image will have the naturalWidth/Height of input image.
  # Should be sync
  cloneImage: (image) ->
    newImage = new Image()
    newImage.src = image.src
    newImage

  # Create a data array from an image's imageData
  # image may be a canvas.
  # The function call = call(imageData, rgbIndex) -> number
  imageToData: (image, call = @pixelByte(0), arrayType = Uint8ClampedArray) ->
    @imageRowsToData image, image.height, call, arrayType

  imageRowsToData: (image, rowsPerSlice, call = @pixelByte(0),
      arrayType = Uint8ClampedArray) ->
    rowsDone = 0
    data = new arrayType image.width * image.height

    while rowsDone < image.height
      rows = Math.min image.height - rowsDone, rowsPerSlice
      context = @imageSliceToContext image, 0, rowsDone, image.width, rows # REMIND: pass context
      idata = @contextToImageData(context).data
      dataStart = rowsDone * image.width
      data[dataStart + i] = call(idata, 4 * i) for i in [0...idata.length / 4] by 1
      rowsDone += rows

    data

  imageSliceToContext: (image, sx, sy, sw, sh, context) ->
    if context?
      context.canvas.width = sw
      context.canvas.height = sh
    else
      context = @createContext sw, sh
    context.drawImage image, sx, sy, sw, sh, 0, 0, sw, sh
    context

  pixelByte: (n) ->
    (byte, i) -> byte[i + n]

  # ### Canvas/Context operations

  # Create a new canvas of given width/height
  createCanvas: (width, height) ->
    canvas = document.createElement 'canvas'
    canvas.width = width
    canvas.height = height
    canvas

  # As above, but returing the context object.
  # Note context.canvas is the canvas for the context, and can be use as an image.
  createContext: (width, height, contextType = "2d") ->
    canvas = @createCanvas width, height
    if contextType is "2d"
      canvas.getContext "2d"
    else
      canvas.getContext("webgl") ? canvas.getContext("experimental-webgl")

  # Return a "layer" 2D/3D rendering context within the specified HTML `<div>`,
  # with the given width/height positioned absolutely at top/left within the div,
  # and with the z-index of z.
  #
  # The z level gives us the capability of buildng a "stack" of coordinated canvases.
  createLayer: (div, width, height, z, context = "2d") -> # a canvas context object
    if context is "img"
      element = context = new Image()
      context.width = width
      context.height = height
    else
      element = (context = @createContext(width, height, context)).canvas
    @insertLayer div, element, width, height, z
    context
  insertLayer: (div, element, w, h, z) ->
    element.setAttribute 'style', # Note: this erases existing style, el.style.position doesnt
    "position:absolute;top:0;left:0;width:#{w};height:#{h};z-index:#{z}"
    div.appendChild(element)

  setContextSmoothing: (context, smoothing) ->
    context.imageSmoothingEnabled = smoothing
    context.mozImageSmoothingEnabled = smoothing
    context.oImageSmoothingEnabled = smoothing
    context.webkitImageSmoothingEnabled = smoothing

  # Install identity transform.  Call context.restore() to revert to previous transform
  setIdentity: (context) ->
    context.save() # revert to native 2D transform
    context.setTransform 1, 0, 0, 1, 0, 0
  
  # Clear the 2D/3D layer to be transparent. Note this [discussion](http://goo.gl/qekXS).
  clearContext: (context) ->
    if context.save? # test for 2D context
      @setIdentity context
      # context.canvas.width = context.canvas.width not used so as to preserve
      # patch coordinates
      context.clearRect 0, 0, context.canvas.width, context.canvas.height
      context.restore()
    else # 3D
      context.clearColor 0, 0, 0, 0 # transparent!
      context.clear context.COLOR_BUFFER_BIT | context.DEPTH_BUFFER_BIT

  # Fill the 2D/3D layer with the given color
  fillContext: (context, color) ->
    if context.fillStyle? # test for 2D context
      @setIdentity context
      context.fillStyle = @colorString color
      context.fillRect 0, 0, context.canvas.width, context.canvas.height
      context.restore()
    else # 3D
      context.clearColor color..., 1 # alpha = 1 unless color is rgba
      context.clear context.COLOR_BUFFER_BIT | context.DEPTH_BUFFER_BIT

  # Draw string of the given color at the xy location, in context pixel coordinates.
  # Use setIdentity .. reset if a transform is being used by caller.
  contextDrawText: (context, string, x, y, color = [0, 0, 0], setIdentity = true) ->
    @setIdentity(context) if setIdentity
    context.fillStyle = @colorString color
    context.fillText(string, x, y)
    if setIdentity
      context.restore()
  # Set the element text align and baseline drawing parameters
  #
  # * font is a HTML/CSS string like: "9px sans-serif"
  # * align is left right center start end
  # * baseline is top hanging middle alphabetic ideographic bottom
  #
  # See [reference](http://goo.gl/AvEAq) for details.
  contextTextParams: (context, font, align = "center", baseline = "middle") ->
    context.font = font
    context.textAlign = align
    context.textBaseline = baseline

  elementTextParams: (element, font, align = "center", baseline = "middle") ->
    element = element.canvas if element.canvas?
    element.style.font = font
    element.style.textAlign = align
    element.style.textBaseline = baseline

  # Convert a canvas to an image, executing fcn f on completion.
  # Generally can skip callback but see [stackoverflow](http://goo.gl/kIk2U)
  # Note: uses toDataURL thus possible cross origin problems.
  # Fix: use context.canvas for programatic imaging.
  contextToDataUrl: (context) -> context.canvas.toDataURL "image/png"

  contextToDataUrlImage: (context, call) ->
    image = new Image()
    if call?
      image.onload = -> call(image)
    image.src = context.canvas.toDataURL "image/png"
    image

  # Convert a context to an imageData object
  contextToImageData: (context) ->
    context.getImageData 0, 0, context.canvas.width, context.canvas.height

  # Draw an image centered at x, y w/ image size dx, dy.
  # See [this tutorial](http://goo.gl/VUlhY).
  drawCenteredImage: (context, image, radians, x, y, dx, dy) ->
    # presume save/restore surrounds this
    context.translate x, y # translate to center
    context.rotate radians
    context.drawImage image, -dx / 2, -dy / 2
  
  # Duplicate a context's image.  Returns the new context, use context.canvas for canvas.
  copyContext: (context) ->
    newContext = @createContext context.canvas.width, context.canvas.height
    newContext.drawImage context.canvas, 0, 0
    newContext

  # Resize a context/canvas and preserve data.
  resizeContext: (context, width, height, scale = false) -> # http://goo.gl/Tp90B
    newContext = @copyContext context
    context.canvas.width = width
    context.canvas.height = height
    context.drawImage newContext.canvas, 0, 0

  # ### Misc / helpers
  
  # Return a linear interpolation between low and high.
  # Scale is in [0 - 1], and the result is in [low, high]
  linearInterpolate: (low, high, scale) ->
    low + (high - low) * scale

  # Return argument unchanged; for primitive arrays or objs sorted by reference
  identityFunction: (object) ->
    object

  # Return a function that returns an object's property.  Property in fcn closure.
  propertyFunction: (property) ->
    (object) -> object[property]

  # Return a function that returns an object's property.  Property in fcn closure.
  propertySortFunction: (property) ->
    (objectA, objectB) ->
      if objectA[property] < objectB[property]
        -1
      else if objectA[property] > objectB[property]
        1
      else
        0

  # Return a JS array given a TypedArray.
  # To create TypedArray from JS array: new Uint8Array(jsa) etc
  typedToJS: (typedArray) ->
    (i for i in typedArray)
