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
  setColor: (c, r, g, b, a=null) ->
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

  # Useful for JS/debugging users: max/min of array, via pushing array.
  aMax: (array) -> Math.max array...
  aMin: (array) -> Math.min array...
  aPush: (array, a) -> array.push a...

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
# function loadFileAJAX(name) {
#     var xhr = new XMLHttpRequest(),
#         okStatus = document.location.protocol === "file:" ? 0 : 200;
#     xhr.open('GET', name, false);
#     xhr.send(null);
#     return xhr.status == okStatus ? xhr.responseText : null;
# };

  # Use XMLHttpRequest to fetch data of several types.
  # Data Types: text, arraybuffer, blob, json, document, ... see: http://goo.gl/y3r3h
  xhrLoadFile: (name, type="text", f=null) -> # AJAX request, sync if f is null
    xhr = new XMLHttpRequest()
    xhr.open "GET", name, f?
    xhr.responseType = type
    xhr.onload = -> f(xhr.response) if f?
    xhr.send()
    return xhr if f?
    okStatus = if document.location.protocol is "file:" then 0 else 200
    if xhr.status is okStatus then xhr.response else null

# ### Canvas/Context Operations
  
  # Create a new canvas of given width/height
  createCanvas: (width, height) ->
    can = document.createElement 'canvas'
    can.width = width; can.height = height
    can
  # As above, but returing the context object.  Note ctx.canvas is the canvas for the ctx.
  createCtx: (width, height, ctx="2d") ->
    can = @createCanvas width, height
    if ctx is "2d" then can.getContext "2d" 
    else can.getContext("webgl") or can.getContext("experimental-webgl")

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

  # Import an image, executing (async) optional function f(img) on completion
  importImage: (imageSrc, f=null) ->
    img = new Image()
    img.onload = -> f(img) if f?
    img.src = imageSrc
    img
    
  # Convert an image to a context. ctx.canvas gives the created canvas.
  imageToCtx: (image) ->
    ctx = @createCtx image.width, image.height
    ctx.drawImage image, 0, 0
    ctx

  # Convert a context to an image, executing function f on completion.
  # Generally can skip callback but see [stackoverflow](http://goo.gl/kIk2U)
  # Note: uses toDataURL thus possible cross origin problems.
  # Fix: use ctx.canvas for programatic imaging.
  ctxToImage: (ctx, f=null) ->
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

    
  


# A *very* simple shapes module for drawing
# [NetLogo-like](http://ccl.northwestern.edu/netlogo/docs/) agents.

ABM.shapes = ABM.util.s = do ->
  # Each shape is a named object with two members: 
  # a boolean rotate and a draw procedure and two optional
  # properties: img for images, and shortcut for a transform-less version of draw.
  # The shape is used in the following context with a color set
  # and a transform such that the shape should be drawn in a -.5 to .5 square
  #
  #     ctx.save()
  #     ctx.fillStyle = u.colorStr color
  #     ctx.translate x, y; ctx.scale size, size;
  #     ctx.rotate heading if shape.rotate
  #     ctx.beginPath(); shape.draw(ctx); ctx.closePath()
  #     ctx.fill()
  #     ctx.restore()
  #
  # The list of current shapes, via `ABM.shapes.names()` below, is:
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
  circ = (c,x,y,s)->c.arc x,y,s/2,0,2*Math.PI # centered circle
  ccirc = (c,x,y,s)->c.arc x,y,s/2,0,2*Math.PI,true # centered counter clockwise circle
  cimg = (c,x,y,s,img)->c.scale 1,-1;c.drawImage img,x-s/2,y-s/2,s,s;c.scale 1,-1 # centered image
  csq = (c,x,y,s)->c.fillRect x-s/2, y-s/2, s, s # centered square
  
  # An async util for delayed drawing of images into sprite slots
  fillSlot = (slot, img) ->
    slot.ctx.save(); slot.ctx.scale 1, -1
    slot.ctx.drawImage img, slot.x, -(slot.y+slot.bits), slot.bits, slot.bits    
    slot.ctx.restore()
  # The spritesheet data, indexed by bits
  spriteSheets = []
  
  # The module returns the following object:
  default:
    rotate: true
    draw: (c) -> poly c, [[.5,0],[-.5,-.5],[-.25,0],[-.5,.5]]
  triangle:
    rotate: true
    draw: (c) -> poly c, [[.5,0],[-.5,-.4],[-.5,.4]]
  arrow:
    rotate: true
    draw: (c) -> poly c, [[.5,0],[0,.5],[0,.2],[-.5,.2],[-.5,-.2],[0,-.2],[0,-.5]]
  bug:
    rotate: true
    draw: (c) ->
      c.strokeStyle = c.fillStyle; c.lineWidth = .05
      poly c, [[.4,.225],[.2,0],[.4,-.225]]; c.stroke()
      c.beginPath(); circ c,.12,0,.26; circ c,-.05,0,.26; circ c,-.27,0,.4
  pyramid:
    rotate: false
    draw: (c) -> poly c, [[0,.5],[-.433,-.25],[.433,-.25]]
  circle:
    shortcut: (c,x,y,s) -> c.beginPath(); circ c,x,y,s; c.closePath(); c.fill()
    rotate: false
    draw: (c) -> circ c,0,0,1 # c.arc 0,0,.5,0,2*Math.PI
  square:
    shortcut: (c,x,y,s) -> csq c,x,y,s
    rotate: false
    draw: (c) -> csq c,0,0,1 #c.fillRect -.5,-.5,1,1
  pentagon:
    rotate: false
    draw: (c) -> poly c, [[0,.45],[-.45,.1],[-.3,-.45],[.3,-.45],[.45,.1]]
  ring:
    rotate: false
    draw: (c) -> circ c,0,0,1; c.closePath(); ccirc c,0,0,.6
  cup: # an image shape, using coffeescript logo
    shortcut: (c,x,y,s) -> cimg c,x,y,s,@img
    rotate: false
    img: u.importImage "http://goo.gl/LTIyR"
    draw: (c) -> cimg c,.5,.5,1,@img
  person:
    rotate: false
    draw: (c) ->
      poly c, [  [.15,.2],[.3,0],[.125,-.1],[.125,.05],
      [.1,-.15],[.25,-.5],[.05,-.5],[0,-.25],
      [-.05,-.5],[-.25,-.5],[-.1,-.15],[-.125,.05],
      [-.125,-.1],[-.3,0],[-.15,.2]  ]
      c.closePath(); circ c,0,.35,.30 
  # Return a list of the available shapes, see above.
  names: ->
    (name for own name, val of @ when val.rotate? and val.draw?)
  # Add your own shape. Will be included in names list.  Usage:
  #
  #     ABM.shapes.add "test", true, (c) -> # bowtie/hourglass
  #       ABM.shapes.poly c, [[-.5,-.5],[.5,.5],[-.5,.5],[.5,-.5]]
  #
  # Note: an image that is not rotated automatically gets a shortcut. 
  add: (name, rotate, draw, shortcut = null) ->
    s = @[name] =
      if u.isFunction draw then {rotate,draw} else {rotate,img:draw,draw:(c)->cimg c,.5,.5,1,@img}
    (s.shortcut = (c,x,y,s) -> cimg c,x,y,s,@img) if s.img? and not s.rotate
    s.shortcut = shortcut if shortcut? # can override img default shortcut if needed

  # Add local private objects for use by add() and debugging
  poly:poly, circ:circ, ccirc:ccirc, cimg:cimg, csq:csq # export utils for use by add
  spriteSheets:spriteSheets # export spriteSheets for debugging, showing in DOM

  # Two draw procedures, one for shapes, the other for sprites made from shapes.
  draw: (ctx, shape, x, y, size, rad, color) ->
    if shape.shortcut?
      ctx.fillStyle = u.colorStr color if not shape.img?
      shape.shortcut ctx,x,y,size
    else
      ctx.save()
      ctx.translate x, y
      ctx.scale size, size if size isnt 1
      ctx.rotate rad if rad isnt 0
      if shape.img? # is an image, not a path function
        shape.draw ctx
      else
        ctx.fillStyle = u.colorStr color
        ctx.beginPath(); shape.draw ctx; ctx.closePath()
        ctx.fill()
      ctx.restore()
    shape
  drawSprite: (ctx, s, x, y, size, rad) ->
    if rad is 0
      ctx.drawImage s.ctx.canvas, s.x, s.y, s.bits, s.bits, x-size/2, y-size/2, size, size
    else
      ctx.save()
      ctx.translate x, y # see http://goo.gl/VUlhY for drawing centered rotated images
      ctx.rotate rad
      ctx.drawImage s.ctx.canvas, s.x, s.y, s.bits, s.bits, -size/2,-size/2, size, size
      ctx.restore()
    s
  # Convert a shape to a sprite by allocating a sprite sheet "slot" and drawing
  # the shape to fit it. Return existing sprite if duplicate.
  shapeToSprite: (name, color, size) ->
    bits = Math.ceil size*ABM.patches.size
    shape = @[name]
    index = if shape.img? then name else "#{name}-#{u.colorStr(color)}"
    ctx = spriteSheets[bits]
    # Create sheet for this bit size if it does not yet exist
    if not ctx?
      spriteSheets[bits] = ctx = u.createCtx bits*10, bits
      ctx.nextX = 0; ctx.nextY = 0; ctx.index = {}
    # Return matching sprite if index match found
    return foundSlot if (foundSlot = ctx.index[index])?
    # Extend the sheet if we're out of space
    if bits*ctx.nextX is ctx.canvas.width
      u.resizeCtx ctx, ctx.canvas.width, ctx.canvas.height+bits
      ctx.nextX = 0; ctx.nextY++
    # Create the sprite "slot" object and install in index object
    x = bits*ctx.nextX; y = bits*ctx.nextY
    slot = {ctx, x, y, size, bits, name, color, index}
    ctx.index[index] = slot
    # Draw the shape into the sprite slot
    if (img=shape.img)? # is an image, not a path function
      if img.height isnt 0 then fillSlot(slot, img)
      else img.onload = -> fillSlot(slot, img)
    else
      ctx.save()
      ctx.scale bits, bits
      ctx.translate ctx.nextX+.5, ctx.nextY+.5
      ctx.fillStyle = u.colorStr color
      ctx.beginPath(); shape.draw ctx; ctx.closePath()
      ctx.fill()
      ctx.restore()
    ctx.nextX++; slot

    



