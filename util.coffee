# This documentation uses Jeremy Ashkenas's
# [docco](http://jashkenas.github.com/docco/) which allows
# [markdown](http://daringfireball.net/projects/markdown/syntax).

# Create the namespace **ABM** for our project.
# Note here `this` or `@` == window due to coffeescript wrapper call.
# Thus @ABM is placed in the global scope.
@ABM={}

root = @ # Keep a private copy of global object

# Global shim for not-yet-standard requestAnimationFrame.
# See: [Paul Irish Shim](https://gist.github.com/paulirish/1579671)
do -> 
  @requestAnimFrame = @requestAnimationFrame or null
  @cancelAnimFrame = @cancelAnimationFrame or null
  for vendor in ['ms', 'moz', 'webkit', 'o'] when not @requestAnimFrame
    @requestAnimFrame or= @[vendor+'RequestAnimationFrame']
    @cancelAnimFrame or= @[vendor+'CancelAnimationFrame']
    @cancelAnimFrame or= @[vendor+'CancelRequestAnimationFrame']
  @requestAnimFrame or= (callback) -> @setTimeout(callback, 1000 / 60)
  @cancelAnimFrame or= (id) -> @clearTimeout(id)

# Shim for `Array.indexOf` if not implemented.
# Use [es5-shim](https://github.com/kriskowal/es5-shim) if additional shims needed.
Array::indexOf or= (item) -> # shim for IE8
  for x, i in this
    return i if x is item
  return -1


# **ABM.util** contains the general utilities for the project. Note that within
# **util** `@` referrs to ABM.util, *not* the global name space as above.
# Alias: u is an alias for ABM.util within the agentscript module (not outside)
#
#      u.clearCtx(ctx) is equivalent to
#      ABM.util.clearCtx(ctx)

ABM.util = u =

  # Shortcut for throwing an error.  Good for debugging:
  #
  #     error("wtf? foo=#{foo}") if fooProblem
  error: (s) -> throw new Error s
  
  # Good replacements for Javascript's badly broken`typeof` and `instanceof`
  # See [underscore.coffee](http://goo.gl/L0umK)
  isArray: Array.isArray or # works with agentSets too
    (obj) -> !!(obj and obj.concat and obj.unshift and not obj.callee)
  isFunction: (obj) -> 
    !!(obj and obj.constructor and obj.call and obj.apply)
  isString: (obj) -> 
    !!(obj is '' or (obj and obj.charCodeAt and obj.substr))
  
# ### Numeric Operations
  
  # Return random int in [0,max) or [min,max)
  randomInt: (max) -> Math.floor(Math.random() * max)
  randomInt2: (min, max) -> min + Math.floor(Math.random() * (max-min))
  # Return float in [0,max) or [min,max) or [-r/2,r/2)
  randomFloat: (max) -> Math.random() * max
  randomFloat2: (min, max) -> min + Math.random() * (max-min)
  randomCentered: (r) -> @randomFloat2 -r/2, r/2
  # Return log n where base is 10, base, e respectively
  log10: (n) -> Math.log(n)/Math.LN10
  logN: (n, base) -> Math.log(n)/Math.log(base)
  ln: (n) -> Math.log n
  # Return true [mod functin](http://goo.gl/spr24), % is remainder, not mod.
  mod: (v, n) -> ((v % n) + n) % n
  # Return v to be between min, max via mod fcn
  wrap: (v, min, max) -> min + @mod(v-min, max-min)
  # Return v to be between min, max via clamping with min/max
  clamp: (v, min, max) -> Math.max(Math.min(v,max),min)
  # Return sign of a number as +/- 1
  sign: (v) -> return (if v<0 then -1 else 1)
  # Return a string float array for printing using given precision and separator
  aToFixed: (a,p=2,s=", ") -> "[#{(i.toFixed p for i in a).join(s)}]"

