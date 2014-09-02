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

# Array utility functions. Are added to ABM.Array and to util for
# legacy reasons.

ABM.util.array =
  # The static `ABM.Array.from` as a method.
  # Used by methods creating new arrays.
  from: (array, arrayType) ->
    ABM.Array.from array, arrayType
  # TODO replace in code

  # Return string representative of agentset.
  toString: (array) ->
    "[" + (object.toString() for object in array).join(", ") + "]"

  # Return an array of floating pt numbers as strings at given precision;
  # useful for printing
  toFixed: (array, precision = 2) ->
    newArray = []
    for number in array
      newArray.push number.toFixed precision
    newArray

  # Does the array have any elements? Is the array empty?
  any: (array) ->
    not @empty(array)

  empty: (array) ->
    array.length is 0

  # Make a copy of the array. Needed when you don't want to modify the given
  # array with mutator methods like sort, splice or your own functions.
  # By giving begin/arguments, retrieve a subset of the array.
  # Works with TypedArrays too.
  clone: (array, begin = null, end = null) ->
    if array.slice?
      method = "slice"
    else
      method = "subarray"

    if begin?
      array[method] begin, end
    else
      array[method] 0

  # Return first element of array.
  first: (array) ->
    array[0]

  # Return last element of array.
  last: (array) ->
    if @empty array
      undefined
    else
      array[array.length - 1]

  # Return random element of array or number random elements of array.
  # Note: array elements presumed unique, i.e. objects or distinct primitives
  # Note: clone, shuffle then first number has poor performance
  sample: (array, numberOrCondition = null, condition = null) ->
    if u.isFunction numberOrCondition
      condition = numberOrCondition
    else if numberOrCondition?
      number = Math.floor(numberOrCondition)

    if number?
      newArray = new ABM.Array
      object = true
      while newArray.length < number and object?
        object = @sample(array, condition)
        if object and object not in newArray
          newArray.push object
      return newArray
    else if condition?
      checked = new ABM.Array
      while checked.length < array.length
        object = @sample(array)
        if object and object not in checked
          checked.push object
          if condition(object)
            return object
    else
      if @empty array
        return null
      return array[u.randomInt array.length]

  # True if object is in array.
  contains: (array, object) ->
    array.indexOf(object) >= 0

  # Remove an object from an array.
  # Error if object not in array.
  remove: (array, object) ->
    while true
      index = array.indexOf object
      break if index is -1
      array.splice index, 1
    array

  # Remove elements in objects from an array. Binary search if f isnt null.
  # Error if an object not in array.
  removeItems: (array, objects) ->
    for object in objects
      @remove array, object
    array

  # Randomize the elements of this array.
  shuffle: (array) ->
    array.sort -> 0.5 - Math.random()

  # TODO add array functions to Array extension, then allow it to be
  # added to array in user models through an ABM.setup() function
  #
  # Return object when lambda(object) min/max in array. Error if array empty.
  # If f is a string, return element with max value of that property.
  # If "valueToo" then return a 2-array of the element and the value;
  # used for cases where f is costly function.
  # 
  #     array = [{x: 1, y: 2}, {x: 3, y: 4}]
  #     array.min()
  #     # returns {x: 1, y: 2} 5
  #     [min, dist2] = array.min(((o) -> o.x * o.x + o.y * o.y), true)
  #     # returns {x: 3, y: 4}
  min: (array, lambda = u.identityFunction, valueToo = false) ->
    u.error "min: empty array" if @empty array
    if u.isString lambda
      lambda = u.propertyFunction lambda
    minValue = Infinity
    minObject = null

    for object in array
      value = lambda(object)
      if value < minValue
        minValue = value
        minObject = object

    if valueToo
      [minObject, minValue]
    else
      minObject

  max: (array, lambda = u.identityFunction, valueToo = false) ->
    u.error "max: empty array" if @empty array
    if u.isString lambda
      lambda = u.propertyFunction lambda
    maxValue = -Infinity
    maxObject = null

    for object in array
      value = lambda(object)
      if value > maxValue
        maxValue = value
        maxObject = object

    if valueToo
      [maxObject, maxValue]
    else
      maxObject

  sum: (array, lambda = u.identityFunction) ->
    if u.isString lambda
      lambda = u.propertyFunction lambda

    value = 0
    for object in array
      value += lambda(object)

    value

  average: (array, lambda = u.identityFunction) ->
    @sum(array, lambda) / array.length

  median: (array) ->
    if array.sort?
      array = @clone array
    else
      array = u.typedToJS array

    middle = (array.length - 1) / 2

    @sort array

    (array[Math.floor(middle)] + array[Math.ceil(middle)]) / 2

  # Return histogram of o when f(o) is a numeric value in array.
  # Histogram interval is bin. Error if array empty.
  # If f is a string, return histogram of that property.
  #
  # In examples below, histogram returns [3, 1, 1, 0, 0, 1]
  #
  #     a = [1, 3, 4, 1, 1, 10]
  #     h = histogram a, 2, (i) -> i
  #     
  #     b = ({id:i} for i in a)
  #     h = histogram b, 2, (o) -> o.id
  #     h = histogram b, 2, "id"
  histogram: (array, binSize = 1, lambda = u.identityFunction) ->
    if u.isString lambda
      lambda = u.propertyFunction lambda
    histogram = []

    for object in array
      integer = Math.floor lambda(object) / binSize
      histogram[integer] or= 0
      histogram[integer] += 1

    for value, integer in histogram when not value?
      histogram[integer] = 0

    histogram

  # Mutator. Sort array of objects in place by the function f.
  # If f is string, f returns property of object.
  # Returns array.
  # Clone first if you want to preserve the original array.
  #
  #     array = [{i: 1}, {i: 5}, {i: -1}, {i: 2}, {i: 2}]
  #     sortBy array, "i"
  #     # array now is [{i: -1}, {i: 1}, {i: 2}, {i: 2}, {i:5}]
  sort: (array, lambda = null) ->
    if u.isString lambda # use item[f] if f is string
      lambda = u.propertySortFunction lambda

    array._sort lambda

  # Mutator. Removes dups, by reference, in place from array.
  # Note "by reference" means litteraly same object, not copy. Returns array.
  # Clone first if you want to preserve the original array.
  #
  #     ids = ({id: i} for i in [0..10])
  #     a = (ids[i] for i in [1, 3, 4, 1, 1, 10])
  #     # a is [{id: 1}, {id: 3}, {id: 4}, {id: 1}, {id: 1}, {id: 10}]
  #     b = clone a
  #     sortBy b, "id"
  #     # b is [{id:1}, {id: 1}, {id: 1}, {id: 3}, {id: 4}, {id: 10}]
  #     uniq b
  #     # b now is [{id:1}, {id: 3}, {id: 4}, {id: 10}]
  uniq: (array) ->
    hash = {}

    i = 0
    while i < array.length
      if hash[array[i]] is true
        array.splice i, 1
        i -= 1
      else
        hash[array[i]] = true
      i += 1

    array
  
  # Return a new array composed of the rows of a matrix. I.e. convert
  #
  #     [[1, 2, 3], [4, 5, 6]] to [1, 2, 3, 4, 5, 6]
  flatten: (array) ->
    array.reduce((arrayA, arrayB) ->
      if not u.isArray arrayA
        arrayA = new ABM.Array arrayA
      arrayA.concat arrayB)

  # Returns a new array that has addArray appended
  #
  # Concat checks [[ClassName]], and this does not work for things
  # inheriting from Array.
  concat: (array, addArray) ->
    newArray = array.clone()
    if u.isArray addArray
      for element in addArray
        newArray.push element
    else
      newArray.push addArray

    newArray
  
  # Return an array with values in [low, high], defaults to [0, 1].
  # Note: to have a half-open interval, [low, high), try high = high - .00009
  normalize: (array, low = 0, high = 1) ->
    min = @min array
    max = @max array
    scale = 1 / (max - min)
    newArray = []
    for number in array
      newArray.push u.linearInterpolate(low, high, scale * (number - min))
    newArray

  normalizeInt: (array, low, high) ->
    (Math.round i for i in @normalize array, low, high)

  # Return a Uint8ClampedArray, normalized to [.5, 255.5] then round/clamp to [0, 255]
  # TODO maybe data-specific?
  normalize8: (array) ->
    new Uint8ClampedArray @normalize(array, -.5, 255.5)

  # ### Debugging
  
  # Useful in console.
  # Also see [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension.
  
  # Similar to NetLogo ask & with operators.
  # Allows functions as strings. Use:
  #
  #     AS.getProperty("x") # [1, 8, 6, 2, 2]
  #     AS.with("o.x < 5").ask("o.x = o.x + 1")
  #     AS.getProperty("x") # [2, 8, 6, 3, 3]
  #
  #     myModel.agents.with("o.id < 100").ask("o.color = [255, 0, 0]")
  ask: (array, functionString) ->
    if u.isString functionString
      eval("functionString=function(o){return " + functionString + ";}")
    functionString(object) for object in array
    array

  with: (array, functionString) ->
    if u.isString functionString
      eval("f=function(o){return " + functionString + ";}")
    @from (object for object in array when functionString(object))
 
  # ### Property Utilities

  # Property access, also useful for debugging<br>
  
  # Return an array of a property of the agentset
  #
  #      AS.getProperty "x" # [0, 8, 6, 1, 1]
  # TODO Prop -> Property
  getProperty: (array, property) ->
    object[property] for object in array

  # Return an array of agents with the property equal to the given value
  #
  #     AS.getPropertyWith "x", 1
  #     [{id: 4, x: 1, y: 3},{id: 5, x: 1, y: 1}]
  getPropertyWith: (array, property, value) ->
    @from (object for object in array when object[property] is value)

  # Set the property of the agents to a given value.  If value
  # is an array, its values will be used, indexed by agentSet's index.
  # This is generally used via: getProperty, modify results, setProperty
  #
  #     # increment x for agents with x=1
  #     AS1 = ABM.Set.from AS.getPropertyWith("x", 1)
  #     AS1.setProperty "x", 2 # {id: 4, x: 2, y: 3}, {id: 5, x: 2, y: 1}
  #
  # Note this changes the last two objects in the original AS above
  setProperty: (array, property, value) ->
    if u.isArray value
      object[property] = value[i] for object, i in array
    else
      object[property] = value for object in array
    array
 
  # Return an array without given object
  #
  #     as = AS.clone().other(AS[0])
  #     as.getProperty "id"  # [1, 2, 3, 4] 
  other: (array, given) ->
    @from (object for object in array when object isnt given) # could clone & remove