# An **AgentSet** is an array, along with a class, agentClass, whose instances
# are the items of the array.  Instances of the class are created
# by the `create` factory method of an AgentSet.
#
# It is a subclass of `Array` and is the base class for
# `Patches`, `Agents`, and `Links`. An AgentSet keeps track of all
# its created instances.  It also provides, much like the **ABM.util**
# module, many methods shared by all subclasses of AgentSet.
#
# ABM contains three agentsets created by class Model:
#
# * `ABM.patches`: the model's "world" grid
# * `ABM.agents`: the model's agents living on the patchs
# * `ABM.links`: the network links connecting agent pairs
#
# See NetLogo [documentation](http://ccl.northwestern.edu/netlogo/docs/)
# for explanation on the overall semantics of Agent Based Modeling
# used by AgentSets as well as Patches, Agents, and Links.
#
# Note: subclassing `Array` can be dangerous and we may have to convert
# to a different style. See Trevor Burnham's [comments](http://goo.gl/Lca8g)
# but thus far we've resolved all related problems.
#
# Because we are an array subset, @[i] == this[i] == agentset[i]

class ABM.AgentSet extends Array 
# ### Static members
  
  # `asSet` is a static wrapper function converting an array of agents into
  # an `AgentSet` .. except for the ID which only impacts the add method.
  # It is primarily used to turn a comprehension into an AgentSet instance
  # which then gains access to all the methods below.  Ex:
  #
  #     evens = (a for a in ABM.agents when a.id % 2 is 0)
  #     ABM.AgentSet.asSet(evens)
  #     randomEven = evens.oneOf()
  @asSet: (a, setType = ABM.AgentSet) ->
    a.__proto__ = setType.prototype ? setType.constructor.prototype # setType.__proto__
    a

  
  # In the examples below, we'll use an array of primitive agent objects
  # with three fields: id, x, y.
  #
  #     AS = for i in [1..5] # long form comprehension
  #       {id:i, x:u.randomInt(10), y:u.randomInt(10)}
  #     ABM.AgentSet.asSet AS # Convert AS to AgentSet in place
  #     # .. produced
  #        [{id:1,x:0,y:1}, {id:2,x:8,y:0}, {id:3,x:6,y:4},
  #         {id:4,x:1,y:3}, {id:5,x:1,y:1}]

# ### Constructor and add/remove agents.
  
  # Create an empty `AgentSet` and initialize the `ID` counter for add().
  # If mainSet is supplied, the new agentset is a sub-array of mainSet.
  # This sub-array feature is how breeds are managed, see class `Model`
  constructor: (@agentClass, @name, @mainSet = null) ->
    super()
    @agentClass::breed = @ # let the breed know I'm it's agentSet
    @ownVariables = []
    @ID = 0 if not @mainSet? # Do not set ID if I'm a subset

  # Abstract method used by subclasses to create and add their instances.
  create: ->
    
  # Add an agent to the list.  Only used by agentset factory methods. Adds
  # the `id` property to all agents. Increment `ID`.
  # Returns the object for chaining. The set will be sorted by `id`.
  #
  # By "agent" we mean an instance of `Patch`, `Agent` and `Link`.
  add: (o) ->
    if @mainSet? then @mainSet.add o else o.id = @ID++
    @push o; o

  # Remove an agent from the agentset, returning the agentset.
  # Note this does not change ID, thus an
  # agentset can have gaps in terms of their id's. Assumes set is
  # sorted by `id`. If the set is one created by `asSet`, and the original
  # array is unsorted, simply call `sortById` first, see `sortById` below.
  #
  #     AS.remove(AS[3]) # [{id:0,x:0,y:1}, {id:1,x:8,y:0},
  #                         {id:2,x:6,y:4}, {id:4,x:1,y:1}] 
  remove: (o) ->
    @mainSet.remove o if @mainSet?
    u.error "remove: empty arraySet" if @length is 0
    if o is @last()
      @[--@length] = null # set last to null and decrease length (null: GC subtlety)
    else
      @splice i, 1 if (i = @indexOfID o.id) isnt -1
      u.error "remove: indexOfID not in list" if i is -1
    @

  setDefault: (name, value) ->
    u.error "setDefault: name is not a string" if typeof name isnt "string"
    @agentClass::[name] = value

  own: (nameValueList...) ->
    u.error "own: odd number of arguments" if nameValueList.length % 2 isnt 0
    for name, i in nameValueList by 2
      @setDefault name, nameValueList[i+1]
      @ownVariables.push name
  

  # Remove adjacent duplicates, by reference, in a sorted agentset.
  # Use `sortById` first if agentset not sorted.
  #
  #     as = (AS.oneOf() for i in [1..4]) # 4 random agents w/ dups
  #     ABM.AgentSet.asSet as # [{id:1,x:8,y:0}, {id:0,x:0,y:1},
  #                              {id:0,x:0,y:1}, {id:2,x:6,y:4}]
  #     as.sortById().uniq() # [{id:0,x:0,y:1}, {id:1,x:8,y:0}, 
  #                             {id:2,x:6,y:4}]
  uniq: -> u.uniq(@)

  # Return the agent with the given `id` within the sorted agentset.
  # Uses binary search thus is faster than simple lookup.
  #
  #     AS.withID 4 # {id:4,x:1,y:1}
  withID: (id) -> # null if not found
    if (i = @indexOfID(id)) isnt -1 then @[i] else null

  # Return the array index of the given agent id in the sorted set.
  # If agentset is not sorted, call @sortById() first.
  #
  #     
  indexOfID: (id, sorted=true) -> # -1 if not found
    @sortById() unless sorted
    return @length-1 if id is @last().id  # no "die" calls yet
    u.binarySearch @, id, (o)->o.id

  # The static `ABM.AgentSet.asSet` as a method.
  # Used by agentset methods creating new agentsets.
  asSet: (a) -> ABM.AgentSet.asSet a # , @

  # Similar to above but sorted via `id`.
  asOrderedSet: (a) -> @asSet(a).sortById()

  # Return string representative of agentset.
  toString: -> "["+(a.toString() for a in @).join(", ")+"]"