# ### Color and Angle Operations
# Our colors are r,g,b,[a] arrays, with an optional color.str HTML
# color string property. The str value is set on the first call to colorStr
  
  # Return a random RGB or gray color. Array passed to minimize garbage collection
  randomColor: (c = []) -> 
    c.str = null if c.str?
    c[i] = @randomInt(256) for i in [0..2]
    c 
  # Note: if 2 args passed, assume they're min, max w/ default c
  randomGray: (c = [], min = 64, max = 192) -> 
    if arguments.length is 2 then return @randomGray null, c, min
    c.str = null if c.str?
    r=@randomInt2 min,max
    c[i] = r for i in [0..2]
    c
  # Random color from a colormap set of r,g,b values, default is one of 125 (5^3) colors
  randomMapColor: (c = [], set = [0,63,127,191,255]) -> 
    @setColor c, u.oneOf(set), u.oneOf(set), u.oneOf(set)
  randomBrightColor: (c=[]) -> @randomMapColor c, [0,127,255]
  # Modify an existing color. Modifying an existing array minimizes GC overhead
  setColor: (c, r, g, b, a) ->
    c.str = null if c.str?
    c[0] = r; c[1] = g; c[2] = b; c[3] = a if a?
    c
  # Return new color, c, by scaling each value of the rgb color max.
  scaleColor: (max, s, c = []) -> 
    c.str = null if c.str?
    c[i] = @clamp(Math.round(val*s),0,255) for val, i in max # [r,g,b] must be ints
    c
  # Return HTML color as used by canvas element.  Can include Alpha
  colorStr: (c) ->
    return s if (s = c.str)?
    c.str = if c.length is 3 then "rgb(#{c})" else "rgba(#{c})"
  # Compare two colors.  Alas, there is no array.Equal operator.
  colorsEqual: (c1, c2) -> c1.toString() is c2.toString()
    
  # Return little/big endian-ness of hardware. 
  # See Mozilla pixel [manipulation article](http://goo.gl/Lxliq)
  isLittleEndian: ->
    d8 = new Uint8ClampedArray 4
    d32 = new Uint32Array d8.buffer
    d32[0] = 0x01020304
    d8[0] is 4
  # Convert between degrees and radians.  We/Math package use radians.
  degToRad: (degrees) -> degrees * Math.PI / 180
  radToDeg: (radians) -> radians * 180 / Math.PI
  # Return angle in (-pi,pi] that added to rad2 = rad1
  subtractRads: (rad1, rad2) ->
    dr = rad1-rad2; PI = Math.PI
    dr += 2*PI if dr <= -PI; dr -= 2*PI if dr > PI; dr
  
# ### Object Operations
  
  # Return object's own variable names, less function in second version
  ownKeys: (obj) -> key for own key, value of obj
  ownVarKeys: (obj) -> key for own key, value of obj when not @isFunction value