# Extends ABM.Array and util
  
ABM.util.array.extender =
  methods: ->
    (key for key, value of ABM.util.array when typeof value is 'function')

  extendArray: (className) ->
    methods = @methods()
    for method in methods
      eval("""
        #{className}.prototype.#{method} = function() {
          var options, _ref, _ret;
          options = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _ret = (_ref = u.array).#{method}.apply(_ref, [this].concat(__slice.call(options)));
          if (ABM.util.isArray(_ret)) {
            return this.constructor.from(_ret);
          } else {
            return _ret;
          }
        };""")

# An **ABM.Array** is an array, with some helper methods.
#
# It is a subclass of `Array` and is the base class for `ABM.Set`.
#
# Note: subclassing `Array` can be dangerous and we may have to convert
# to a different style. See Trevor Burnham's [comments](http://goo.gl/Lca8g)
# but thus far we've resolved all related problems.

# Shim for `Array.indexOf` if not implemented.
# Use [es5-shim](https://github.com/kriskowal/es5-shim) if additional shims needed.
# TODO look into
Array::indexOf or= (given) ->
  for object, i in @
    return i if object is given
  -1

Array::_sort = Array::sort

# Extended with ABM.util.array

class ABM.Array extends Array
  # ### Static members
  
  # `from` is a static wrapper function converting an array into
  # an `ABM.Array` ..
  #
  # It gains access to all the methods below. Ex:
  #
  #     array = [1, 2, 3]
  #     ABM.Array.from(array)
  #     randomNr = array.random()
  @from: (array, arrayType = ABM.Array) ->
    array.__proto__ = arrayType.prototype ? arrayType.constructor.prototype
    array
 
  # WARNING: Needs constructor or subclassing Array won't work
  constructor: (options...) ->
    return @constructor.from(options)
 
# ### Extending

# Adds most methods
#
ABM.util.array.extender.extendArray('ABM.Array')

# A *very* simple shapes module for drawing
# [NetLogo-like](http://ccl.northwestern.edu/netlogo/docs/) agents.