# ### Property Utilities
# Property access, also useful for debugging<br>
  
  # Return an array of a property of the agentset
  #
  #      AS.getProp "x" # [0, 8, 6, 1, 1]
  getProp: (prop) -> o[prop] for o in @

  # Return an array of arrays of props, given as a string or an array of strings.
  #
  #     AS.getProps "id x y"
  #     AS.getProps ["id", "x", "y"]
  #     [[1,0,1],[2,8,0],[3,6,4],[4,1,3],[5,1,1]]
  getProps: (props) -> 
    props = props.split(" ") if u.isString props
    (o[p] for p in props) for o in @

  # Return an array of agents with the property equal to the given value
  #
  #     AS.getPropWith "x", 1
  #     [{id:4,x:1,y:3},{id:5,x:1,y:1}]
  getPropWith: (prop, value) -> @asSet (o for o in @ when o[prop] is value)

  # Set the property of the agents to a given value
  #
  #     # increment x for agents with x=1
  #     AS1 = ABM.AgentSet.asSet AS.getPropWith("x",1)
  #     AS1.setProp "x", 2 # {id:4,x:2,y:3},{id:5,x:2,y:1}
  #
  # Note this changes the last two objects in the original AS above
  setProp: (prop, value) -> o[prop] = value for o in @; @

  # Get the agent with the min/max prop value in the agentset
  #
  #     min = AS.minProp "y"  # 0
  #     max = AS.maxProp "y"  # 4
  maxProp: (prop) -> Math.max @getProp(prop)...
  minProp: (prop) -> Math.min @getProp(prop)...
  
# ### Array Utilities, often from ABM.util

  # Randomize the agentset
  #
  #     AS.shuffle(); AS.getProp "id" # [3, 2, 1, 4, 5] 
  shuffle: -> u.shuffle @

  # Sort the agentset by the agent's `id`.
  #
  #     AS.shuffle();  AS.getProp "id"  # [3, 2, 1, 4, 5] 
  #     AS.sortById(); AS.getProp "id"  # [1, 2, 3, 4, 5]
  sortById: -> u.sortBy @, "id"

  # Make a copy of an agentset, return as new agentset.<br>
  # NOTE: does *not* duplicate the objects, simply creates a new agentset
  # with references to the same agents.  Ex: create a randomized version of AS
  # but without mangling AS itself:
  #
  #     as = AS.clone().shuffle()
  #     AS.getProp "id"  # [1, 2, 3, 4, 5]
  #     as.getProp "id"  # [2, 4, 0, 1, 3]
  clone: -> @asSet u.clone @

  # Return the last agent in the agentset
  #
  #     AS.last().id             # l5
  #     l=AS.last(); p=[l.x,l.y] # [1,1]
  last: -> u.last @

  # Returns true if the agentset has any agents
  #
  #     AS.any()  # true
  #     AS.getPropWith("x", 99).any() #false
  any: -> u.any @

  # Return an agentset without given agent a
  #
  #     as = AS.clone().other(AS[0])
  #     as.getProp "id"  # [1, 2, 3, 4] 
  other: (a) -> @asSet (o for o in @ when o isnt a) # could clone & remove

  # Return random agent in agentset
  #
  #     AS.oneOf()  # {id:2,x:6,y:4}
  oneOf: -> u.oneOf @

  # Return agentset made of n distinct agents
  #
  #     AS.nOf(3) # [{id:0,x:0,y:1}, {id:4,x:1,y:1}, {id:1,x:8,y:0}]
  nOf: (n) -> @asSet u.nOf @, n

  # Return agent when f(o) min/max in agentset. If multiple agents have
  # min/max value, return the first. Error if agentset empty.
  # If f is a string, return element with min/max value of that property.
  # If "valueToo" then return an array of the agent and the value.
  # 
  #     AS.minOneOf("x") # {id:0,x:0,y:1}
  #     AS.maxOneOf((a)->a.x+a.y, true) # {id:2,x:6,y:4},10 
  minOneOf: (f, valueToo=false) ->
    u.minOneOf @, f, valueToo
  maxOneOf: (f, valueToo=false) ->
    u.maxOneOf @, f, valueToo

# ### Drawing
  
  # For agentsets who's agents have a `draw` method.
  # Clears the graphics context (transparent), then
  # calls each agent's draw(ctx) method.
  draw: (ctx) ->
    u.clearCtx(ctx)
    o.draw(ctx) for o in @ when not o.hidden; null

# ### Topology
  
  # For ABM.patches & ABM.agents which have x,y. See ABM.util doc.
  #
  # Return all agents in agentset within d distance from given object.
  # By default excludes the given object. Uses linear/torus distance
  # depending on patches.isTorus, and patches width/height if needed.
  inRadius: (o, d, meToo=false) -> # for any objects w/ x,y
    d2 = d*d; x=o.x; y=o.y
    if ABM.patches.isTorus
      w=ABM.patches.numX; h=ABM.patches.numY
      @asSet (a for a in @ when \
        u.torusSqDistance(x,y,a.x,a.y,w,h)<=d2 and (meToo or a isnt o))
    else
      @asSet (a for a in @ when \
        u.sqDistance(x,y,a.x,a.y)<=d2 and (meToo or a isnt o))
  # As above, but also limited to the angle `cone` around
  # a `heading` from object `o`.
  inCone: (o, heading, cone, radius, meToo=false) ->
    rSet = @inRadius o, radius, meToo
    x=o.x; y=o.y
    if ABM.patches.isTorus
      w=ABM.patches.numX; h=ABM.patches.numY
      @asSet (a for a in rSet when \
        (a is o and meToo) or u.inTorusCone(heading,cone,radius,x,y,a.x,a.y,w,h))
    else
      @asSet (a for a in rSet when \
        (a is o and meToo) or u.inCone(heading,cone,radius,x,y,a.x,a.y))    

# ### Debugging
  
  # Useful in console.
  # Also see [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension.
  
  # Similar to NetLogo ask & with operators.
  # Allows functions as strings. Use:
  #
  #     AS.getProp("x") # [1, 8, 6, 2, 2]
  #     AS.with("o.x<5").ask("o.x=o.x+1")
  #     AS.getProp("x") # [2, 8, 6, 3, 3]
  #
  #     ABM.agents.with("o.id<100").ask("o.color=[255,0,0]")
  ask: (f) -> 
    eval("f=function(o){return "+f+";}") if u.isString f
    f(o) for o in @; @
  with: (f) -> 
    eval("f=function(o){return "+f+";}") if u.isString f
    @asSet (o for o in @ when f(o))