# ### Array Operations
  
  # Does the array have any elements? Is the array empty?
  any: (array) -> array.length isnt 0
  empty: (array) -> array.length is 0
  # Make a copy of the array. Needed when you don't want to modify the given
  # array with mutator methods like sort, splice or your own functions.
  clone: (array) -> array.slice 0
  # Return last element of array.  Error if empty.
  last: (array) -> 
    @error "last: empty array" if @empty array
    array[array.length-1]
  # Return random element of array.  Error if empty.
  oneOf: (array) -> 
    @error "oneOf: empty array" if @empty array
    array[@randomInt array.length]
  # Return n random elements of array.  Error if n > array size.
  nOf: (array, n) -> # Note: clone, shuffle then first n may be better
    @error "nOf: n > length" if n > array.length
    r = []; while r.length < n
      o = @oneOf(array)
      r.push o unless o in r
    r
  contains: (array, item) -> -1 isnt array.indexOf item
  # Remove an item from an array. Error if item not in array.
  removeItem: (array, item) ->
    array.splice i, 1 if (i = array.indexOf item) isnt -1
    @error "removeItem: item not found" if i < 0
    i
    
  # Randomize the elements of array.  Clever! See [cookbook](http://goo.gl/TT2SY)
  shuffle: (array) -> array.sort -> 0.5 - Math.random()

  # Return o when f(o) min/max in array. Error if array empty.
  # If f is a string, return element with max value of that property.
  # If "valueToo" then return an array of the element and the value.
  # 
  #     array = [{x:1,y:2}, {x:3,y:4}]
  #     # returns {x: 1, y: 2} 5
  #     [min, dist2] = minOneOf array, ((o)->o.x*o.x+o.y*o.y), true
  #     # returns {x: 3, y: 4}
  #     max = maxOneOf array, "x"
  minOneOf: (array, f, valueToo=false) ->
    @error "minOneOf: empty array" if @empty array
    r = Infinity; o = null; (s=f; f = ((o)->o[s])) if @isString f
    for a in array
      (r = r1; o = a) if (r1=f(a)) < r
    if valueToo then [o, r] else o
  maxOneOf: (array, f, valueToo=false) ->
    @error "maxOneOf: empty array" if @empty array
    r = -Infinity; o = null; (s=f; f = ((o)->o[s])) if @isString f
    for a in array
      (r = r1; o = a) if (r1=f(a)) > r
    if valueToo then [o, r] else o

  # Return histogram of o when f(o) is a numeric value in array.
  # Histogram interval is bin. Error if array empty.
  # If f is a string, return histogram of that property.
  #
  # In examples below, histOf returns [3,1,1,0,0,1]
  #
  #     a = [1,3,4,1,1,10]
  #     h = histOf a, 2, (i) -> i
  #     
  #     b = ({id:i} for i in a)
  #     h = histOf b, 2, (o) -> o.id
  #     h = histOf b, 2, "id"
  histOf: (array, bin, f) ->
    r = []; (s=f; f = ((o)->o[s])) if @isString f
    for a in array
      i = Math.floor f(a)/bin
      r[i] = if (ri=r[i])? then ri+1 else 1
    r[i] = 0 for val,i in r when not val?
    r

  # Mutator. Sorts the array of objects in place by the property. Returns array.
  # Clone first if you want to preserve the original array.
  #
  #     array = [{i:1},{i:5},{i:-1},{i:2},{i:2}]
  #     sortBy array, "i"
  #     # array now is [{i:-1},{i:1},{i:2},{i:2},{i:5}]
  sortBy: (array, prop) -> array.sort (a,b) -> a[prop] - b[prop]

  # Mutator. Removes adjacent dups, by reference, in place from sorted array.
  # Note "by reference" means litteraly same object, not copy. Returns array.
  # Clone first if you want to preserve the original array.
  #
  #     ids = ({id:i} for i in [0..10])
  #     a = (ids[i] for i in [1,3,4,1,1,10])
  #     # a is [{id:1},{id:3},{id:4},{id:1},{id:1},{id:10}]
  #     b = clone a
  #     sortBy b, "id"
  #     # b is [{id:1},{id:1},{id:1},{id:3},{id:4},{id:10}]
  #     uniq b
  #     # b now is [{id:1},{id:3},{id:4},{id:10}]
  uniq: (array) ->
    array.splice i,1 for i in [array.length-1..1] by -1 when array[i-1] is array[i]
    array
  
  # Return a new array composed of the rows of a matrix. I.e. convert
  #
  #     [[1,2,3],[4,5,6]] to [1,2,3,4,5,6]
  flatten: (matrix) -> matrix.reduce( (a,b) -> a.concat b )
  
  # Return max/min/sum/avg of numeric array
  aMax: (array) -> array.reduce (a,b) -> Math.max a,b
  aMin: (array) -> array.reduce (a,b) -> Math.min a,b
  aSum: (array) -> array.reduce (a,b) -> a+b
  aMul: (array) -> array.reduce (a,b) -> a*b
  aAvg: (array) -> @aSum(array)/array.length
  # Return array composed of f pairwise on both arrays
  aPairwise: (a1, a2, f) -> v=0; f(v,a2[i]) for v,i in a1 
  aPairSum: (a1, a2) -> @aPairwise a1, a2, (a,b)->a+b
  aPairDif: (a1, a2) -> @aPairwise a1, a2, (a,b)->a-b
  aPairMul: (a1, a2) -> @aPairwise a1, a2, (a,b)->a*b

  # Return a JS array given a TypedArray
  typedToJS: (typedArray) -> (i for i in typedArray)
  
  # Return an array with values in [0,norm], defaults to [0,1).
  # Note: to have a half-open interval, [0,norm), use something like norm-.00009
  normalize: (array, norm=.999999999) ->
    min = @aMin array; scale = (norm)/(@aMax(array) - min)
    (num-min)*scale for num in array    

  # Binary search of a sorted array, adapted from [jaskenas](http://goo.gl/ozAZH).
  # Search for index of value with items array, using fcn for item value.
  # Return -1 if not found.
  binarySearch: (items, value, fcn = (ex) -> ex) ->
    start = 0
    stop  = items.length - 1
    pivot = Math.floor (start + stop) / 2
    while (pivotVal = fcn(items[pivot])) isnt value and start < stop
      stop  = pivot - 1 if value < pivotVal  # Adjust the search area.
      start = pivot + 1 if value > pivotVal
      pivot = Math.floor (stop + start) / 2  # Recalculate the pivot.
    if fcn(items[pivot]) is value then pivot else -1