ABM.util.shapes = do ->
  # Each shape is a named object with two members: 
  # a boolean rotate and a draw procedure and two optional
  # properties: img for images, and shortcut for a transform-less version of draw.
  # The shape is used in the following context with a color set
  # and a transform such that the shape should be drawn in a -.5 to .5 square
  #
  #     context.save()
  #     context.fillStyle = u.colorString color
  #     context.translate x, y; context.scale size, size;
  #     context.rotate heading if shape.rotate
  #     context.beginPath(); shape.draw(context); context.closePath()
  #     context.fill()
  #     context.restore()
  #
  # The list of current shapes, via `u.shapes.names()` below, is:
  #
  #     ["default", "triangle", "arrow", "bug", "pyramid", 
  #      "circle", "square", "pentagon", "ring", "cup", "person"]
  
  # A simple polygon utility:  c is the 2D context, and a is an array of 2D points.
  # c.closePath() and c.fill() will be called by the calling agent, see initial 
  # discription of drawing context.  It is used in adding a new shape above.
  poly = (c, a) ->
    for p, i in a
      if i is 0 then c.moveTo p[0], p[1] else c.lineTo p[0], p[1]
    null

  # Centered drawing primitives: centered on x,y with a given width/height size.
  # Useful for shortcuts
  circ = (c, x, y, s) -> c.arc x, y, s / 2, 0, 2 * Math.PI # centered circle

  ccirc = (c, x, y, s) -> c.arc x, y, s / 2, 0, 2 * Math.PI, true # centered counter clockwise circle

  cimg = (c, x, y, s, img) ->
    c.scale 1,-1
    c.drawImage img, x - s / 2, y - s / 2, s, s
    c.scale 1,-1 # centered image

  csq = (c, x, y, s) -> c.fillRect x - s / 2, y - s / 2, s, s # centered square
  
  # An async util for delayed drawing of images into sprite slots
  fillSlot = (slot, img) ->
    slot.context.save()
    slot.context.scale 1, -1
    slot.context.drawImage img, slot.x, -(slot.y + slot.spriteSize), slot.spriteSize, slot.spriteSize
    slot.context.restore()

  # The spritesheet data, indexed by spriteSize
  spriteSheets = new ABM.Array
  
  # The module returns the following object:
  default:
    rotate: true
    draw: (c) ->
      poly c, [[.5, 0], [-.5, -.5], [-.25, 0], [-.5, .5]]

  triangle:
    rotate: true
    draw: (c) ->
      poly c, [[.5, 0], [-.5, -.4], [-.5, .4]]

  arrow:
    rotate: true
    draw: (c) ->
      poly c, [[.5,0], [0, .5], [0, .2], [-.5, .2], [-.5, -.2], [0, -.2], [0, -.5]]

  bug:
    rotate: true
    draw: (c) ->
      c.strokeStyle = c.fillStyle
      c.lineWidth = .05
      poly c, [[.4, .225], [.2, 0], [.4, -.225]]
      c.stroke()
      c.beginPath()
      circ c, .12, 0, .26
      circ c, -.05, 0, .26
      circ c, -.27, 0, .4

  pyramid:
    rotate: false
    draw: (c) ->
      poly c, [[0, .5], [-.433, -.25], [.433, -.25]]

  circle: # Note: NetLogo's dot is simply circle with a small size
    shortcut: (c, x, y, s) ->
      c.beginPath()
      circ c, x, y, s
      c.closePath()
      c.fill()
    rotate: false
    draw: (c) ->
      circ c, 0, 0, 1 # c.arc 0, 0,.5, 0, 2 * Math.PI

  square:
    shortcut: (c, x, y, s) ->
      csq c, x, y, s
    rotate: false
    draw: (c) ->
      csq c, 0, 0, 1 #c.fillRect -.5, -.5, 1 , 1

  pentagon:
    rotate: false
    draw: (c) ->
      poly c, [[0, .45], [-.45, .1], [-.3, -.45], [.3, -.45], [.45, .1]]

  ring:
    rotate: false
    draw: (c) ->
      circ c, 0, 0, 1
      c.closePath()
      ccirc c, 0, 0, .6

  filledRing:
    rotate: false
    draw: (c) ->
      circ(c, 0, 0, 1)
      tempStyle = c.fillStyle # save fill style
      c.fillStyle = c.strokeStyle # use stroke style for larger circle
      c.fill()
      c.fillStyle = tempStyle
      c.beginPath()
      circ(c, 0, 0, 0.8)

  person:
    rotate: false
    draw: (c) ->
      poly c, [
        [.15, .2], [.3, 0], [.125, -.1], [.125, .05], [.1, -.15], [.25, -.5],
        [.05, -.5], [0, -.25], [-.05, -.5], [-.25, -.5], [-.1, -.15],
        [-.125, .05], [-.125, -.1], [-.3, 0], [-.15, .2]
      ]
      c.closePath()
      circ c, 0, .35, .30

  # Return a list of the available shapes, see above.
  names: ->
    array = new ABM.Array
    for own name, val of @
      if val.rotate? and val.draw?
        array.push name
    array

  # Add your own shape. Will be included in names list.  Usage:
  #
  #     u.shapes.add "test", true, (c) -> # bowtie/hourglass
  #       u.shapes.poly c, [[-.5, -.5], [.5, .5], [-.5, .5], [.5, -.5]]
  #
  # Note: an image that is not rotated automatically gets a shortcut. 
  add: (name, rotate, draw, shortcut) -> # draw can be an image, shortcut defaults to null
    if u.isFunction draw
      shape = {rotate, draw}
    else
      shape = {rotate, img:draw, draw:(c) -> cimg c, .5, .5, 1, @img}

    @[name] = shape

    if shortcut? # can override img default shortcut if needed
      shape.shortcut = shortcut
    else if shape.img? and not shape.rotate
      shape.shortcut = (c, x, y, s) ->
        cimg c, x, y, s, @img

  # Add local private objects for use by add() and debugging
  poly:poly, circ:circ, ccirc:ccirc, cimg:cimg, csq:csq # export utils for use by add

  spriteSheets:spriteSheets # export spriteSheets for debugging, showing in DOM

  # Two draw procedures, one for shapes, the other for sprites made from shapes.
  draw: (context, shape, x, y, size, rad, color, strokeColor) ->
    if shape.shortcut?
      unless shape.img?
        context.fillStyle = u.colorString color
      shape.shortcut context, x, y, size
    else
      context.save()
      context.translate x, y
      context.scale size, size if size isnt 1
      context.rotate rad if rad isnt 0
      if shape.img? # is an image, not a path function
        shape.draw context
      else
        context.fillStyle = u.colorString color
        if strokeColor
          context.strokeStyle = u.colorStr strokeColor
          context.lineWidth = 0.05
        context.save()
        context.beginPath()
        shape.draw context
        context.closePath()
        context.restore()
        context.fill()
        context.stroke() if strokeColor

      context.restore()
    shape

  drawSprite: (context, slot, x, y, size, rad) ->
    if rad is 0
      context.drawImage context.canvas, slot.x, slot.y, slot.spriteSize,
        slot.spriteSize, x - size / 2, y - size / 2, size, size
    else
      context.save()
      context.translate x, y # see http://goo.gl/VUlhY for drawing centered rotated images
      context.rotate rad
      context.drawImage slot.context.canvas, slot.x, slot.y, slot.spriteSize,
        slot.spriteSize, -size / 2, -size / 2, size, size
      context.restore()
    slot

  # Convert a shape to a sprite by allocating a sprite sheet "slot" and drawing
  # the shape to fit it. Return existing sprite if duplicate.
  shapeToSprite: (name, color, size, strokeColor) ->
    spriteSize = Math.ceil size
    strokePadding = 4
    slotSize = spriteSize + strokePadding
    shape = @[name]
    index = if shape.img? then name else "#{name}-#{u.colorString(color)}"
    context = spriteSheets[slotSize]

    # Create sheet for this bit size if it does not yet exist
    unless context?
      spriteSheets[slotSize] = context = u.createContext slotSize * 10, slotSize
      context.nextX = 0
      context.nextY = 0
      context.index = {}

    # Return matching sprite if index match found
    return foundSlot if (foundSlot = context.index[index])?

    # Extend the sheet if we're out of space
    if slotSize * context.nextX is context.canvas.width
      u.resizeContext context, context.canvas.width, context.canvas.height + slotSize
      context.nextX = 0
      context.nextY++

    # Create the sprite "slot" object and install in index object
    x =  slotSize * context.nextX + strokePadding / 2
    y =  slotSize * context.nextY + strokePadding / 2
    slot = {context, x, y, size, spriteSize, name, color, strokeColor, index}
    context.index[index] = slot

    # Draw the shape into the sprite slot
    if (img = shape.img)? # is an image, not a path function
      if img.height isnt 0
        fillSlot(slot, img)
      else img.onload = ->
        fillSlot(slot, img)
    else
      context.save()
      context.translate (context.nextX + 0.5) * (slotSize),
        (context.nextY + 0.5) * (slotSize)
      context.scale spriteSize, spriteSize
      context.fillStyle = u.colorString color

      if strokeColor
        context.strokeStyle = u.colorString strokeColor
        context.lineWidth = 0.05

      context.save()
      context.beginPath()
      shape.draw context
      context.closePath()
      context.restore()
      context.fill()
      if strokeColor
        context.stroke()

      context.restore()
    
    context.nextX++
    slot

# An **ABM.AgentArray** is an array, with some agent/patch/link specific
# helper methods.
#
# It is a subclass of `ABM.Array` and is the base class for `ABM.BreedSet`.

class ABM.Set extends ABM.Array
  # `from` is a static wrapper function converting an array into
  # an `@model.Set`
  #
  # It gains access to all the methods below. Ex:
  #
  #     array = [1, 2, 3]
  #     @model.Set.from(array)
  #     randomNr = array.random()
  @from: (array, setType) ->
    if @model?
      setType ||= @model.Set
    else
      setType ||= ABM.Set

    array.__proto__ = setType.prototype ? setType.constructor.prototype
    array
  
  # The static `@model.Set.from` as a method.
  # Used by methods creating new sets.
  from: (array, setType = @) ->
    @model.Set.from array, setType # setType = @model.Set
    # TODO see if can be removed

  # In the examples below, we'll use an array of primitive agent objects
  # with three fields: id, x, y.
  #
  #     AS = for i in [1..5] # long form comprehension
  #       {id:i, x:u.randomInt(10), y:u.randomInt(10)}
  #     @model.Set.from AS # Convert AS to Set in place
  #        [{id: 1, x: 0, y: 1}, {id: 2, x: 8, y: 0}, {id: 3, x: 6, y: 4},
  #         {id: 4, x: 1, y: 3}, {id: 5, x: 1, y: 1}]

  # Set the default value of an agent class, return agentset
  setDefault: (name, value) ->
    @agentClass::[name] = value
    @

  # Return all agents that are not of the given breeds argument.
  # Breeds is a string of space separated names:
  #   @patches.exclude "roads houses"
  exclude: (breeds) ->
    breeds = breeds.split(" ")
    @from (o for o in @ when o.breed.name not in breeds)

  # ### Drawing
  
  # For agentsets whose agents have a `draw` method.
  # Clears the graphics context (transparent), then
  # calls each agent's draw(context) method.
  draw: (context) ->
    u.clearContext(context)
    o.draw(context) for o in @ when not o.hidden
    null
  
  # Show/Hide all of an agentset or breed.
  # To show/hide an individual object, set its prototype: o.hidden = bool
  show: ->
    o.hidden = false for o in @
    @draw(@model.contexts[@name])

  hide: ->
    o.hidden = true for o in @
    @draw(@model.contexts[@name])

  # ### Location/radius
  
  # Return all agents within d distance from given object.
  inRadius: (point, options) -> # for any objects w/ x, y
    inner = new @model.Set
    for entity in @
      if entity.distance(point) <= options.radius
        inner.push entity
    return inner
      
  # As above, but returns agents also limited to the angle `cone`
  # around a `heading` from point.
  inCone: (point, options) ->
    inner = new @model.Set
    for entity in @
      if u.inCone(options.heading, options.cone, options.radius,
          point, entity.position, @model.patches)
        inner.push entity
    return inner