# The example agentset AS used in the code fragments was made like this,
# slightly more useful than shown above due to the toString method.
#
#     class XY
#       constructor: (@x,@y) ->
#       toString: -> "{id:#{@id},x:#{@x},y:#{@y}}"
#     @AS = new ABM.AgentSet # @ => global name space
#
# The result of 
#
#     AS.add new XY(u.randomInt(10), u.randomInt(10)) for i in [1..5]
#
# random run, captured so we can reuse.
#
#     AS.add new XY(pt...) for pt in [[0,1],[8,0],[6,4],[1,3],[1,1]]


# There are three agentsets and their corresponding 
# agents: Patches/Patch, Agents/Agent, and Links/Link.

# ### Patch and Patches
  
# Class Patch instances represent a rectangle on a grid with:
#
# * id: installed by Patches agentset
# * x,y: the x,y position within the grid
# * color: the color of the patch as an RGBA array, A optional.
# * hidden: whether or not to draw this patch
# * label: text for the patch
# * n/n4: adjacent neighbors: n: 8 patches, n4: N,E,S,W patches.
# * breed: the agentset this patch belongs to
class ABM.Patch
  # Patches may not need their neighbors, thus we use a default
  # of none.  n and n4 are promoted by the Patches agent set 
  # if world.neighbors is true, the default.
  n: null
  n4: null
  color: [0,0,0]
  hidden: false
  label: null
  breed: null # set by the agentSet owning this patch
  
  # New Patch: Just set x,y. Neighbors set by Patches constructor if needed.
  constructor: (@x, @y) ->

  # Return a string representation of the patch.
  toString: ->
    "{id:#{@id} xy:#{u.aToFixed [@x,@y]} c:#{@color}}"

  # Set patch color to `c` scaled by `s`. Usage:
  #
  #     p.scaleColor p.color, .8 # reduce patch color by .8
  #     p.scaleColor @foodColor, p.foodPheromone # ants model
  #
  # Promotes color if currently using the default.
  scaleColor: (c, s) -> 
    @color = u.clone @color if not @.hasOwnProperty("color")
    u.scaleColor c, s, @color
  
  # Draw the patch and its text label if there is one.
  draw: (ctx) ->
    ctx.fillStyle = u.colorStr @color
    ctx.fillRect @x-.5, @y-.5, 1, 1
    if @label? # REMIND: should be 2nd pass.
      [x,y] = ctx.labelXY
      ctx.save() # bug: fonts don't scale for size < 1
      ctx.translate @x, @y
      ctx.scale 1/ABM.patches.size, -1/ABM.patches.size # revert to identity for text use
      u.ctxDrawText ctx, @label, [x,y], ctx.labelColor
      ctx.restore()
  
  # Return an array of the agents on this patch.
  # If patches.cacheAgentsHere has created an @agents instance
  # variable for the patches, agents will add/remove themselves
  # as they move from patch to patch.
  agentsHere: ->
    @agents ? (a for a in ABM.agents when a.p is @)
  
  # Returns true if this patch is on the edge of the grid.
  isOnEdge: ->
    @x is ABM.patches.minX or @x is ABM.patches.maxX or \
    @y is ABM.patches.minY or @y is ABM.patches.maxY
  
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
# * size: pixel h/w of each patch.
# * minX/maxX: min/max x coord in patch coords
# * minY/maxY: min/max y coord in patch coords
# * numX/numY: width/height of grid.
# * isTorus: true if coord system wraps around at edges
# * hasNeighbors: true if each patch caches its neighbors
class ABM.Patches extends ABM.AgentSet
  # Constructor: super creates the empty AgentSet instance and installs
  # the agentClass (breed) variable shared by all the Patches in this set.
  # Patches are created from top-left to bottom-right to match data sets.
  constructor: -> # agentClass, name, mainSet
    super # call super with all the args I was called with
    @[k] = v for own k,v of ABM.world # add world items to patches
    ABM.world.numX = @numX = @maxX-@minX+1 # add two more items to world
    ABM.world.numY = @numY = @maxY-@minY+1
    for y in [@maxY..@minY] by -1
      for x in [@minX..@maxX] by 1
        @add new ABM.Patch x, y
    @setNeighbors() if @hasNeighbors
    @setPixels() 
    @drawWithPixels = @size is 1 # if size is 1, default to true, otherwise false
  
  # Set the default color for new Patch instances.
  # Note coffeescript :: which refers to the Patch prototype.
  # This is the usual way to modify class variables.
  setDefaultColor: (color) -> ABM.Patch::color = color
  
  # Have patches cache the agents currently on them.
  # Optimizes p.agentsHere method.
  # Call before first agent is created.
  cacheAgentsHere: -> p.agents = [] for p in @; null

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support these flags.
  usePixels: (usePix=true) ->
    ctx = ABM.contexts.patches
    ctx.imageSmoothingEnabled = not usePix
    ctx.mozImageSmoothingEnabled = not usePix
    ctx.webkitImageSmoothingEnabled = not usePix
    u.setIdentity ctx
    @drawWithPixels = usePix

  # Optimization: Cache a single set by modeler for use by patchRect,
  # inCone, inRect, inRadius.  Ex: flock demo model's vision rect.
  cacheRect: (radius, meToo=false) ->
    for p in @
      p.pRect = @patchRect p, radius, radius, meToo
      p.pRect.radius = radius; p.pRect.meToo = meToo

  # Install neighborhoods in patches
  setNeighbors: -> 
    for p in @
      p.n =  @patchRect p, 1, 1
      p.n4 = @asSet (n for n in p.n when n.x is p.x or n.y is p.y)

  # Setup pixels used for `drawScaledPixels` and `importColors`
  setPixels: ->
    if @size is 1
      @pixelsCtx = ABM.contexts.patches
    else
      can = document.createElement 'canvas'  # small pixel grid for patch colors
      can.width = @numX; can.height = @numY
      @pixelsCtx = can.getContext "2d"
    @pixelsImageData = @pixelsCtx.getImageData(0, 0, @numX, @numY)
    @pixelsData = @pixelsImageData.data
    if @pixelsData instanceof Uint8Array # Check for typed arrays
      @pixelsData32 = new Uint32Array @pixelsData.buffer
      @pixelsAreLittleEndian = u.isLittleEndian()
  
  # If using scaled pixels, use pixel manipulation below, or use default agentSet
  # draw which iterates over the patches, drawing rectangles.
  draw: (ctx) -> if @drawWithPixels then @drawScaledPixels ctx else super ctx

# #### Patch grid coord system utilities:
  
  # Return the patch id/index given integer x,y in patch coords
  patchIndex: (x,y) -> x-@minX + @numX*(@maxY-y)
  # Return the patch at matrix position x,y where 
  # x & y are both valid integer patch coordinates.
  patchXY: (x,y) -> @[@patchIndex x,y]
  
  # Return x,y float values to be between min/max patch coord values
  clamp: (x,y) -> [u.clamp(x, @minX-.5, @maxX+.5), u.clamp(y, @minY-.5, @maxY+.5)]
  
  # Return x,y float values to be modulo min/max patch coord values.
  wrap: (x,y)  -> [u.wrap(x, @minX-.5, @maxX+.5),  u.wrap(y, @minY-.5, @maxY+.5)]
  
  # Return x,y float values to be between min/max patch values
  # using either clamp/wrap above according to isTorus topology.
  coord: (x,y) -> #returns a valid world coord (real, not int)
    if @isTorus then @wrap x,y else @clamp x,y

  # Return patch at x,y float values according to topology.
  patch: (x,y) -> 
    [x,y]=@coord x,y
    x = u.clamp Math.round(x), @minX, @maxX
    y = u.clamp Math.round(y), @minY, @maxY
    @patchXY x, y
  
  # Return a random valid float x,y point in patch space
  randomPt: -> [u.randomFloat2(@minX-.5,@maxX+.5), u.randomFloat2(@minY-.5,@maxY+.5)]