# ### Topology Operations
  
  # Return angle in (-pi,pi] radians from x1,y1 to x2,y2.
  radsToward: (x1, y1, x2, y2) -> 
    PI = Math.PI; dx = x2-x1; dy = y2-y1
    if dx is 0 then return 3*PI/2 if dy < 0; return PI/2 if dy > 0; return 0
    else return Math.atan(dy/dx) + if dx < 0 then PI else 0
  # Return true if x2,y2 is in cone radians around heading radians from x1,x2
  # and within distance radius from x1,x2.
  # I.e. is p2 in cone/heading/radius from p1
  inCone: (heading, cone, radius, x1, y1, x2, y2) ->
    if radius < @distance x1, y1, x2, y2 then return false
    angle12 = @radsToward x1, y1, x2, y2 # angle from 1 to 2
    cone/2 >=Math.abs @subtractRads(heading, angle12)
  # Return the Euclidean distance and distance squared between x1,y1, x2,y2.
  # The squared distance is used for comparisons to avoid the Math.sqrt fcn.
  distance: (x1, y1, x2, y2) -> dx = x1-x2; dy = y1-y2; Math.sqrt dx*dx + dy*dy
  sqDistance: (x1, y1, x2, y2) -> dx = x1-x2; dy = y1-y2; dx*dx + dy*dy

  # Return the [torus distance](http://goo.gl/PgJ5N) and distance squared
  # between two points A(x1,y1) and B(x2,y2):
  #
  #     dx = |x2-x1|; dy = |y2-y1|
  #     d=sqrt(min(dx, W-dx)^2 + min(dy, H-dy)^2)
  #
  # Torus note: ABMs often use a Torus topology where the right and left edges
  # fold to meet,and similarly for the top/bottom.
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
  torusDistance: (x1, y1, x2, y2, w, h) -> 
    Math.sqrt @torusSqDistance x1, y1, x2, y2, w, h
  torusSqDistance: (x1, y1, x2, y2, w, h) ->
    dx = Math.abs x2-x1; dy = Math.abs y2-y1
    dxMin = Math.min dx, w-dx; dyMin = Math.min dy, h-dy
    dxMin*dxMin + dyMin*dyMin
  # Return true if closest path between x1,y1 & x2,y2 wraps around the torus.
  torusWraps: (x1, y1, x2, y2, w, h) ->
    dx = Math.abs x2-x1; dy = Math.abs y2-y1
    dx > w-dx or dy > h-dy
  # Return 4 torus point reflections of x2,y2 around x1,y1
  torus4Pts: (x1, y1, x2, y2, w, h) ->
    x2r = if x2<x1 then x2+w else x2-w
    y2r = if y2<y1 then y2+h else y2-h
    [ [x2,y2], [x2r,y2], [x2,y2r], [x2r,y2r] ]
  # Return closest of 4 torus pts from A to B
  torusPt: (x1, y1, x2, y2, w, h) ->
    x2r = if x2<x1 then x2+w else x2-w
    y2r = if y2<y1 then y2+h else y2-h
    x = if Math.abs(x2r-x1) < Math.abs(x2-x1) then x2r else x2
    y = if Math.abs(y2r-y1) < Math.abs(y2-y1) then y2r else y2
    [x,y]
  # Return the angle from x1,y1 to x2.y2 on torus using shortest reflection.
  torusRadsToward: (x1, y1, x2, y2, w, h) -> 
    [x2,y2] = @torusPt x1, y1, x2, y2, w, h
    @radsToward x1, y1, x2, y2
  # Return true if x2,y2 is in cone radians around heading radians from x1,x2
  # and within distance radius from x1,x2 considering all torus reflections.
  inTorusCone: (heading, cone, radius, x1, y1, x2, y2, w, h) ->
    for p in @torus4Pts x1, y1, x2, y2, w, h
      return true if @inCone heading, cone, radius, x1, y1, p[0], p[1]
    false