# A **BreedSet** is an ABM.Set (which is an ABM.Array), along with a
# class, agentClass, whose instances are the items of the array.
# Instances of the class are created by the `create` factory method of
# a BreedSet.
#
# It is a subclass of `ABM.Set` and is the base class for `Patches`,
# `Agents`, and `Links`. A Set keeps track of all its created
# instances. It also provides, much like the **ABM.util** module, some
# methods shared by all subclasses of Set.
#
# A model contains three BreedSets:
#
# * `patches`: the model's "world" grid
# * `agents`: the model's agents living on the patches
# * `links`: the network links connecting agent pairs
#
# See NetLogo [documentation](http://ccl.northwestern.edu/netlogo/docs/)
# for explanation of the overall semantics of Agent Based Modeling
# used by Sets as well as Patches, Agents, and Links.
#
# Because we are an array subset, @[i] == this[i] == agentset[i]

class ABM.BreedSet extends ABM.Set
  # In the examples below, we'll use an array of primitive agent objects
  # with three fields: id, x, y.
  #
  #     AS = for i in [1..5] # long form comprehension
  #       {id:i, x:u.randomInt(10), y:u.randomInt(10)}
  #     ABM.BreedSet.from AS # Convert AS to Set in place
  #        [{id: 1, x: 0, y: 1}, {id: 2, x: 8, y: 0}, {id: 3, x: 6, y: 4},
  #         {id: 4, x: 1, y: 3}, {id: 5, x: 1, y: 1}]

  # ### Constructor and add/remove agents.
  
  # Create an empty `Set` and initialize the `ID` counter for add().
  # If mainSet is supplied, the new agentset is a sub-array of mainSet.
  # This sub-array feature is how breeds are managed, see class `Model`
  constructor: (agentClass, name, mainSet) ->
    super(0) # doesn't yield empty array if already instances in the mainSet
    @agentClass = agentClass
    @name = name
    @mainSet = mainSet
    unless @mainSet?
      # Do not set breeds & ID if I'm a subset
      @breeds = []
      @ID = 0
    @agentClass::breed = @ # let the breed know I'm it's agentSet

  # Abstract method used by subclasses to create and add their instances.
  create: ->

  # Add an agent to the list. Only used by agentset factory methods. Adds
  # the `id` property to all agents. Increment `ID`.
  # Returns the object for chaining.
  #
  # By "agent" we mean an instance of `Patch`, `Agent` and `Link` and their breeds
  originalPush: @::push
  push: (object...) ->
    if object.length > 1
      for item in object
        @push item
    else
      object = object[0]
      @originalPush object

      if @mainSet?
        @mainSet.push object
      else
        if object.id?
          if object.breed? and object.breed.name is not @name
            object.id = @ID++
        else
          object.id = @ID++

    object

  # TODO remove
  add: (object) ->
    @push object

  # Remove an agent from the agentset, returning the agentset.
  # Note this does not change delete id or change the set's ID, thus
  # an agentset can have gaps in terms of their id's. 
  #
  #     AS.remove(AS[3]) # [{id: 0, x: 0, y: 1}, {id: 1, x: 8, y: 0},
  #                         {id: 2, x: 6, y: 4}, {id: 4, x: 1, y: 1}] 
  remove: (object) ->
    if @mainSet?
      @mainSet.remove object
    u.array.remove @, object
    @

  pop: () ->
    object = @last()
    @remove(object)
    object

  # Move an agent from its BreedSet to be in this BreedSet.
  #
  setBreed: (agent) ->
    agent.breed.remove agent
    @push agent
    proto = agent.__proto__ = @agentClass.prototype
    delete agent[key] for own key, value of agent when proto[key]?
    agent

  # Floodfill arguments:
  #
  # * aset: initial array of agents, often a single agent: [a]
  # * fCandidate(a, asetLast) -> true if a is elegible to be added to the set
  # * fJoin(a, asetLast) -> adds a to the agentset, usually by setting a variable
  # * fCallback(asetLast, asetNext) -> optional function to be called each iteration of floodfill;
  # if fCallback returns true, the flood is aborted
  # * fNeighbors(a) -> returns the neighbors of this agent
  # * asetLast: the array of the last set of agents to join the flood;
  # gets passed into fJoin, fCandidate, and fCallback
  floodFill: (aset, fCandidate, fJoin, fCallback, fNeighbors, asetLast = []) ->
    floodFunc = @floodFillOnce(aset, fCandidate, fJoin, fCallback, fNeighbors, asetLast)
    floodFunc = floodFunc() while floodFunc

  # Move one step forward in a floodfill. floodFillOnce() returns a function that performs the next step of the flood.
  # This is useful if you want to watch your flood progress as an animation.
  floodFillOnce: (aset, fCandidate, fJoin, fCallback, fNeighbors, asetLast = []) ->
    fJoin p, asetLast for p in aset
    asetNext = []
    for p in aset
      for n in fNeighbors(p) when fCandidate n, aset
        asetNext.push n if asetNext.indexOf(n) < 0
    stopEarly = fCallback and fCallback(aset, asetNext)
    if stopEarly or asetNext.length is 0 then return null
    else return () =>
      @floodFillOnce asetNext, fCandidate, fJoin, fCallback, fNeighbors, aset
  
  # Similar to above but sorted via `id`.
  # TODO remove
  asOrderedSet: (a) ->
    @from(a).sort("id")

# ### Agent
  