# #### Patch metrics
  
  # Return pixel width/height of patch grid
  bitWidth:  -> @numX*@size # methods, not constants in case resize
  bitHeight: -> @numY*@size
  
  # Convert patch measure to pixels
  patches2Bits: (p) -> p*@size
  # Convert bit measure to patches
  bits2Patches: (b) -> b/@size

# #### Patch utilities
  
  # Return an array of patches in a rectangle centered on the given 
  # patch `p`, dx, dy units to the right/left and up/down. 
  # Exclude `p` unless meToo is true, default false.
  patchRect: (p, dx, dy, meToo=false) ->
    if p.pRect? and p.pRect.radius is dx # and p.pRect.radius is dy
      return p.pRect
    rect = []; # REMIND: optimize if no wrapping, rect inside patch boundaries
    for y in [p.y-dy..p.y+dy] by 1 # by 1: perf: avoid bidir JS for loop
      for x in [p.x-dx..p.x+dx] by 1
        if @isTorus or (@minX<=x<=@maxX and @minY<=y<=@maxY)
          if @isTorus
            x+=@numX if x<@minX; x-=@numX if x>@maxX
            y+=@numY if y<@minY; y-=@numY if y>@maxY
          pnext = @patchXY x, y # much faster than coord()
          if not pnext?
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
  importDrawing: (imageSrc, f=null) ->
    u.importImage imageSrc, (img) ->
      ctx = ABM.drawing
      u.setIdentity ctx
      ctx.drawImage img, 0, 0, ctx.canvas.width, ctx.canvas.height
      ctx.restore() # restore patch transform
      f() if f?
  
  # Utility function for pixel manipulation.  Given a patch, returns the 
  # native canvas index i into the pixel data.
  # The top-left order simplifies finding pixels in data sets
  pixelByteIndex: (p) -> 4*p.id # Uint8
  pixelWordIndex: (p) -> p.id   # Uint32
    
  # Draws, or "imports" an image URL into the patches as their color property.
  # The drawing is scaled to the number of x,y patches, thus one pixel
  # per patch.  The colors are then transferred to the patches.
  importColors: (imageSrc, f=null) ->
    u.importImage imageSrc, (img) => # fat arrow, this context
      @pixelsCtx.drawImage img, 0, 0, @numX, @numY # scale if needed
      data = @pixelsCtx.getImageData(0, 0, @numX, @numY).data
      for p in @
        i = @pixelByteIndex p
        p.color = [data[i++], data[i++], data[i]] # promote initial default
      f() if f?
  
  # Draw the patches via pixel manipulation rather than 2D drawRect.
  # See Mozilla pixel [manipulation article](http://goo.gl/Lxliq)
  drawScaledPixels: (ctx) -> 
    if @pixelsData32?
      @drawScaledPixels32 ctx
    else
      @drawScaledPixels8 ctx
  # The 8-bit version for drawScaledPixels.  Used for systems w/o typed arrays
  drawScaledPixels8: (ctx) ->
    data = @pixelsData
    for p in @
      i = @pixelByteIndex p
      c = p.color
      data[i+j] = c[j] for j in [0..2] 
      data[i+3] = if c.length is 4 then c[3] else 255
    @pixelsCtx.putImageData(@pixelsImageData, 0, 0)
    return if @size is 1
    ctx.drawImage @pixelsCtx.canvas, 0, 0, ctx.canvas.width, ctx.canvas.height
  # The 32-bit version of drawScaledPixels, with both little and big endian hardware.
  drawScaledPixels32: (ctx) ->
    data = @pixelsData32
    for p in @
      i = @pixelWordIndex p
      c = p.color
      a = if c.length is 4 then c[3] else 255
      if @pixelsAreLittleEndian
        data[i] = 
          (a    << 24) |  # alpha
          (c[2] << 16) |  # blue
          (c[1] << 8)  |  # green
          c[0];           # red
      else
        data[i] = 
          (c[0] << 24) |  # red
          (c[1] << 16) |  # green
          (c[2] << 8)  |  # blue
          a;              # alpha
    @pixelsCtx.putImageData(@pixelsImageData, 0, 0)
    return if @size is 1
    ctx.drawImage @pixelsCtx.canvas, 0, 0, ctx.canvas.width, ctx.canvas.height
      
  # Diffuse the value of patch variable `p.v` by distributing `rate` percent
  # of each patch's value of `v` to its neighbors. If a color `c` is given,
  # scale the patch's color to be `p.v` of `c`. If the patch has
  # less than 8 neighbors, return the extra to the patch.
  diffuse: (v, rate, c) -> # variable name, diffusion rate, max color (optional)
    # zero temp variable if not yet set
    if not @[0]._diffuseNext?
      p._diffuseNext = 0 for p in @
    # pass 1: calculate contribution of all patches to themselves and neighbors
    for p in @
      dv = p[v]*rate; dv8 = dv/8; nn = p.n.length
      p._diffuseNext += p[v] - dv + (8-nn)*dv8
      n._diffuseNext += dv8 for n in p.n
    # pass 2: set new value for all patches, zero temp, modify color if c given
    if c
      for p in @
        p[v] = p._diffuseNext
        p._diffuseNext = 0
        p.scaleColor c, p[v]
    else
      for p in @
        p[v] = p._diffuseNext
        p._diffuseNext = 0
    null # avoid returning copy of @

# ### Agent & Agents
  