# ### File I/O

  # Cache of file names used by file imports below
  fileIndex: {}
  # Import an image, executing (async) optional function f(img) on completion
  importImage: (name, f) ->
    if (img=@fileIndex[name])? or ((img=name).width and img.height)
      f(img) if f?
    else
      img = new Image()
      img.onload = -> f(img) if f?
      img.src = name
      @fileIndex[name] = img
    img
    
  # Use XMLHttpRequest to fetch data of several types.
  # Data Types: text, arraybuffer, blob, json, document, [Specification:](http://goo.gl/y3r3h)
  xhrLoadFile: (name, type="text", f) -> # AJAX request, sync if f is null
    if (xhr=@fileIndex[name])?
      f(xhr.response) if f?
    else
      xhr = new XMLHttpRequest()
      xhr.open "GET", name, f?
      xhr.responseType = type
      xhr.onload = -> f(xhr.response) if f?
      xhr.send()
      @fileIndex[name] = xhr
    xhr

# ### Canvas/Context Operations
  
  # Create a new canvas of given width/height
  createCanvas: (width, height) ->
    can = document.createElement 'canvas'
    can.width = width; can.height = height
    can
  # As above, but returing the context object.
  # Note ctx.canvas is the canvas for the ctx, and can be use as an image.
  createCtx: (width, height, ctxType="2d") ->
    can = @createCanvas width, height; can.ctxType = ctxType
    can.ctx = if ctxType is "2d" 
    then can.getContext "2d" 
    else can.getContext("webgl") ? can.getContext("experimental-webgl")

  # Return a "layer" 2D/3D rendering context within the specified HTML `<div>`,
  # with the given width/height positioned absolutely at top/left within the div,
  # and with the z-index of z.
  #
  # The z level gives us the capability of buildng a "stack" of coordinated canvases.
  createLayer: (div, width, height, z, ctx = "2d") -> # a canvas ctx object
    ctx = @createCtx width, height, ctx
    ctx.canvas.setAttribute 'style', "position:absolute;top:0;left:0;z-index:#{z}"
    document.getElementById(div).appendChild(ctx.canvas)
    ctx
  # Install identity transform.  Call ctx.restore() to revert to previous transform
  setIdentity: (ctx) ->
    ctx.save() # revert to native 2D transform
    ctx.setTransform 1, 0, 0, 1, 0, 0
  
  # Clear the 2D/3D layer to be transparent. Note this [discussion](http://goo.gl/qekXS).
  clearCtx: (ctx) ->
    if ctx.save? # test for 2D ctx
      @setIdentity ctx # ctx.canvas.width = ctx.canvas.width not used so as to preserve patch coords
      ctx.clearRect 0, 0, ctx.canvas.width, ctx.canvas.height
      ctx.restore()
    else # 3D
      ctx.clearColor 0, 0, 0, 0 # transparent!
      ctx.clear ctx.COLOR_BUFFER_BIT | ctx.DEPTH_BUFFER_BIT
  # Fill the 2D/3D layer with the given color
  fillCtx: (ctx, color) ->
    if ctx.fillStyle? # test for 2D ctx
      @setIdentity ctx
      ctx.fillStyle = @colorStr(color)
      ctx.fillRect 0, 0, ctx.canvas.width, ctx.canvas.height
      ctx.restore()
    else # 3D
      ctx.clearColor color..., 1 # alpha = 1 unless color is rgba
      ctx.clear ctx.COLOR_BUFFER_BIT | ctx.DEPTH_BUFFER_BIT
  # Draw string of the given color at the xy location.
  # Note that this will follow the existing transform.
  ctxDrawText: (ctx, string, xy, color = [0,0,0]) -> 
    ctx.fillStyle = @colorStr color
    ctx.fillText(string, xy[0], xy[1])
  # Set the canvas text align and baseline drawing parameters
  #
  # * font is a HTML/CSS string like: "9px sans-serif"
  # * align is left right center start end
  # * baseline is top hanging middle alphabetic ideographic bottom
  #
  # See [reference](http://goo.gl/AvEAq) for details.
  ctxTextParams: (ctx, font, align = "center", baseline = "middle") -> 
    ctx.font = font; ctx.textAlign = align; ctx.textBaseline = baseline
  # 2D: Store the default color and xy offset for text labels for agentsets.
  # This is simply using the ctx object for convenient storage.
  ctxLabelParams: (ctx, color, xy) -> # patches/agents defaults
    ctx.labelColor = color; ctx.labelXY = xy

  # Convert an image to a context. ctx.canvas gives the created canvas.
  imageToCtx: (image) ->
    ctx = @createCtx image.width, image.height
    ctx.drawImage image, 0, 0
    ctx

  # Convert a context to an image, executing function f on completion.
  # Generally can skip callback but see [stackoverflow](http://goo.gl/kIk2U)
  # Note: uses toDataURL thus possible cross origin problems.
  # Fix: use ctx.canvas for programatic imaging.
  ctxToImage: (ctx, f) ->
    img = new Image()
    img.onload = -> f(img) if f?
    img.src = ctx.canvas.toDataURL "image/png"
  # Convert a ctx to an imageData object
  ctxToImageData: (ctx) -> ctx.getImageData 0, 0, ctx.canvas.width, ctx.canvas.height

  # Canvas versions of above
  canvasToImage: (canvas) -> ctxToImage(canvas.getContext "2d")
  canvasToImageData: (canvas) -> ctxToImageData(canvas.getContext "2d")
  imageToCanvas: (image) -> imageToCtx(image).canvas
  
  # Draw an image centered at x, y w/ image size dx, dy.
  # See [this tutorial](http://goo.gl/VUlhY).
  drawCenteredImage: (ctx, img, rad, x, y, dx, dy) -> # presume save/restore surrounds this
    ctx.translate x, y # translate to center
    ctx.rotate rad
    ctx.drawImage img, -dx/2, -dy/2
  
  # Duplicate a ctx's image.  Returns the new ctx, use ctx.canvas for canvas.
  copyCtx: (ctx0) ->
    ctx = @createCtx ctx0.canvas.width, ctx0.canvas.height
    ctx.drawImage ctx0.canvas, 0, 0
    ctx
    
  # Resize a ctx/canvas and preserve data.
  resizeCtx: (ctx, width, height, scale = false) -> # http://goo.gl/Tp90B
    copy = @copyCtx ctx
    ctx.canvas.width = width; ctx.canvas.height = height
    ctx.drawImage copy.canvas, 0, 0

    
  