# Class Agent instances represent the dynamic, behavioral element of ABM.
# Each agent knows the patch it is on, and interacts with that and other
# patches, as well as other agents.
class ABM.Agent
  # Constructor & Class Variables:
  #
  # * id:          unique identifier, promoted by agentset create() factory method
  # * breed:       the agentset this agent belongs to
  # * x, y:        position on the patch grid, in patch coordinates, default: 0, 0
  # * size:        size of agent, in patch coordinates, default: 1
  # * color:       the color of the agent, default: randomColor
  # * shape:       the shape name of the agent, default: "default"
  # * label:       a text label drawn on my instances
  # * labelColor:  the color of my label text
  # * labelOffset: the x, y offset of my label from my x, y location
  # * heading:     direction of the agent, in radians, from x-axis
  # * hidden:      whether or not to draw this agent
  # * patch:       patch at current x, y location
  # * penDown:     true if agent pen is drawing
  # * penSize:     size in pixels of the pen, default: 1 pixel
  # * sprite:      an image of the agent if non null
  # * links:       array of links in/out of me
  #
  # These class variables are "defaults" and many are "promoted" to instance variables.
  # To have these be set to a constant for all instances, use breed.setDefault.
  # This can be a huge savings in memory.
  id: null              # unique id, promoted by agentset create factory method
  breed: null           # my agentSet, set by the agentSet owning me
  position: null        # my location, has float .x & .y
  patch: null           # the patch I'm on
  size: 1               # my size in patch coordinates
  color: null           # default color, overrides random color if set
  strokeColor: null     # color of the border of an agent
  shape: "default"      # my shape
  hidden: false         # draw me?
  label: null           # my text
  labelColor: [0, 0, 0] # its color
  labelOffset: [0, 0]   # its offset from my x, y
  penDown: false        # if my pen is down, I draw my path between changes in x, y
  penSize: 1            # the pen thickness in pixels
  heading: null         # the direction I'm pointed in, in radians
  sprite: null          # an image of me for optimized drawing
  links: null           # array of links to/from me as an endpoint; init by ctor

  constructor: -> # called by agentSets create factory, not user
    @position = {x: 0, y: 0}
    @color = u.randomColor() unless @color? # promote color if default not set
    @heading = u.randomFloat(Math.PI * 2) unless @heading?
    @links = new ABM.Array
    @moveTo @position

  # ### Strings

  # Return a string representation of the agent.
  toString: ->
    "{id: #{@id}, position: {x: #{@position.x.toFixed 2}," +
      " y: #{@position.y.toFixed 2}}, c: #{@color}, h: #{@heading.toFixed 2}}"

  # ### Movement and space
  
  # Place the agent at the given patch/agent location
  #
  # Place the agent at the given point (floats) in patch coordinates using
  # patch topology (isTorus)
  moveTo: (point) ->
    if @penDown
      [x0, y0] = [@position.x, @position.y]

    @position = @model.patches.coordinate point
    oldPatch = @patch
    @patch = @model.patches.patch @position

    if oldPatch and oldPatch isnt @patch
      oldPatch.agents.remove @
    @patch.agents.push @

    if @penDown
      drawing = @model.drawing
      drawing.strokeStyle = u.colorString @color
      drawing.lineWidth = @model.patches.fromBits @penSize
      drawing.beginPath()
      drawing.moveTo x0, y0
      drawing.lineTo @position.x, @position.y # REMIND: euclidean
      drawing.stroke()

  # Moves the agent off the grid, making him lose his patch
  moveOff: ->
    if @patch
      @patch.agents.remove @
    @patch = @position = null

  # Move forward (along heading) by distance units (patch coordinates),
  # using patch topology (isTorus)
  forward: (distance) ->
    @moveTo(
      x: @position.x + distance * Math.cos(@heading),
      y: @position.y + distance * Math.sin(@heading))
  
  # Change current heading by radians which can be + (left) or - (right)
  rotate: (radians) ->
    @heading = u.wrap @heading + radians, 0, Math.PI * 2 # returns new h
  
  # Set heading towards given agent/patch using patch topology.
  face: (point) ->
    @heading = u.angle @position, point, @model.patches

  # Return distance in patch coordinates from me to given agent/patch
  # using patch topology (isTorus)
  distance: (point) -> # o any object w/ x, y, patch or agent
    u.distance @position, point, @model.patches

  # Returns the neighbors (agents) of this agent
  neighbors: (options) ->
    options ?= 1
    if options.radius
      square = @neighbors(options.radius)
      if options.cone
        options.heading ?= @heading
        # adopt heading unless explicitly given
        neighbors = square.inCone(@position, options)
      else
        neighbors = square.inRadius(@position, options)
    else
      neighbors = @breed.from []
      if @patch
        for patch in @patch.neighbors(options)
          for agent in patch.agents
            if agent isnt @
              neighbors.push agent

    neighbors

  # ### Life and death

  # Remove myself from the model. Includes removing myself from the
  # agents agentset and removing any links I may have.
  die: ->
    @breed.remove @
    for link in @links by -1
      link.die()
    @moveOff()
    null

  # Factory: create num new agents at this agents location. The optional init
  # proc is called on the new agent after inserting in its agentSet.
  hatch: (number = 1, breed = @model.agents, init = ->) ->
    breed.create number, (agent) => # fat arrow so that @ = this agent
      agent.moveTo @position # for side effects like patches.agents
      for own key, value of @ when key isnt "id"
        agent[key] = value
      init(agent) # Important: init called after object inserted in agent set
      agent

  # ### Links

  # Return other end of link from me
  otherEnd: (link) ->
    if link.from is @
      link.to
    else
      link.from
 
  # Return links where I am the "from" agent in links.create
  outLinks: ->
    link for link in @links when link.from is @
 
  # Return links where I am the "to" agent in links.create
  inLinks: ->
    link for link in @links when link.to is @

  # All agents linked to me.
  linkNeighbors: ->
    array = new ABM.Array
    for link in @links
      array.push @otherEnd(link)
    array.uniq()
 
  # Other end of myInLinks
  inLinkNeighbors: ->
    array = new ABM.Array
    for link in @inLinks()
      array.push link.from
    array.uniq()
 
  # Other end of myOutinks
  outLinkNeighbors: ->
    array = new ABM.Array
    for link in @outLinks()
      array.push link.to
    array.uniq()

  # ### Drawing

  # Draw the agent, instanciating a sprite if required
  draw: (context) ->
    if @patch is null
      return
    shape = u.shapes[@shape]
    radians = if shape.rotate then @heading else 0 # radians
    if @sprite? or @breed.useSprites
      @setSprite() unless @sprite? # lazy evaluation of useSprites
      u.shapes.drawSprite context, @sprite, @position.x, @position.y, @size, radians
    else
      u.shapes.draw context, shape, @position.x, @position.y, @size, radians, @color, @strokeColor
    if @label?
      [x, y] = @model.patches.patchXYtoPixelXY @x, @y
      u.contextDrawText context, @label, x + @labelOffset[0], y + @labelOffset[1], @labelColor
  
  # Set an individual agent's sprite, synching its color, shape, size
  setSprite: (sprite)->
    if (sprite)?
      @sprite = sprite
      @color = sprite.color
      @strokeColor = sprite.strokeColor
      @shape = sprite.shape
      @size = sprite.size
    else
      @color = u.randomColor unless @color?
      @sprite = u.shapes.shapeToSprite @shape, @color,
        @model.patches.toBits(@size), @strokeColor
    
  # Draw the agent on the drawing layer, leaving permanent image.
  stamp: -> @draw @model.drawing

# ### Agents

# Class Agents is a subclass of Set which stores instances of Agent or 
# Breeds, which are subclasses of Agent
class ABM.Agents extends ABM.BreedSet
  # Constructor creates the empty Set instance and installs
  # the agentClass (breed) variable shared by all the Agents in this set.
  constructor: -> # agentClass, name, mainSet
    super # call super with all the args I was called with
    @useSprites = false

  # Use sprites rather than drawing
  setUseSprites: (@useSprites = true) ->
  
  # Filter to return all instances of this breed. Note: if used by
  # the mainSet, returns just the agents that are not subclassed breeds.
  in: (agents) ->
    array = []

    for agent in agents
      if agent.breed is @
        array.push agent

    @from array

  # Factory: create num new agents stored in this agentset. The optional init
  # proc is called on the new agent after inserting in its agentSet.
  create: (num, initialize = ->) -> # returns array of new agents too
    ((o) -> initialize(o); o) @add new @agentClass for i in [1..num] by 1 # too tricky?
    # TODO refactor!

  # Remove all agents from set via agent.die()
  # Note call in reverse order to optimize list restructuring.
  clear: ->
    @last().die() while @any()
    null # tricky, each die modifies list
  
  # Return the members of this agentset that are neighbors of agent
  # using patch topology
  neighboring: (agent, rangeOptions) ->
    array = agent.neighbors(rangeOptions)
    @in array

  # Circle Layout: position the agents in the list in an equally
  # spaced circle of the given radius, with the initial agent
  # at the given start angle (default to pi / 2 or "up") and in the
  # +1 or -1 direction (counder clockwise or clockwise) 
  # defaulting to -1 (clockwise).
  formCircle: (radius, startAngle = Math.PI / 2, direction = -1) ->
    dTheta = 2 * Math.PI / @.length

    for agent, i in @
      agent.moveTo x: 0, y: 0
      agent.heading = startAngle + direction * dTheta * i
      agent.forward radius

    null