# Class Agent instances represent the dynamic, behavioral element of ABM.
class ABM.Agent
  # Constructor & Class Variables:
  #
  # * x,y: position on the patch grid, in patch coordinates, default: 0,0
  # * color: the color of the agent, default: randomColor
  # * shape: the shape name of the agent, default: "default"
  # * heading: direction of the agent, in radians, from x-axis
  # * hidden: whether or not to draw this agent
  # * size: size of agent, in patch coords, default: 1
  # * p: patch at current x,y location
  # * penDown: true if agent pen is drawing
  # * penSize: size in pixels of the pen, default: 1 pixel
  # * breed: the agentset this agent belongs to
  # * sprite: an image of the agent if non null
  color: null  # default color, overrides random color if set
  shape: "default"
  breed: null # set by the agentSet owning this agent
  hidden: false
  size: 1
  penDown: false
  penSize: 1 # pixels
  heading: null
  sprite: null # default sprite, none
  cacheLinks: false
  constructor: -> # called by agentSets create factory, not user
    @x = @y = 0
    @color = u.randomColor() if not @color? # promote color if default not set
    @heading = u.randomFloat(Math.PI*2) if not @heading? 
    @p = ABM.patches.patch @x, @y
    @p.agents.push @ if @p.agents? # ABM.patches.cacheAgentsHere
    @links = [] if @cacheLinks

  # Move agent to different breed agentSet.
  changeBreed: (newBreed) ->
    u.error "changeBreed: not in agentSet" if not @id?
    u.error "changeBreed: breed illegally set" if @hasOwnProperty "breed"
    u.error "changeBreed: breed==newBreed" if @breed is newBreed
    @die(); newBreed.create 1, (a) => a.setXY @x, @y

  # Set agent color to `c` scaled by `s`. Usage: see patch.scaleColor
  scaleColor: (c, s) -> 
    @color = u.clone @color if not @hasOwnProperty "color" # promote color to inst var
    u.scaleColor c, s, @color
  
  # Return a string representation of the agent.
  toString: ->
    "{id:#{@id} xy:#{u.aToFixed [@x,@y]} c:#{@color} h: #{@heading.toFixed 2}}"
  
  # Place the agent at the given x,y (floats) in patch coords
  # using patch topology (isTorus)
  setXY: (x, y) -> # REMIND GC problem, 2 arrays
    [x0, y0] = [@x, @y] if @penDown
    [@x, @y] = ABM.patches.coord x, y
    p = @p
    @p = ABM.patches.patch @x, @y
    if p.agents? and p isnt @p # ABM.patches.cacheAgentsHere 
      u.removeItem p.agents, @
      @p.agents.push @
    if @penDown
      drawing = ABM.drawing
      drawing.strokeStyle = u.colorStr @color
      drawing.lineWidth = ABM.patches.bits2Patches @penSize
      drawing.beginPath()
      drawing.moveTo x0, y0; drawing.lineTo x, y # REMIND: euclidean
      drawing.stroke()
  
  # Place the agent at the given patch/agent location
  moveTo: (a) -> @setXY a.x, a.y
  
  # Move forward (along heading) d units (patch coords),
  # using patch topology (isTorus)
  forward: (d) ->
    @setXY @x + d*Math.cos(@heading), @y + d*Math.sin(@heading)
  
  # Change current heading by rad radians which can be + (left) or - (right)
  rotate: (rad) -> @heading = u.wrap @heading + rad, 0, Math.PI*2 # returns new h
  
  # Draw the agent, instanciating a sprite if required
  draw: (ctx) ->
    shape = ABM.shapes[@shape]
    rad = if shape.rotate then @heading else 0 # radians
    if @sprite? or @breed.useSprites 
      @setSprite() if not @sprite? # lazy evaluation of useSprites
      ABM.shapes.drawSprite ctx, @sprite, @x, @y, @size, rad
    else
      ABM.shapes.draw ctx, shape, @x, @y, @size, rad, @color
  
  # Set an individual agent's sprite, synching its color, shape, size
  setSprite: (sprite = null)->
    if (s=sprite)?
      @sprite = s; @color = s.color; @shape = s.shape; @size = s.size
    else
      @color = u.randomColor if not @color?
      @sprite = ABM.shapes.shapeToSprite @shape, @color, @size
    
  # Draw the agent on the drawing layer, leaving permanent image.
  stamp: -> @draw ABM.drawing
  
  # Return distance in patch coords from me to x,y 
  # using patch topology (isTorus)
  distanceXY: (x,y) ->
    if ABM.patches.isTorus
    then u.torusDistance @x, @y, x, y, ABM.patches.numX, ABM.patches.numY
    else u.distance @x, @y, x, y
  
  # Return distance in patch coords from me to given agent/patch using patch topology.
  distance: (o) -> # o any object w/ x,y, patch or agent
    @distanceXY o.x, o.y
  
  # Return the closest torus topology point of given x,y relative to myself.
  # See util.torusPt.
  torusPtXY: (x, y) ->
    u.torusPt @x, @y, x, y, ABM.patches.numX, ABM.patches.numY

  # Return the closest torus topology point of given agent/patch 
  # relative to myself. See util.torusPt.
  torusPt: (o) ->
    @torusPtXY o.x, o.y

  # Set my heading towards given agent/patch using patch topology.
  face: (o) -> @heading = @towards o

  # Return heading towards x,y using patch topology.
  towardsXY: (x, y) ->
    if ABM.patches.isTorus
    then u.torusRadsToward @x, @y, x, y, ABM.patches.numX, ABM.patches.numY
    else u.radsToward @x, @y, x, y

  # Return heading towards given agent/patch using patch topology.
  towards: (o) -> @towardsXY o.x, o.y
  
  # Remove myself from the model.  Includes removing myself from the agents
  # agentset and removing any links I may have.
  die: ->
    @breed.remove @
    l.die() for l in @myLinks()
    u.removeItem @p.agents, @ if @p.agents?
    null

  # Factory: create num new agents at this agents location. The optional init
  # proc is called on the new agent after inserting in its agentSet.
  hatch: (num = 1, breed = ABM.agents, init = ->) ->
    breed.create num, (a) => # fat arrow so that @ = this agent
      a.setXY @x, @y # for side effects like patches.agentsHere
      a[k] = v for own k, v of @ when k isnt "id"    
      init(a); a # Important: init called after object inserted in agent set

  # Return the members of the given agentset that are within radius distance 
  # from me, and within cone radians of my heading using patch topology
  inCone: (aset, cone, radius, meToo=false) -> 
    aset.inCone @p, @heading, cone, radius, meToo # REMIND: @p vs @?
  
  # Return other end of link from me
  otherEnd: (l) -> if l.end1 is @ then l.end2 else l.end1

  # Return all links linked to me
  myLinks: ->
    @links ? (l for l in ABM.links when (l.end1 is @) or (l.end2 is @))
  
  # Return all agents linked to me.
  linkNeighbors: -> # return all agents linked to me
    @otherEnd l for l in @myLinks()
  
  # Return links where I am the "to" agent in links.create
  myInLinks: ->
    l for l in @myLinks() when l.end2 is @

  # Return other end of myInLinks
  inLinkNeighbors: ->
    l.end1 for l in @myLinks() when l.end2 is @
    
  # Return links where I am the "from" agent in links.create
  myOutLinks: ->
    l for l in @myLinks() when l.end1 is @
  
  # Return other end of myOutinks
  outLinkNeighbors: ->
    l.end2 for l in @myLinks() when l.end1 is @

# Class Agents is a subclass of AgentSet which stores instances of Agent or 
# Breeds, which are subclasses of Agent
class ABM.Agents extends ABM.AgentSet
  # Constructor creates the empty AgentSet instance and installs
  # the agentClass (breed) variable shared by all the Agents in this set.
  constructor: -> # agentClass, name, mainSet
    super # call super with all the args I was called with
    @useSprites = false

  # Have agents cache the links with them as a node.
  # Optimizes Agent a.myLinks method. Call before any agents created.
  cacheLinks: -> ABM.Agent::cacheLinks = true # all agents, not individual breeds

  # Methods to change the default Agent class variables.
  setDefaultColor:  (color) -> @agentClass::color = color
  setDefaultShape:  (shape) -> @agentClass::shape = shape
  setDefaultSize:   (size)  -> @agentClass::size = size
  setDefaultHeading:(heading)-> @agentClass::heading = heading
  setDefaultHidden: (hidden)-> @agentClass::hidden = hidden
  setDefaultSprite: (sprite)-> 
    @setDefaultColor sprite.color; @setDefaultShape sprite.shape; @setDefaultSize sprite.size
    @agentClass::sprite = sprite
  setDefaultPen:   (size, down=false) -> 
    @agentClass::penSize = size
    @agentClass::penDown = down
  
  # Use sprites rather than drawing
  setUseSprites: (@useSprites=true) ->
  
  # Filter to return all instances of this breed.  Note: if used by
  # the mainSet, returns just the agents that are not subclassed breeds.
  in: (array) -> @asSet (o for o in array when o.breed is @)

  # Factory: create num new agents stored in this agentset.The optional init
  # proc is called on the new agent after inserting in its agentSet.
  create: (num, init = ->) -> # returns list too
    ((o) -> init(o); o) @add new @agentClass for i in [1..num] by 1 # too tricky?

  # Remove all agents from set via agent.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list
  
  # Return an agentset of agents within the patch array
  inPatches: (patches) ->
    array = []
    array.push p.agentsHere()... for p in patches # concat measured slower
    if @mainSet? then @in array else @asSet array
  
  # Return an agentset of agents within the patchRect
  inRect: (a, dx, dy, meToo=false) ->
    rect = ABM.patches.patchRect a.p, dx, dy, true
    rect = @inPatches rect
    u.removeItem rect, a if not meToo
    rect
  
  # Return the members of this agentset that are within radius distance
  # from me, and within cone radians of my heading using patch topology
  inCone: (a, heading, cone, radius, meToo=false) -> # heading? .. so p ok?
    as = @inRect a, radius, radius, true
    as.inCone a, heading, cone, radius, meToo
  
  # Return the members of this agentset that are within radius distance
  # from me, using patch topology
  inRadius: (a, radius, meToo=false)->
    as = @inRect a, radius, radius, true
    as.inRadius a, radius, meToo