# Class Model is the control center for our Sets: Patches, Agents and Links.
# Creating new models is done by subclassing class Model and overriding two 
# virtual/abstract methods: `setup()` and `step()`

# ### Animator
  
# Because not all models have the same amimator requirements, we build a class
# for customization by the programmer.  See these URLs for more info:
#
# * [JavaScript timers doc](https://developer.mozilla.org/en-US/docs/JavaScript/Timers)
# * [Using timers & requestAnimFrame together](http://goo.gl/ymEEX)
# * [John Resig on timers](http://goo.gl/9Q3q)
# * [jsFiddle setTimeout vs rAF](http://jsfiddle.net/calpo/H7EEE/)
# * [Timeout tutorial](http://javascript.info/tutorial/settimeout-setinterval)
# * [Events and timing in depth](http://javascript.info/tutorial/events-and-timing-depth)
  
class ABM.Animator
  # Create initial animator for the model, specifying default rate (fps) and multiStep.
  # If multiStep, run the draw() and step() methods separately by draw() using
  # requestAnimFrame and step() using setTimeout.
  constructor: (@model, @rate = 30, @multiStep = model.world.isHeadless) ->
    @isHeadless = model.world.isHeadless
    @reset()

  # Adjust animator.  Call before model.start()
  # in setup() to change default settings
  setRate: (@rate, @multiStep = @isHeadless) -> @resetTimes() # Change rate while running?

  # start/stop model, often used for debugging and resetting model
  start: ->
    return unless @stopped # avoid multiple animates
    @resetTimes()
    @stopped = false
    @animate()

  stop: ->
    @stopped = true
    if @animatorHandle?
      cancelAnimFrame @animatorHandle
    if @timeoutHandle?
      clearTimeout @timeoutHandle
    if @intervalHandle?
      clearInterval @intervalHandle
    @animatorHandle = @timerHandle = @intervalHandle = null

  # Internal util: reset time instance variables
  resetTimes: ->
    @startMS = @now()
    @startTick = @ticks
    @startDraw = @draws

  # Reset used by model.reset when resetting model.
  reset: ->
    @stop()
    @ticks = @draws = 0

  # Two handlers used by animation loop
  step: ->
    @ticks++
    @model.step()

  draw: ->
    @draws++
    @model.draw()

  # step and draw the model once, mainly debugging
  once: ->
    @step()
    @draw()

  # Get current time, with high resolution timer if available
  now: -> (performance ? Date).now()

  # Time in ms since starting animator
  ms: -> @now() - @startMS

  # Get ticks/draws per second. They will differ if multiStep.
  # The "if" is to avoid from ms=0
  ticksPerSec: ->
    elapsed = @ticks - @startTick
    if elapsed is 0
      0
    else
      Math.round elapsed * 1000 / @ms()

  drawsPerSec: ->
    elapsed = @draws - @startDraw
    if elapsed is 0
      0
    else
      Math.round elapsed * 1000 / @ms()

  # Return a status string for debugging and logging performance
  toString: -> 
    "ticks: #{@ticks}, draws: #{@draws}, rate: #{@rate} " +
      "tps/dps: #{@ticksPerSec()}/#{@drawsPerSec()}"

  # Animation via setTimeout and requestAnimFrame
  animateSteps: =>
    @step()
    @timeoutHandle = setTimeout @animateSteps, 10 unless @stopped

  animateDraws: =>
    if @isHeadless # Use rAF when headless wants to be throttled.
      @step() if @ticksPerSec() < @rate
    else if @drawsPerSec() < @rate # throttle drawing to @rate
      @step() unless @multiStep
      @draw()
    @animatorHandle = requestAnimFrame @animateDraws unless @stopped

  animate: ->
    @animateSteps() if @multiStep
    @animateDraws() unless @isHeadless and @multiStep

# ### Link
  
# Class Link connects two agent endpoints for graph modeling.
class ABM.Link
  # Constructor initializes instance variables:
  #
  # * id:         unique identifier, promoted by agentset create() factory method
  # * breed:      the agentset this agent belongs to
  # * from:       two agents being connected
  # * to:
  # * color:      defaults to light gray
  # * thickness:  thickness in pixels of the link, default 2
  # * label:      a text label drawn on my instances
  # * labelColor: the color of my label text
  # * labelOffset:the x, y offset of my label from my x, y location
  # * hidden:     whether or not to draw this link

  id: null               # unique id, promoted by agentset create factory method
  breed: null            # my agentSet, set by the agentSet owning me
  from: null              # My two endpoints, using agents. Promoted by ctor
  to: null
  color: [130, 130, 130] # my color
  thickness: 2           # my thickness in pixels, default to 2
  hidden: false          # draw me?
  label: null            # my text
  labelColor: [0, 0, 0]  # its color
  labelOffset: [0, 0]    # its offset from my midpoint

  constructor: (@from, @to) ->
    @from.links.push @
    @to.links.push @
      
  # Draw a line between the two endpoints. Draws "around" the
  # torus if appropriate using two lines. As with Agent.draw,
  # is called with patch coordinate transform installed.
  draw: (context) ->
    context.save()
    context.strokeStyle = u.colorString @color
    context.lineWidth = @model.patches.fromBits @thickness
    context.beginPath()

    if !@model.patches.isTorus
      context.moveTo @from.position.x, @from.position.y
      context.lineTo @to.position.x, @to.position.y
    else
      point = u.closestTorusPoint @from.position, @to.position,
        @model.patches.numX, @model.patches.numY
      context.moveTo @from.position.x, @from.position.y
      context.lineTo point.x, point.y
      if point.x isnt @to.position.x or point.y isnt @to.position.y
        point = u.closestTorusPoint @to.position, @from.position,
          @model.patches.numX, @model.patches.numY
        context.moveTo @to.position.x, @to.position.y
        context.lineTo point.x, point.y

    context.closePath()
    context.stroke()
    context.restore()

    if @label?
      x0 = u.linearInterpolate @from.position.x, @to.position.x, .5
      y0 = u.linearInterpolate @from.position.y, @to.position.y, .5
      [x, y] = @model.patches.patchXYtoPixelXY x0, y0
      u.contextDrawText context, @label, x + @labelOffset[0], y + @labelOffset[1], @labelColor
  
  # Remove this link from the agent set
  die: ->
    @breed.remove @
    @from.links.remove @
    @to.links.remove @
    null
  
  # Return the two endpoints of this link
  bothEnds: ->
    new ABM.Array(@from, @to)
  
  # Return the distance between the endpoints with the current topology.
  length: ->
    @from.distance @to.position
  
  # Return the other end of the link, given an endpoint agent.
  # Assumes the given input *is* one of the link endpoint pairs!
  otherEnd: (a) ->
    if @from is a 
      @to
    else
      @from

# ### Links
  
# Class Links is a subclass of Set which stores instances of Link
# or subclasses of Link

class ABM.Links extends ABM.BreedSet
  # Constructor: super creates the empty Set instance and installs
  # the agentClass (breed) variable shared by all the Links in this set.
  constructor: -> # agentClass, name, mainSet
    super # call super with all the args I was called with

  # Factory: Add 1 or more links from the from agent to the to agent(s) which
  # can be a single agent or an array of agents. The optional init
  # proc is called on the new link after inserting in the agentSet.
  create: (from, to, init = ->) -> # returns array of new links too
    to = [to] unless to.length?
    ((o) -> init(o); o) @add new @agentClass from, a for a in to # too tricky?
  
  # Remove all links from set via link.die()
  # Note call in reverse order to optimize list restructuring.
  clear: ->
    while @any()
      @last().die()

    null # tricky, each die modifies list

  # Return all the nodes in this agentset, with duplicates
  # included.  If 4 links have the same endpoint, it will
  # appear 4 times.
  nodesWithDups: -> # all link ends, w / dups
    set = new @model.Set

    for link in @
      set.push link.from, link.to

    set

  # Returns all the nodes in this agentset with duplicates removed.
  nodes: ->
    @nodesWithDups().uniq()

# Class Model is the control center for our Sets: Patches, Agents and Links.
# Creating new models is done by subclassing class Model and overriding two 
# virtual/abstract methods: `setup()` and `step()`

# ### Class Model

ABM.models = {} # user space, put your models here

class ABM.Model
  # Class variable for layers parameters. 
  # Can be added to by programmer to modify/create layers, **before** starting your own model.
  # Example:
  # 
  #     v.z++ for k, v of ABM.Model::contextsInit # increase each z value by one
  contextsInit: { # Experimental: image:   {z: 15, context: "img"} 
    patches:   {z: 10, context: "2d"}
    drawing:   {z: 20, context: "2d"}
    links:     {z: 30, context: "2d"}
    agents:    {z: 40, context: "2d"}
    spotlight: {z: 50, context: "2d"}
  }
  # Constructor: 
  #
  # * create agentsets, install them and ourselves in ABM global namespace
  # * create layers/contexts, install drawing layer in ABM global namespace
  # * setup patch coordinate transforms for each layer context
  # * intialize various instance variables
  # * call `setup` abstract method
  constructor: (options) ->
    div = options.div
    isHeadless = options.isHeadless = options.isHeadless or not div?
    @setWorld options

    @contexts = {}

    unless isHeadless
      (@div = document.getElementById(div)).setAttribute 'style',
        "position:relative; width:#{@world.pxWidth}px; height:#{@world.pxHeight}px"

      # * Create 2D canvas contexts layered on top of each other.
      # * Initialize a patch coordinate transform for each layer.
      # 
      # Note: this transform is permanent .. there isn't the usual context.restore().
      # To use the original canvas 2D transform temporarily:
      #
      #     u.setIdentity context
      #       <draw in native coordinate system>
      #     context.restore() # restore patch coordinate system
      for own key, value of @contextsInit
        @contexts[key] = context = u.createLayer @div, @world.pxWidth,
          @world.pxHeight, value.z, value.context
        if context.canvas?
          @setContextTransform context
        if context.canvas?
          context.canvas.style.pointerEvents = 'none'
        u.elementTextParams context, "10px sans-serif", "center", "middle"

      # One of the layers is used for drawing only, not an agentset:
      @drawing = @contexts.drawing
      @drawing.clear = => u.clearContext @drawing
      # Setup spotlight layer, also not an agentset:
      @contexts.spotlight.globalCompositeOperation = "xor"

    # if isHeadless
    # # Initialize animator to headless default: 30fps, async  
    # then @animator = new ABM.Animator @, null, true
    # # Initialize animator to default: 30fps, not async
    # else 
    @animator = new ABM.Animator @
    # Set drawing controls.  Default to drawing each agentset.
    # Optimization: If any of these is set to false, the associated
    # agentset is drawn only once, remaining static after that.
    @refreshLinks = @refreshAgents = @refreshPatches = true

    # Give class prototypes a 'model' attribute that references this model.
    @Patches = @extendWithModel(ABM.Patches)
    @Patch = @extendWithModel(ABM.Patch)
    @Agents = @extendWithModel(ABM.Agents)
    @Agent = @extendWithModel(ABM.Agent)
    @Links = @extendWithModel(ABM.Links)
    @Link = @extendWithModel(ABM.Link)
    @Set = @extendWithModel(ABM.Set)

    # Initialize agentsets.
    @patchBreeds 'patches'
    @agentBreeds 'agents'
    @linkBreeds 'links'

    # Initialize model global resources
    @debugging = false
    @modelReady = false
    @globalNames = null
    @globalNames = u.ownKeys @
    @globalNames.set = false
    @startup()

    u.waitOnFiles =>
      @modelReady = true
      @setup()
      @globals() unless @globalNames.set

  # Initialize/reset world parameters.
  setWorld: (options) ->
    defaults = {
      patchSize: 13, mapSize: 32, isTorus: false, hasNeighbors: true,
      isHeadless: false}

    for own key, value of defaults
      options[key] ?= value

    options.min ?= {x: -1 * options.mapSize / 2, y: -1 * options.mapSize / 2}
    options.max ?= {x: options.mapSize / 2, y: options.mapSize / 2}
    options.mapSize = null # not passed on, because optional

    @world = {}

    for own key, value of options
      @world[key] = value

    @world.width = @world.max.x - @world.min.x + 1
    @world.height = @world.max.y - @world.min.y + 1
    @world.pxWidth = @world.width * @world.patchSize
    @world.pxHeight = @world.height * @world.patchSize
    @world.minCoordinate = {x: @world.min.x - .5, y: @world.min.y - .5}
    @world.maxCoordinate = {x: @world.max.x + .5, y: @world.max.y + .5}

  setContextTransform: (context) ->
    context.canvas.width = @world.pxWidth
    context.canvas.height = @world.pxHeight
    context.save()
    context.scale @world.patchSize, -@world.patchSize
    context.translate -(@world.minCoordinate.x), -(@world.maxCoordinate.y)

  globals: (globalNames) ->
    if globalNames?
      @globalNames = globalNames
      @globalNames.set = true
    else
      @globalNames = u.ownKeys(@).removeItems @globalNames

  # Add this model to a class's prototype. This is used in
  # the model constructor to create Patch/Patches, Agent/Agents,
  # and Link/Links classes with a built-in reference to their model.
  extendWithModel: (original) ->
    model = @
    class extendedClass extends original
      @model: model
      model: model
      constructor: ->
        super
    return extendedClass

#### Optimizations:
  
  # Modelers "tune" their model by adjusting flags:<br>
  # `@refreshLinks, @refreshAgents, @refreshPatches`<br>
  # and by the following helper methods:

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support imageSmoothingEnabled or equivalent.
  setFastPatches: -> @patches.usePixels()

  # Patches are all the same static default color, just "clear" entire canvas.
  # Don't use if patch breeds have different colors.
  setMonochromePatches: -> @patches.monochrome = true
    
#### User Model Creation
# A user's model is made by subclassing Model and over-riding these
# two abstract methods. `super` need not be called.
  
  # Initialize model resources (images, files) here.  
  # Uses util.waitOn so can be be async.
  startup: -> # called by constructor

  # Initialize your model variables and defaults here.
  # If async used, make sure step/draw are aware of possible missing data.
  setup: ->

  # Update/step your model here
  step: -> # called each step of the animation

#### Animation and Reset methods

# Convenience access to animator:

  # Start/stop the animation
  start: ->
    u.waitOn (=> @modelReady), (=> @animator.start())
    @isRunning = true
    @

  stop: ->
    @animator.stop()
    @isRunning = false
    @

  toggle: ->
    if @isRunning
      @stop()
    else
      @start()

  # Animate once by `step(); draw()`. For UI and debugging from console.
  # Will advance the ticks/draws counters.
  once: ->
    unless @animator.stopped
      @stop()
    @animator.once()
    @

  # Stop and reset the model, restarting if restart is true
  reset: (restart = false) ->
    console.log "reset: animator"
    
    @animator.reset() # stop & reset ticks/steps counters
    
    console.log "reset: contexts"
    
    # clear/resize before agentsets
    for key, value in @contexts
      if value.canvas?
        value.restore()
        @setContextTransform value
    
    console.log "reset: patches, agents, links"
    
    @patchBreeds 'patches'
    @agentBreeds 'agents'
    @linkBreeds 'links'

    u.s.spriteSheets.length = 0 # possibly null out entries?
    console.log "reset: setup"
    
    @setup()
    @setRootVars() if @debugging
    @start() if restart