# ### Link and Links
  
# Class Link connects two agent endpoints for graph modeling.
class ABM.Link
  # Constructor initializes instance variables:
  #
  # * breed: the agentset this link belongs to
  # * end1, end2: two agents being connected
  # * color: defaults to light gray
  # * thickness: thickness in pixels of the link, default 2
  # * hidden: whether or not to draw this link
  breed: null # set by the agentSet owning this link
  color: [130, 130, 130]
  thickness: 2
  hidden: false
  constructor: (@end1, @end2) ->
    if @end1.links?
      @end1.links.push @
      @end2.links.push @
      
  # Draw a line between the two endpoints.  Draws "around" the
  # torus if appropriate using two lines. As with Agent.draw,
  # is called with patch coordinate transform installed.
  draw: (ctx) ->
    ctx.save()
    ctx.strokeStyle = u.colorStr @color
    ctx.lineWidth = ABM.patches.bits2Patches @thickness
    ctx.beginPath()
    if !ABM.patches.isTorus
      ctx.moveTo @end1.x, @end1.y
      ctx.lineTo @end2.x, @end2.y
    else
      pt = @end1.torusPt @end2
      ctx.moveTo @end1.x, @end1.y
      ctx.lineTo pt...
      if pt[0] isnt @end2.x or pt[1] isnt @end2.y
        pt = @end2.torusPt @end1
        ctx.moveTo @end2.x, @end2.y
        ctx.lineTo pt...
    ctx.closePath()
    ctx.stroke()
    ctx.restore()
  
  # Remove this link from the agent set
  die: ->
    @breed.remove @
    u.removeItem @end1.links, @ if @end1.links?
    u.removeItem @end2.links, @ if @end2.links?
    null
  
  # Return the two endpoints of this link
  bothEnds: -> [@end1, @end2]
  
  # Return the distance between the endpoints with the current topology.
  length: -> @end1.distance @end2
  
  # Return the other end of the link, given an endpoint agent.
  # Assumes the given input *is* one of the link endpoint pairs!
  otherEnd: (a) -> if @end1 is a then @end2 else @end1

# Class Links is a subclass of AgentSet which stores instances of Link
# or subclasses of Link

class ABM.Links extends ABM.AgentSet
  # Constructor: super creates the empty AgentSet instance and installs
  # the agentClass (breed) variable shared by all the Links in this set.
  constructor: -> # agentClass, name, mainSet
    super # call super with all the args I was called with

  # Methods to change the default Link class variables.
  setDefaultColor:     (color)      -> @agentClass::color = color
  setDefaultThickness: (thickness)  -> @agentClass::thickness = thickness
  setDefaultHidden:    (hidden)     -> @agentClass::hidden = hidden

  # Factory: Add 1 or more links from the from agent to the to agent(s) which
  # can be a single agent or an array of agents. The optional init
  # proc is called on the new link after inserting in the agentSet.
  create: (from, to, init = ->) -> # returns list too
    to = [to] if not to.length?
    ((o) -> init(o); o) @add new @agentClass from, a for a in to # too tricky?
  
  # Remove all links from set via link.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list

  # Return the subset of this set with the given breed value.
  # breed: (breed) -> @getPropWith "breed", breed

  # Return all the nodes in this agentset, with duplicates
  # included.  If 4 links have the same endpoint, it will
  # appear 4 times.
  allEnds: -> # all link ends, w/ dups
    n = @asSet []
    n.push l.end1, l.end2 for l in @
    n

  # Returns all the nodes in this agentset sorted by ID and with
  # duplicates removed.
  nodes: -> # allEnds without dups
    @allEnds().sortById().uniq()
  
  # Circle Layout: position the agents in the list in an equally
  # spaced circle of the given radius, with the initial agent
  # at the given start angle (default to pi/2 or "up") and in the
  # +1 or -1 direction (counder clockwise or clockwise) 
  # defaulting to -1 (clockwise).
  layoutCircle: (list, radius, startAngle = Math.PI/2, direction = -1) ->
    dTheta = 2*Math.PI/list.length
    for a, i in list
      a.setXY 0, 0
      a.heading = startAngle + direction*dTheta*i
      a.forward radius
    null
      


# Class Model is the control center for our AgentSets: Patches, Agents and Links.
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
  # Create initial animator for the model, specifying default rate (fps) and multiStep (async).
  # If multiStep, run the draw() and step() methods asynchronously by draw() using
  # requestAnimFrame and step() using setTimeout.
  constructor: (@model, @rate=30, @multiStep=false) ->
    @ticks = @draws = 0
    @animHandle = @timerHandle = @intervalHandle = null
    @animStop = true
  # Adjust animator.  This is used by programmer as the default animator will already have
  # been created by the time her model runs.
  setRate: (@rate, @multiStep=false) -> @reset()
  # start/stop model, often used for debugging
  start: ->
    if not @animStop then return # avoid multiple animates
    @reset()
    @animStop = false
    @animate()
  reset: ->
    @startMS = @now()
    @startTick = @ticks
    @startDraw = @draws
  stop: ->
    @animStop = true
    if @animHandle? then cancelAnimFrame @animHandle
    if @timeoutHandle? then clearTimeout @timeoutHandle
    if @intervalHandle? then clearInterval @intervalHandle
    @animHandle = @timerHandle = @intervalHandle = null
  # step/draw the model.  Note ticks/draws counters separate due to async.
  step: -> @ticks++; @model.step()
  draw: -> @draws++; @model.draw()
  # step and draw the model once, mainly debugging
  once: -> @step(); @draw()
  # Get current time, with high resolution timer if available
  now: -> (performance ? Date).now()
  # Time in ms since starting animator
  ms: -> @now()-@startMS
  # Get the number of ticks/draws per second.  They will differ if async
  ticksPerSec: -> if (elapsed = @ticks-@startTick) is 0 then 0 else Math.round elapsed*1000/@ms()
  drawsPerSec: -> if (elapsed = @draws-@startDraw) is 0 then 0 else Math.round elapsed*1000/@ms()
  # Return a status string for debugging and logging performance
  toString: -> "ticks: #{@ticks}, draws: #{@draws}, rate: #{@rate} #{@ticksPerSec()}/#{@drawsPerSec()}"
  # Animation via setTimeout and requestAnimFrame
  animateSteps: =>
    @step()
    @timeoutHandle = setTimeout @animateSteps, 10 unless @animStop
  animateDraws: =>
    if @drawsPerSec() <= @rate
      @step() if not @multiStep
      @draw()
    @animHandle = requestAnimFrame @animateDraws unless @animStop
  animate: ->
    if @multiStep
      @animateSteps()
    @animateDraws()

# ### Class Model