#### Animation.
  
# Call the agentset draw methods if either the first draw call or
# their "refresh" flags are set.  The latter are simple optimizations
# to avoid redrawing the same static scene. Called by animator.
  draw: (force = @animator.stopped) ->
    if force or @refreshPatches or @animator.draws is 1
      @patches.draw @contexts.patches
    if force or @refreshLinks or @animator.draws is 1
      @links.draw @contexts.links
    if force or @refreshAgents  or @animator.draws is 1
      @agents.draw @contexts.agents
    if @spotlightAgent?
      @drawSpotlight @spotlightAgent, @contexts.spotlight

# Creates a spotlight effect on an agent, so we can follow it
# throughout the model.
# Use:
#
#     @setSpotliight breed.sample()
#
# to draw one of a random breed. Remove spotlight by passing `null`
  setSpotlight: (@spotlightAgent) ->
    u.clearContext @contexts.spotlight unless @spotlightAgent?

  drawSpotlight: (agent, context) ->
    u.clearContext context
    u.fillContext context, [0, 0, 0, 0.6]
    context.beginPath()
    context.arc agent.x, agent.y, 3, 0, 2 * Math.PI, false
    context.fill()

# ### Breeds
  
# Three versions of NL's `breed` commands.
#
#     @patchBreeds "streets buildings"
#     @agentBreeds "embers fires"
#     @linkBreeds "spokes rims"
#
# will create 6 agentSets: 
#
#     @streets and @buildings
#     @embers and @fires
#     @spokes and @rims 
#
# These agentsets' `create` method create subclasses of Agent/Link.
# Use of <breed>.setDefault methods work as for agents/links, creating default
# values for the breed set:
#
#     @embers.setDefault "color", [255, 0, 0]
#
# ..will set the default color for just the embers. Note: patch breeds are currently
# not usable due to the patches being prebuilt.  Stay tuned.
  
  createBreeds: (list, type, agentClass, breedSet) ->
    if u.isString list
      list = list.split(" ")

    breeds = []
    breeds.classes = {}
    breeds.sets = {}

    resetType = false

    for string in list
      if string is type
        @[type] = new breedSet agentClass, string
      else
        breedClass = class Breed extends agentClass
        breed = @[string] = # add @<breed> to local scope
          new breedSet breedClass, string, agentClass::breed # create subset agentSet

        breeds.push breed
        breeds.sets[string] = breed
        breeds.classes["#{string}Class"] = breedClass

    @[type].breeds = breeds

  patchBreeds: (list, agentClass = @Patch, breedSet = @Patches) ->
    @createBreeds list, 'patches', agentClass, breedSet

  agentBreeds: (list, agentClass = @Agent, breedSet = @Agents) ->
    @createBreeds list, 'agents', agentClass, breedSet

  linkBreeds: (list, agentClass = @Link, breedSet = @Links) ->
    @createBreeds list, 'links', agentClass, breedSet
  
  # A simple debug aid which places short names in the global name space.
  # Note we avoid using the actual name, such as "patches" because this
  # can cause our modules to mistakenly depend on a global name.
  # See [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension too.
  debug: (@debugging = true) ->
    u.waitOn (=> @modelReady), (=> @setRootVars())
    @

  # TODO get rid of
  setRootVars: ->
    root.ps  = @patches
    root.p0  = @patches[0]
    root.as  = @agents
    root.a0  = @agents[0]
    root.ls  = @links
    root.l0  = @links[0]
    root.dr  = @drawing
    root.u   = ABM.util
    root.cx  = @contexts
    root.an  = @animator
    root.gl  = @globals
    root.dv  = @div
    root.root= root
    root.app = @

# ### Patch
  
# Class Patch instances represent a rectangle on a grid.  They hold variables
# that are in the patches the agents live on. The set of all patches (@model.patches)
# is the world on which the agents live and the model runs.
class ABM.Patch
  # Constructor & Class Variables:
  # * id:          unique identifier, promoted by agentset create() factory method
  # * breed:       the agentset this agent belongs to
  # * position:    position on the patch grid, .x and .y in patch coordinates
  # * color:       the color of the patch as an RGBA array, A optional.
  # * hidden:      whether or not to draw this patch
  # * label:       text for the patch
  # * labelColor:  the color of my label text
  # * labelOffset: the x, y offset of my label from my x, y location

  id: null              # unique id, promoted by agentset create factory method
  breed: null           # set by the agentSet owning this patch
  position: null        # The patch position in the patch grid, in .x and .y
  color: [0, 0, 0]      # The patch color
  hidden: false         # draw me?
  label: null           # text for the patch
  labelColor: [0, 0, 0] # text color
  labelOffset: [0, 0]   # text offset from the patch center
  agents: null          # agents on this patch
  
  # New Patch: Just set x, y.
  #constructor: (@x, @y) ->
  constructor: (@position) ->
    @neighborsCache = {}
    @agents = new ABM.Array

  # Return a string representation of the patch.
  toString: ->
    "{id:#{@id} position: {x: #{@position.x}, y: #{@position.y}}," +
    "c: #{@color}}"

  # Draw the patch and its text label if there is one.
  draw: (context) ->
    context.fillStyle = u.colorString @color
    context.fillRect @position.x - .5, @position.y - .5, 1, 1
    if @label? # REMIND: should be 2nd pass.
      position = @breed.patchXYtoPixelXY @position
      u.contextDrawText context, @label, position.x + @labelOffset[0],
        position.y + @labelOffset[1], @labelColor
  
  empty: ->
    @agents.empty()

  # Returns true if this patch is on the edge of the grid.
  isOnEdge: ->
    @position.x is @breed.min.x or @position.x is @breed.max.x or \
    @position.y is @breed.min.y or @position.y is @breed.max.y
  
  # Factory: Create num new agents on this patch. The optional init
  # proc is called on the new agent after inserting in its agentSet.
  sprout: (number = 1, breed = @model.agents, init = ->) ->
    breed.create number, (agent) => # fat arrow so that @ = this patch
      agent.moveTo @position
      init(agent)
      agent

  # Return distance in patch coordinates from me to given agent/patch
  # using patch topology (isTorus)
  distance: (point) -> # o any object w/ x, y, patch or agent
    u.distance @position, point, @model.patches

  # Get neighbors for patch
  neighbors: (options) ->
    options ?= 1

    if u.isNumber(options)
      options = {range: options}

    if not options.cache? or options.cache
      cacheKey = JSON.stringify(options)
      neighbors = @neighborsCache[cacheKey]

    if not neighbors?
      if options.radius
        square = @neighbors(range: options.radius, meToo: options.meToo,
          cache: options.cache)
        if options.cone
          neighbors = square.inCone(@position, options)
          unless options.cache
            cacheKey = null
            # cone has variable heading, better not cache by default
        else
          neighbors = square.inRadius(@position, options)
      else if options.diamond
        neighbors = @diamondNeighbors(options.diamond, options.meToo)
      else
        neighbors = @breed.patchRectangle(@, options.range, options.range, options.meToo)
  
      if cacheKey?
        @neighborsCache[cacheKey] = neighbors

    return neighbors

  # Not to be used directly, will not cache.
  diamondNeighbors: (range, meToo) ->
    neighbors = @breed.patchRectangleNullPadded @, range, range, true
    diamond = new @model.Set
    counter = 0
    row = 0
    column = -1
    span = range * 2 + 1

    for neighbor in neighbors
      row = counter % span
      if row == 0
        column += 1
      distanceColumn = Math.abs(column - range)
      distanceRow = Math.abs(row - range)
      if distanceRow + distanceColumn <= range and
          (meToo or distanceRow + distanceColumn != 0)
        diamond.push neighbor
      counter += 1

    diamond.remove(null)

    return diamond

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