class ABM.Model  
  
  # Class variable for layers parameters. 
  # Can be added to by programmer to modify/create layers, **before** starting your own model.
  # Example:
  # 
  #     v.z++ for k,v of ABM.Model::contextsInit # increase each z value by one
  contextsInit: {
    patches:   {z:0, ctx:"2d"}
    drawing:   {z:1, ctx:"2d"}
    links:     {z:2, ctx:"2d"}
    agents:    {z:3, ctx:"2d"}
    spotlight: {z:4, ctx:"2d"}
  }
  # Constructor: 
  #
  # * create agentsets, install them and ourselves in ABM global namespace
  # * create layers/contexts, install drawing layer in ABM global namespace
  # * setup patch coord transforms for each layer context
  # * intialize various instance variables
  # * call `setup` abstract method
  constructor: (
    div, size, minX, maxX, minY, maxY,
    isTorus=true, hasNeighbors=true
  ) ->
    ABM.model = @
    ABM.world = @world = {div, size, minX, maxX, minY, maxY, isTorus, hasNeighbors}
    @contexts = ABM.contexts = {}
    
    # * Create 2D canvas contexts layered on top of each other.
    # * Initialize a patch coord transform for each layer.
    # 
    # Note: this is permanent .. there isn't the usual ctx.restore().
    # To use the original canvas 2D transform temporarily:
    #
    #     u.setIdentity ctx
    #       <draw in native coord system>
    #     ctx.restore() # restore patch coord system
    
    for own k,v of @contextsInit
      @contexts[k] = ctx =
        u.createLayer div, size*(maxX-minX+1), size*(maxY-minY+1), v.z, v.ctx
      ctx.save()
      ctx.scale size, -size
      ctx.translate -(minX-.5), -(maxY+.5)
      ctx.agentSetName = k # Set a variable in each context with its name

    # Initialize agentsets.
    @patches = ABM.patches = new ABM.Patches ABM.Patch, "patches"
    @agents = ABM.agents = new ABM.Agents ABM.Agent, "agents"
    @links = ABM.links = new ABM.Links ABM.Link, "links"
    # One of the layers is used for drawing only, not an agentset:
    @drawing = ABM.drawing = @contexts.drawing
    # Setup spotlight layer, also not an agentset:
    @contexts.spotlight.globalCompositeOperation = "xor"

    # Initialize animator to default: 30fps, not async
    @anim = new ABM.Animator(@)
    # Set drawing controls.  Default to drawing each agentset.
    # Optimization: If any of these is set to false, the associated
    # agentset is drawn only once, remaining static after that.
    @refreshLinks = @refreshAgents = @refreshPatches = true
    
    # Call the models setup function. Set the list of global variables to
    # the new variables created by setup(). Do not include agentsets, they
    # are available in the ABM global.
    beginVars = (k for own k,v of @ when not (v.agentClass? or u.isFunction v))
    @setup()
    endVars = (k for own k,v of @ when not (v.agentClass? or u.isFunction v))
    ABM.globals = @globals = (v for v in endVars when not u.contains beginVars, v)
    console.log "globals", @globals
    

#### Optimizations:
  
  # Modelers "tune" their model by adjusting flags:<br>
  # `@refreshLinks, @refreshAgents, @refreshPatches`<br>
  # and by the following methods:

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support imageSmoothingEnabled or equivalent.
  setFastPatches: -> @patches.usePixels()
    
  # Have patches cache the agents currently on them.
  # Optimizes Patch p.agentsHere method
  setCacheAgentsHere: -> @patches.cacheAgentsHere()
  
  # Have agents cache the links with them as a node.
  # Optimizes Agent a.myLinks method
  setCacheMyLinks: -> @agents.cacheLinks()
  
  # Have patches cache the given patchRect.
  # Optimizes patchRect, inRadius and inCone
  setCachePatchRects: (radius, meToo=false) -> @patches.cacheRect radius, meToo

#### Text Utilities:
  
  # Return context name for agentset via naming convention: Links->links etc.
  agentSetCtxName: (aset) ->
    aset = aset.mainSet if aset.mainSet? # breeds->mainSet
    aset.constructor.name.toLowerCase()
  # Set the text parameters for an agentset's context.  See ABM.util<br>
  # `agentSetName` can be a key in @contexts or an agentset itself
  setTextParams: (agentSetName, domFont, align="center", baseline="middle") ->
    agentSetName = @agentSetCtxName(agentSetName) if typeof agentSetName isnt "string"
    u.error "setTextParams: #{@agentSetName} not fount." if not @contexts[agentSetName]?
    u.ctxTextParams @contexts[agentSetName], domFont, align, baseline
  setLabelParams: (agentSetName, color, xy) ->
    agentSetName = @agentSetCtxName(agentSetName) if typeof agentSetName isnt "string"
    u.error "setLabelParams: #{@agentSetName} not fount." if not @contexts[agentSetName]?
    u.ctxLabelParams @contexts[agentSetName], color, xy
  
#### User Model Creation
# A user's model is made by subclassing Model and over-riding these
# two abstract methods. `super` need not be called.
  
  # Initialize your model here
  setup: -> # called at the end of model creation
  # Update/step your model here
  step: -> # called each step of the animation

# Convenience access to animator:

  # Start/stop the animation
  start: -> @anim.start()
  stop: -> @anim.stop()
  # Animate once by `step(); draw()`. For debugging from console.
  once: -> @anim.once() 

#### Animation.
  
# Call the agentset draw methods if either the first draw call or
# their "refresh" flags are set.  The latter are simple optimizations
# to avoid redrawing the same static scene. Called by animator.
  draw: ->
    @patches.draw @contexts.patches  if @refreshPatches or @anim.draws is 1
    @links.draw   @contexts.links    if @refreshLinks   or @anim.draws is 1
    @agents.draw  @contexts.agents   if @refreshAgents  or @anim.draws is 1
    @drawSpotlight @spotlightAgent, @contexts.spotlight  if @spotlightAgent?

# Creates a spotlight effect on an agent, so we can follow it throughout the model.
# Use:
#
#     @setSpotliight breed.oneOf()
#
# to draw one of a random breed. Remove spotlight by passing `null`
  setSpotlight: (@spotlightAgent) ->
    u.clearCtx @contexts.spotlight if not @spotlightAgent?

  drawSpotlight: (agent, ctx) ->
    u.clearCtx ctx
    u.fillCtx ctx, [0,0,0,0.6]
    ctx.beginPath()
    ctx.arc agent.x, agent.y, 3, 0, 2*Math.PI, false
    ctx.fill()


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
# These agentset's `create` method create subclasses of Agent/Link.
# Use of <breed>.setDefault methods work as for agents/links, creating default
# values for the breed set:
#
#     @embers.setDefaultColor [255,0,0]
#
# ..will set the default color for just the embers.
  
  createBreeds: (s, agentClass, breedSet) ->
    breeds = []; breeds.classes = {}; breeds.sets = {}
    for b in s.split(" ")
      c = class Breed extends agentClass
      @[b] = # add @<breed> to local scope
        new breedSet c, b, agentClass::breed # create subset agentSet
      breeds.push @[b]
      breeds.sets[b] = @[b]
      breeds.classes["#{b}Class"] = c
    breeds
  patchBreeds: (s) -> ABM.patchBreeds = @createBreeds s, ABM.Patch, ABM.Patches
  agentBreeds: (s) -> ABM.agentBreeds = @createBreeds s, ABM.Agent, ABM.Agents
  linkBreeds:  (s) -> ABM.linkBreeds  = @createBreeds s, ABM.Link,  ABM.Links
  
  # Utility for models to create agentsets from arrays.  Ex:
  #
  #     even = @asSet (a for a in @agents when a.id % 2 is 0)
  #     even.shuffle().getProp("id") # [6, 0, 4, 2, 8]
  asSet: (a) -> # turns an array into an agent set
    ABM.AgentSet.asSet(a)

  # A simple debug aid which places short names in the global name space.
  # Note we avoid using the actual name, such as "patches" because this
  # can cause our modules to mistakenly depend on a global name.
  # See [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension too.
  setRootVars: ->
    root.ps  = @patches
    root.p0  = @patches[0]
    root.as  = @agents
    root.a0  = @agents[0]
    root.ls  = @links
    root.l0  = @links[0]
    root.dr  = @drawing
    root.u   = ABM.util
    root.sh  = ABM.shapes
    root.app = @
    root.cx  = @contexts
    root.ab  = ABM.agentBreeds
    root.lb  = ABM.linkBreeds
    root.an  = @anim
    root.wd  = @world
    root.gl  = @globals
    root.root= root
    null
  
