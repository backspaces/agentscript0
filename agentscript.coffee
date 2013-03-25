# This documentation uses Jeremy Ashkenas's
# [docco](http://jashkenas.github.com/docco/) which allows
# [markdown](http://daringfireball.net/projects/markdown/syntax).

# Create the namespace **ABM** for our project.
# Note here `this` or `@` == window due to coffeescript wrapper call.
# Thus @ABM is placed in the global scope.
@ABM={}
# Keep copy of global object in ABM
ABM.root = @

# Global shim for not-yet-standard requestAnimationFrame
do -> 
  @requestAnimFrame = @requestAnimationFrame or null
  for vendor in ['ms', 'moz', 'webkit', 'o']
    @requestAnimFrame or= @[vendor+'RequestAnimationFrame']
  @requestAnimFrame or=
    (callback) -> window.setTimeout(callback, 1000 / 60)

# Shim for `Array.indexOf` if not implemented.
# Use [es5-shim](https://github.com/kriskowal/es5-shim) if additional shims needed.
Array::indexOf or= (item) -> # shim for IE8
  for x, i in this
    return i if x is item
  return -1

# **ABM.util** contains the general utilities for the project. Note that within
# **util** `@` referrs to ABM.util, *not* the global name space as above.
ABM.util =

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

  # Return a random RGB or gray color. Array passed to minimize garbage collection
  randomColor: (color = []) -> 
    color[i] = @randomInt(256) for i in [0..2]
    color 
  randomGray: (color = [], min = 64, max = 192) -> 
    r=@randomInt2 min,max
    color[i] = r for i in [0..2]
    color
  # Return new color by scaling each value of an RGB array.
  # Note [r,g,b] must be ints
  scaleColor: (max, s, color = []) -> 
    color[i] = @clamp(Math.round(c*s),0,255) for c, i in max
    color
  # Return HTML color as used by canvas element.  Can include Alpha
  colorStr: (c) -> if c.length is 3 then "rgb(#{c})" else "rgba(#{c})"
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
  nOf: (array, n) -> # REMIND: shuffle then first n may be better
    @error "nOf: n > length" if n > array.length
    r = []; while r.length < n
      o = @oneOf(array)
      r.push o unless o in r
    r
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

  # Useful for JS users: max/min of array, push array.  Not used in our CS code
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
    
# ### Canvas/Context Operations
  
  # Return a "layer" 2D/3D rendering context within the specified HTML `<div>`,
  # with the given width/height positioned absolutely at top/left within the div,
  # and with the z-index of z.
  #
  # The z level gives us the capability of buildng a "stack" of coordinated canvases.
  createLayer: (div, width, height, z, ctx = "2d") -> # a canvas ctx object
    can = document.createElement 'canvas'
    can.setAttribute 'style', "position:absolute;top:0;left:0;z-index:#{z}"
    can.width = width; can.height = height
    can.ctx = # http://goo.gl/atMRr can't get both 2d/3d contexts, only one allowed
      if ctx is "2d" then can.getContext "2d" 
      else can.getContext("webgl") or can.getContext("experimental-webgl")
    document.getElementById(div).appendChild(can)
    can.ctx
  # Clear the 2D/3D layer to be transparent. Note this [discussion](http://goo.gl/qekXS).
  clearCtx: (ctx) ->
    if ctx.save? # test for 2D ctx
      ctx.save()
      ctx.setTransform 1, 0, 0, 1, 0, 0
      ctx.clearRect 0, 0, ctx.canvas.width, ctx.canvas.height
      ctx.restore()
    else # 3D
      ctx.clearColor 0, 0, 0, 0 # transparent!
      ctx.clear ctx.COLOR_BUFFER_BIT | ctx.DEPTH_BUFFER_BIT
  # Fill the 2D/3D layer with the given color
  fillCtx: (ctx, color) ->
    if ctx.fillStyle? # test for 2D ctx
      ctx.save()
      ctx.setTransform 1, 0, 0, 1, 0, 0
      ctx.fillStyle = @colorStr(color)
      ctx.fillRect 0, 0, ctx.canvas.width, ctx.canvas.height
      ctx.restore()
      console.log "fillCtx: 2d"
    else # 3D
      console.log "fillCtx: 2d"
      ctx.clearColor color..., 1 # alpha = 1 unless color is rgba
      ctx.clear ctx.COLOR_BUFFER_BIT | ctx.DEPTH_BUFFER_BIT
  # 2D: Draw string of the given color at the xy location.
  # Note that this will follow the existing transform.
  ctxDrawText: (ctx, string, xy, color = [0,0,0]) -> 
    ctx.fillStyle = @colorStr color
    ctx.fillText(string, xy[0], xy[1])
  # 2D: Set the canvas text align and baseline drawing parameters
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

  # Import an image, executing function f on completion
  importImage: (imageSrc, f=(img)->) ->
    img = new Image()
    img.onload = -> f(img)
    img.src = imageSrc
    img
  # Convert an image to a context
  imageToCtx: (image) ->
    canvas = document.createElement "canvas"
    canvas.width = image.width
    canvas.height = image.height
    ctx = canvas.getContext "2d"
    ctx.drawImage image, 0, 0
    ctx # note: ctx.canvas gives the canvas created above.
  # Convert a context to an image
  ctxToImage: (ctx) ->
    image = new Image()
    image.src = ctx.canvas.toDataURL "image/png"
    image
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
    
    
    
  
# A *very* simple shapes module for drawing
# [NetLogo-like](http://ccl.northwestern.edu/netlogo/docs/) agents.
u = ABM.util # alias for util module

ABM.shapes = s = # s alias below for ABM.shapes
  # Each shape is a named object with two members: 
  # a boolean "rotate" and a drawing procedure.
  # The shape is used in the following context with a color set
  # and a transform such that the shape should be drawn in a -.5 to .5 square
  #
  #     ctx.save()
  #     ctx.fillStyle = u.colorStr @color
  #     ctx.translate @x, @y; ctx.scale @size, @size;
  #     ctx.rotate @heading if shape.rotate
  #     ctx.beginPath()
  #     shape.draw(ctx)
  #     ctx.closePath()
  #     ctx.fill()
  #     ctx.restore()
  #
  # The list of current shapes, via `ABM.shapes.names()` below, is:
  #
  #     ["default", "triangle", "arrow", "bug", "pyramid", 
  #      "circle", "square", "pentagon", "ring", "person"]
  #
  
  default:
    rotate: true
    draw: (c) -> s.poly c, [[.5,0],[-.5,-.5],[-.25,0],[-.5,.5]]
  triangle:
    rotate: true
    draw: (c) -> s.poly c, [[.5,0],[-.5,-.4],[-.5,.4]]
  arrow:
    rotate: true
    draw: (c) -> s.poly c, [[.5,0],[0,.5],[0,.2],[-.5,.2],[-.5,-.2],[0,-.2],[0,-.5]]
  bug:
    rotate: true
    draw: (c) ->
      PI = Math.PI
      c.strokeStyle = c.fillStyle; c.lineWidth = .05
      c.moveTo .4,.225; c.lineTo .2,0; c.lineTo .4, -.225
      c.stroke()
      c.beginPath()
      c.arc .12,0,.13,0,2*PI; c.arc -.05,0,.13,0,2*PI; c.arc -.27,0,.2,0,2*PI
  pyramid:
    rotate: false
    draw: (c) -> s.poly c, [[0,.5],[-.433,-.25],[.433,-.25]]
  circle:
    rotate: false
    draw: (c) -> c.arc 0,0,.5,0,2*Math.PI
  square:
    rotate: false
    draw: (c) -> c.fillRect -.5,-.5,1,1
  pentagon:
    rotate: false
    draw: (c) -> s.poly c, [[0,.45],[-.45,.1],[-.3,-.45],[.3,-.45],[.45,.1]]
  ring:
    rotate: false
    draw: (c) ->
      c.arc 0,0,.5,0,2*Math.PI,true;c.closePath();c.arc 0,0,.3,0,2*Math.PI,false
  person:
    rotate: false
    draw: (c) ->
      s.poly c, [  [.15,.2],[.3,0],[.125,-.1],[.125,.05],
      [.1,-.15],[.25,-.5],[.05,-.5],[0,-.25],
      [-.05,-.5],[-.25,-.5],[-.1,-.15],[-.125,.05],
      [-.125,-.1],[-.3,0],[-.15,.2]  ]
      c.closePath(); c.arc 0,.35,.15,0,2*Math.PI
  # Return a list of the available shapes, see above.
  names: ->
    (name for own name, val of @ when !ABM.util.isFunction val)
  # Add your own shape. Will be included in names list.  Usage:
  #
  #     ABM.shapes.add "test", true, (c) -> # bowtie/hourglass
  #       ABM.shapes.poly c, [[-.5,-.5],[.5,.5],[-.5,.5],[.5,-.5]]
  add: (name, rotate, draw) -> @[name] = {rotate,draw}
  # A simple polygon utility:  c is the 2D context, and a is an array of 2D points.
  # c.closePath() and c.fill() will be called by the calling agent, see initial 
  # discription of drawing context.  It is used in adding a new shape above.
  poly: (c, a) ->
    for p, i in a 
      if i is 0 then c.moveTo p[0], p[1] else c.lineTo p[0], p[1]
    null
  
  # Create an image ctx of a shape by drawing it into a small canvas.
  # Used to implement agent sprites.
  shapeToCtx: (name, color, scale) ->
    shape = @[name]
    can = document.createElement 'canvas'
    can.width = can.height = scale
    ctx = can.getContext "2d"
    ctx.scale scale, scale
    ctx.translate .5, .5
    ctx.fillStyle = u.colorStr color
    ctx.beginPath()
    shape.draw ctx
    ctx.closePath()
    ctx.fill()
    ctx
    

# **AgentSet** is a subclass of `Array` and is the base class for
# `Patches`, `Agents`, and `Links`.  Its subclasses are also a factory
# for agent classes (`Patch`, `Agent`, `Link`). `AgentSet` keeps track of all
# the created agent instances.  It also provides, much like the **ABM.util**
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
# but thus far we've resolved all related problems, mainly by using the
# ABM.util array functions rather than "super".
#
# Because we are an array subset, @[i] below (this[i]), gets the i'th agentset element.

# The usual alias for **ABM.util**. These are equivalent:
#
#      ABM.util.clearCtx(ctx)
#      u.clearCtx(ctx)
u = ABM.util

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
    # if a.prototype?
    # then a.prototype = setType.prototype
    # else a.__proto__ = setType.prototype
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
  constructor: ->
    super()
    @ID = 0

  # Add an agent to the list.  Only used by agentset factory methods. Adds
  # the `id` and `hidden` properties to all agents. Increment `ID`.
  # Returns the object for chaining. The set will be sorted by `id`.
  #
  # By "agent" we mean an instance of `Patch`, `Agent` and `Link`.
  add: (o) ->
    o.id = @ID++
    # o.hidden = false
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
    if o is @last()
      @.length--
    else
      @splice i, 1 if (i = @indexOfID o.id) isnt -1
      u.error "remove: indexOfID not in list" if i is -1
    @

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
  #     AS.getWithProp "x", 1
  #     [{id:4,x:1,y:3},{id:5,x:1,y:1}]
  getWithProp: (prop, value) -> @asSet (o for o in @ when o[prop] is value)

  # Set the property of the agents to a given value
  #
  #     # increment x for agents with x=1
  #     AS1 = ABM.AgentSet.asSet AS.getWithProp("x",1)
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
  #     AS.getWithProp("x", 99).any() #false
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
class XY
  constructor: (@x,@y) ->
  toString: -> "{id:#{@id},x:#{@x},y:#{@y}}"
@AS = new ABM.AgentSet # @ => global name space
# The result of 
#
#     AS.add new XY(u.randomInt(10), u.randomInt(10)) for i in [1..5]
# random run, captured so we can reuse.
AS.add new XY(pt...) for pt in [[0,1],[8,0],[6,4],[1,3],[1,1]]
# There are three agentsets and their corresponding 
# agents: Patches/Patch, Agents/Agent, and Links/Link.

# The usual alias for **ABM.util**.
u = ABM.util

# ### Patch and Patches

# Class Patch instances represent a rectangle on a grid with::
#
# * id: installed by Patches agentset
# * x,y: the x,y position within the grid
# * color: the color of the patch as an RGBA array, A optional.
# * label: text for the patch
# * n/n4: adjacent neighbors: n: 8 patches, n4: N,E,S,W patches.
class ABM.Patch
  # Class variable defaults, "promoted" to instance variables if needed
  # when unique per instance rather than shared.
  # This approach yields considerable space effeciency when appropriate.
  
  # Not all patches need their neighbor patches, thus we use a default
  # of none.  n and n4 are promoted by the ABM.Patches agent set 
  # constructor if the constructor variable "neighbors" is true,
  # the default. This is only important in very large patch sets
  # and should be handled with care!
  n: null
  n4: null
  cachedRects: null
  # Default color starts as black, can be set to different default value
  # by setDefault methods in ABM.Patches
  color: [0,0,0]
  # Default patch is visible but can be changed to true if
  # appropriate by setDefault methods
  hidden: false
  # new Patch: set x,y. Neighbors set by Patches constructor if needed.
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
    if @label?
      [x,y] = ctx.labelXY
      ctx.save()
      ctx.translate @x, @y # bug: fonts don't scale for size < 1
      ctx.scale 1/ABM.patches.size, -1/ABM.patches.size
      u.ctxDrawText ctx, @label, [x,y], ctx.labelColor
      ctx.restore()
  
  # Return an array of the agents on this patch.
  # See model.setCacheAgentsHere for optimization.
  agentsHere: ->
    @agents ? (a for a in ABM.agents when a.p is @)
  
  # Returns true if this patch is on the edge of the grid.
  isOnEdge: ->
    @x is ABM.patches.minX or @x is ABM.patches.maxX or \
    @y is ABM.patches.minY or @y is ABM.patches.maxY
  
  # Factory: Create num new agents on this patch.
  # The optional init proc is called on each of the newly created agents.<br>
  # NOTE: init must be applied after object inserted in agent set
  sprout: (num = 1, init = ->) ->
    ABM.agents.create num, (a) => # fat arrow so that @ = this patch
      a.setXY @x, @y; init(a); a
  

# Class Patches is a singleton 2D matrix of Patch instances, each patch 
# representing a 1x1 square in patch coordinates (via 2D coord transforms).
#
# * size: pixel h/w of each patch.
# * minX/maxX: min/max x coord, each patch being a unit square.
# * minY/maxY: min/max y coord.
# * numX/numY: total patches in x/y direction, width/height of grid.
# * isTorus: topology of patches, see **ABM.util**.
class ABM.Patches extends ABM.AgentSet
  # Constructor: set variables, fill patch neighbor variables, n & n4.
  constructor: (
    @size, @minX, @maxX, @minY, @maxY, @isTorus=true, neighbors=true
  ) ->
    super()
    @numX = @maxX-@minX+1
    @numY = @maxY-@minY+1
    for y in [minY..maxY] by 1
      for x in [minX..maxX] by 1
        @add new ABM.Patch x, y
    @setNeighbors() if neighbors
    @setPixels() 
    @drawWithPixels = @size is 1 #false
  
  # Install neighborhoods in patches
  setNeighbors: -> 
    for p in @
      p.n =  @patchRect p, 1, 1 # p.n =  p.patchRect 1, 1
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
  
  # If using scaled pixels, use pixel manipulation below, or use default.
  draw: (ctx) ->
    if @drawWithPixels then @drawScaledPixels ctx else super ctx
  
  # Set the default color for new Patch instances.
  # Note coffeescript :: which refers to the Patch prototype.
  # This is the usual way to modify class variables.
  setDefaultColor: (color) -> ABM.Patch::color = color

# #### Patch grid coord system utilities:

  # Return the patch at matrix position x,y where 
  # x & y are both valid integer patch coordinates.
  patchXY: (x,y) -> @[x-@minX + @numX*(y-@minY)]
  
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
    if p.pRect? and p.pRect.radius is dx and p.pRect.radius is dy
      return p.pRect
    rect = []; # REMIND: could optimize w/ a loop for the all inside patches case
    for y in [p.y-dy..p.y+dy] by 1 # by 1: perf: avoid bidir JS for loop
      for x in [p.x-dx..p.x+dx] by 1
        if @isTorus or (@minX<=x<=@maxX and @minY<=y<=@maxY)
          if @isTorus
            x+=@numX if x<@minX; x-=@numX if x>@maxX
            y+=@numY if y<@minY; y-=@numY if y>@maxY
          pnext = @patchXY x, y # much faster than coord()
          if not pnext?
            u.error "patchRect: x,y out of bounds, see console.log"
            console.log "  x #{x} y #{y} p.x #{p.x} p.y #{p.y} dx #{dx} dy #{dy} minX #{@minX} minY #{@minY}"
          rect.push pnext if (meToo or p isnt pnext)
    @asSet rect

  # Draws, or "imports" an image URL into the drawing layer.
  # The image is scaled to fit the drawing layer.
  #
  # This is an async load, see this
  # [new Image()](http://javascript.mfields.org/2011/creating-an-image-in-javascript/)
  # tutorial.  We draw the image into the drawing layer as
  # soon as the onload callback executes.
  # The "fat arrow" insures the callback executes within the importDrawing context.
  importDrawing: (imageSrc) ->
    u.importImage imageSrc, (img) ->
      ctx = ABM.drawing
      ctx.save() # revert to native 2D transform
      ctx.setTransform 1, 0, 0, 1, 0, 0
      ctx.drawImage img, 0, 0, ctx.canvas.width, ctx.canvas.height
      ctx.restore() # restore patch transform
  
  # Utility function for pixel manipulation.  Given a patch, returns the 
  # native canvas index i into the pixel data.
  pixelIndex: (p) ->
    ( (p.x-@minX) + (@maxY-p.y)*@numX )*4
    
  # Draws, or "imports" an image URL into the patches as their color property.
  # The drawing is scaled to the number of x,y patches, thus one pixel
  # per patch.  The colors are then transferred to the patches.
  importColors: (imageSrc) ->
    u.importImage imageSrc, (img) => # fat arrow, this context
      if img.width isnt @numX or img.height isnt @numY
        @pixelsCtx.drawImage img, 0, 0, @numX, @numY
      else
        @pixelsCtx.drawImage img, 0, 0
      data = @pixelsCtx.getImageData(0, 0, @numX, @numY).data
      for p in @
        i = @pixelIndex p
        p.color = (data[i+j] for j in [0..2])
      null # avoid CS return of array
  
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
    minX=@minX; numX=@numX; maxY=@maxY
    for p in @
      i = ( (p.x-minX) + (maxY-p.y)*numX )*4
      c = p.color
      data[i+j] = c[j] for j in [0..2] 
      data[i+3] = if c.length is 4 then c[3] else 255
      
    @pixelsCtx.putImageData(@pixelsImageData, 0, 0)
    return if @size is 1
    ctx.drawImage @pixelsCtx.canvas, 0, 0, ctx.canvas.width, ctx.canvas.height
  # The 32-bit version of drawScaledPixels, with both little and big endian hardware.
  drawScaledPixels32: (ctx) ->
    data = @pixelsData32
    minX=@minX; numX=@numX; maxY=@maxY
    for p in @
      i = (p.x-minX) + (maxY-p.y)*numX
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
  diffuse: (v, rate, c=null) -> # variable name, diffusion rate, max color (optional)
    # zero temp variable if not yet set
    if not @[0]._diffuseNext?
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

# ### Agent & Agents

# Class Agent instances represent the dynamic, behavioral element of ABM.
class ABM.Agent
  # Constructor & Class Variables:
  #
  # * x,y: position on the patch grid, in patch coordinates, default: 0,0
  # * color: the color of the agent, default: ABM.util.randomColor
  # * shape: the ABM.shape name of the agent, default: ABM.agents.defaultShape
  # * heading: direction of the agent, in radians, from x-axis
  # * size: size of agent, in patch coords, default: 1
  # * p: patch at current x,y location
  # * penDown: true if agent pen is drawing
  # * penSize: size in patch coords of the pen, default: 1 pixel
  # * breed: string represented the type of agent. Ex: wolf, rabbit.

  # Default class variables, promoted to instances when needed
  color: null  # default color, overrides random color if set
  shape: "default"
  breed: "default"
  hidden: false
  size: 1
  penDown: false
  penSize: 1
  heading: null
  sprite: null
  links: null
  constructor: ->
    @x = @y = 0
    @color = u.randomColor() if not @color? # promote color if default not set
    @heading = u.randomFloat(Math.PI*2) if not @heading? 
    @p = ABM.patches.patch @x, @y
    @p.agents.push @ if @p.agents? # ABM.patches.cacheAgentsHere
    @links = [] if ABM.links.cacheAgentLinks

  #  Set agent color to `c` scaled by `s`. Usage: see patch.scaleColor
  scaleColor: (c, s) -> 
    @color = u.clone @color if not @.hasOwnProperty("color")
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
  
  # Place the agent at the given patch/agent location,
  # using patch topology (isTorus)
  moveTo: (a) -> @setXY a.x, a.y
  
  # Move forward (along heading) d units (patch coords),
  # using patch topology (isTorus)
  forward: (d) ->
    @setXY @x + d*Math.cos(@heading), @y + d*Math.sin(@heading)
  
  # Change current heading by rad radians which can be + (left) or - (right)
  rotate: (rad) -> @heading = u.wrap @heading + rad, 0, Math.PI*2 # returns new h
  
  # Draw the agent: Around ctx save/restore pair
  #
  # * Get the agent shape object: procedure & rotate flag
  # * Set agent transform, assuming patch coordinate transform in place
  # * Rotate shape by heading if rotate flag set on shape
  # * Call the shape draw with our ctx, closing the path
  # * Fill with agent color
  draw: (ctx) ->
    shape = ABM.shapes[@shape]
    ctx.save()
    if @sprite?
      ctx.translate @x, @y # see tutorial: http://goo.gl/VUlhY
      ctx.rotate @heading if shape.rotate
      ctx.scale 1/ABM.patches.size, -1/ABM.patches.size # convert back to pixel scale
      ctx.drawImage @sprite.canvas, -@sprite.canvas.width/2, -@sprite.canvas.height/2
    else
      ctx.translate @x, @y
      ctx.scale @size, @size
      ctx.rotate @heading if shape.rotate
      @colorStr = u.colorStr @color if ABM.agents.staticColors and not @colorStr?
      ctx.fillStyle = @colorStr or u.colorStr @color
      ctx.beginPath()
      shape.draw ctx
      ctx.closePath()
      ctx.fill()
    ctx.restore()
  
  # Draw the agent on the drawing layer, leaving perminant image.
  stamp: -> @draw ABM.drawing
  
  # Return distance in patch coords from me to x,y 
  # using patch topology (isTorus)
  distanceXY: (x,y) ->
    if ABM.patches.isTorus
    then u.torusDistance @x, @y, x, y, ABM.patches.numX, ABM.patches.numY
    else u.distance @x, @y, x, y
  
  # Return distance in patch coords from me to given agent/patch
  # using patch topology (isTorus)
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

  # Set my heading towards given agent/patch using patch topology (isTorus)
  face: (o) -> @heading = @towards o

  # Return heading towards x,y using patch topology (isTorus)
  towardsXY: (x, y) ->
    if ABM.patches.isTorus
    then u.torusRadsToward @x, @y, x, y, ABM.patches.numX, ABM.patches.numY
    else u.radsToward @x, @y, x, y

  # Return heading towards given agent/patch using patch topology (isTorus)
  towards: (o) -> @towardsXY o.x, o.y
  
  # Remove myself from the model.  Includes removing myself from the agents
  # agentset and removing any links I may have.
  die: ->
    ABM.agents.remove @
    l.die() for l in @myLinks()
    u.removeItem @p.agents, @ if @p.agents?
    null

  # Factory: create num new agents here
  # The optional init proc is called on each of the newly created agents.<br>
  # NOTE: init must be applied after object inserted in agent set
  hatch: (num = 1, init = ->) ->
    ABM.agents.create num, (a) => # fat arrow so that @ = this agent
      a.setXY @x, @y # for side effects like patches.agentsHere
      a[k] = v for own k, v of @ when k isnt "id"    
      init(a); a

  # Return the members of the given agentset that are within radius distance 
  # from me, and within cone radians of my heading using patch topology (isTorus)
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

# Class Agents is a subclass of AgentSet which stores instances of Agent.

class ABM.Agents extends ABM.AgentSet
  # Constructor creates the AgentSet instance and installs
  # variables shared by all the Agents.  This can be used to
  # minimize Agent variables by using a "default".  Here for example
  # we provide a default shape for agents.
  constructor: ->
    super()
    @staticColors = false
    @useSprites = false

  # Methods to change the default Agent class variables.
  setDefaultColor:  (color) -> ABM.Agent::color = color#; @setDefaultSprite()
  setDefaultShape:  (shape) -> ABM.Agent::shape = shape#; @setDefaultSprite()
  setDefaultSize:   (size)  -> ABM.Agent::size = size#; @setDefaultSprite()
  setDefaultHeading:(heading)-> ABM.Agent::heading = heading
  setDefaultHidden: (hidden)-> ABM.Agent::hidden = hidden
  setDefaultSprite: -> 
    if ABM.Agent::color?
      ABM.Agent::sprite = ABM.shapes.shapeToCtx \
        ABM.Agent::shape, ABM.Agent::color, ABM.Agent::size*ABM.patches.size
  setDefaultPen:   (size, down=false) -> 
    ABM.Agent::penSize = size
    ABM.Agent::penDown = down
  
  # Performance: tell draw to reuse existing color string
  setStaticColors: (@staticColors) ->
  # Use sprites rather than drawing
  setUseSprites: (@useSprites) ->      

  # Factory: create num new agents stored in this agentset.
  # The optional init proc is called on each of the newly created agents.<br>
  # NOTE: init must be applied after object inserted in agent set
  create: (num, init = ->) -> # returns list too
    ((o) -> init(o); o) @add new ABM.Agent for i in [1..num] by 1 # too tricky?

  # Remove all agents from set via agent.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list

  # Return the subset of this set with the given breed value.
  breed: (breed) -> @getWithProp "breed", breed
  
  # Return an agentset of agents within the patch array
  agentsInPatches: (patches) ->
    array = []
    array.push p.agentsHere()... for p in patches # concat measured slower
    @asSet array
  
  # Return an agentset of agents within the patchRect
  agentRect: (a, dx, dy, meToo=false) ->
    rect = ABM.patches.patchRect a.p, dx, dy, true
    rect = @agentsInPatches rect
    u.removeItem rect, a if not meToo
    rect
  
  # Return the members of this agentset that are within radius distance
  # from me, and within cone radians of my heading using patch topology (isTorus)<br>
  # See agentset.inCone
  inCone: (a, heading, cone, radius, meToo=false) -> # heading? .. so p ok?
    as = @agentRect a, radius, radius, true
    as.inCone a, heading, cone, radius, meToo
  
  # Return the members of this agentset that are with radius distance
  # from me, using patch topology (isTorus)<br>
  # See agentset.inRadius
  inRadius: (a, radius, meToo=false)->
    as = @agentRect a, radius, radius, true
    as.inRadius a, radius, meToo

# ### Link and Links

# Class Link connects two agent endpoints for graph modeling.
class ABM.Link
  # Constructor initializes instance variables:
  #
  # * end1, end2: two agents being connected
  # * color: defaults to light gray
  # * thickness: the thickness of the line connecting the ends<br>
  #   Defaults to 2 pixels in patch coordinates.
  breed: "default"
  color: [130, 130, 130]
  thickness: 2
  hidden: false
  constructor: (@end1, @end2) ->
    if ABM.links.cacheAgentLinks
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
    ABM.links.remove @
    u.removeItem @end1.links, @ if @end1.links?
    u.removeItem @end2.links, @ if @end2.links?
  
  # Return the two endpoints of this link
  bothEnds: -> [@end1, @end2]
  
  # Return the distance between the endpoints with the current topology.
  length: -> @end1.distance @end2
  
  # Return the other end of the link, given an endpoint agent.
  # Assumes the given input *is* one of the link endpoint pairs!
  otherEnd: (a) -> if @end1 is a then @end2 else @end1

# Class Links is a subclass of AgentSet which stores instances of Link.

class ABM.Links extends ABM.AgentSet
  # Constructor simply creates an unmodified AgentSet
  constructor: ->
    super()
    @cacheAgentLinks = false
  
  # Methods to change the default Link class variables.
  setDefaultColor:     (color)      -> ABM.Link::color = color
  setDefaultThickness: (thickness)  -> ABM.Link::thickness = thickness
  setDefaultHidden:    (hidden)     -> ABM.Link::hidden = hidden

  # Factory: Add 1 or more links from the from agent to
  # the to agent(s) which can be a single agent or an array
  # of agents.
  # The optional init proc is called on each of the newly created links.
  create: (from, to, init = ->) -> # returns list too
    to = [to] if not to.length?
    # NOTE: init must be applied after object inserted in agent set
    ((o) -> init(o); o) @add new ABM.Link from, a for a in to # too tricky?
  
  # Remove all links from set via link.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list

  # Return the subset of this set with the given breed value.
  breed: (breed) -> @getWithProp "breed", breed

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

# The usual alias for **ABM.util**.
u = ABM.util

# ### Class Model

class ABM.Model  
  # Constructor: 
  #
  # * create agentsets, install them and ourselves in ABM global namespace
  # * create layers/contexts, install drawing layer in ABM global namespace
  # * setup patch coord transforms for each layer context
  # * intialize various instance variables
  # * call `setup` abstract method
  constructor: (
    div, size, minX, maxX, minY, maxY,
    torus=true, neighbors=true
  ) ->
    ABM.model = @

    # Create 5 2D canvas contexts layered on top of each other.
    layers = for i in [0..4] # multi-line array comprehension
      u.createLayer div, size*(maxX-minX+1), size*(maxY-minY+1), i, "2d"
    # One of the layers is used for drawing only, not an agentset:
    @drawing = ABM.drawing = layers[1]

    # Initialize a patch coord transform for each layer.<br>
    # Note: this is permanent .. there is no ctx.restore() call.<br>
    # To use the original canvas 2D transform temporarily:
    #
    #     ctx.save()
    #     ctx.setTransform(1, 0, 0, 1, 0, 0) # reset to identity
    #       <draw in native coord system>
    #     ctx.restore() # restore back to patch coord system
    for ctx in layers # install permenant (no ctx.restore) patch coordinates
      ctx.save()
      ctx.scale size, -size
      ctx.translate -(minX-.5), -(maxY+.5); 
    # Create instance variable object with names for each layer
    @contexts = ABM.contexts =
      patches:   layers[0]
      drawing:   layers[1]
      links:     layers[2]
      agents:    layers[3]
      spotlight: layers[4]
    # Set a variable in each context with its name
    v.agentSetName = k for k,v of @contexts

    # Initialize agentsets.
    @patches = ABM.patches = \
      new ABM.Patches size,minX,maxX,minY,maxY,torus,neighbors
    @agents = ABM.agents = new ABM.Agents
    @links = ABM.links = new ABM.Links

    # Setup spotlight layer
    ABM.model.contexts.spotlight.globalCompositeOperation = "xor"

    # Initialize instance variables
    @showFPS = true # show fps in console. generally use chrome fps instead
    @ticks = 1 # initial tick/frame
    @refreshLinks = @refreshAgents = @refreshPatches = true # drawing flags
    @fastPatches = false
    
    # Call the models setup function.
    @setup()
    
    # Postprocesssing after setup
    if @agents.useSprites
      @agents.setDefaultSprite() if ABM.Agent::color?
      for a in @agents when not a.hasOwnProperty "sprite"
        if a.hasOwnProperty "color" or a.hasOwnProperty "shape" or a.hasOwnProperty "size"
          a.sprite = ABM.shapes.shapeToCtx a.shape, a.color, a.size*@patches.size
    

#### Optimizations:

  # Modelers "tune" their model by adjusting flags:
  #
  #      @refreshLinks = @refreshAgents = @refreshPatches
  #
  # and by the following methods:

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support imageSmoothingEnabled or equivalent.
  setFastPatches: ->
    ctx = @contexts.patches
    ctx.imageSmoothingEnabled = false
    ctx.mozImageSmoothingEnabled = false
    ctx.webkitImageSmoothingEnabled = false
    ctx.save() # revert to native 2D transform
    ctx.setTransform 1, 0, 0, 1, 0, 0
    @patches.drawWithPixels = true

  # Have agents use images (sprites) rather than drawing for agents.
  setAgentsUseSprites: ->
    @agents.setUseSprites(true)
    
  # Have patches cache the agents currently on them.
  # Optimizes Patch p.agentsHere method
  setCacheAgentsHere: ->
    p.agents = [] for p in @patches
    a.p.agents.push a for a in @agents
  
  # Have agents cache the links with them as a node.
  # Optimizes Agent a.myLinks method
  setCacheMyLinks: ->
    @links.cacheAgentLinks = true
    a.links = [] for a in @agents # not needed if called b4 any agents & links made
    (l.end1.links.push l; l.end2.links.push l) for l in @links
  
  # Have patches cache the given patchRect.
  # Optimizes patchRect, inRadius and inCone
  setCachePatchRects: (radius, meToo=false) ->
    for p in @patches
      p.pRect = @patches.patchRect p, radius, radius, meToo
      p.pRect.radius = radius
      p.pRect.meToo = meToo
  
  # Ask agents to cache their color strings.
  # This is a temporary optimization and will likely change.
  setAgentStaticColors: ->
    @agents.setStaticColors(true)

#### Text Utilities:
  # Return string name for agentset.  Note this depends on our
  # using a singleton naming convension: foo = new Foo(...)
  agentSetName: (aset) -> aset.constructor.name.toLowerCase()
  # Set the text parameters for an agentset's context.  See ABM.util
  setTextParams: (agentSetName, domFont, align="center", baseline="middle") ->
    agentSetName = @agentSetName(agentSetName) if typeof agentSetName isnt "string"
    u.ctxTextParams @contexts[agentSetName], domFont, align, baseline
  # Set the label parameters for an agentset's context.  See ABM.util
  setLabelParams: (agentSetName, color, xy) ->
    agentSetName = @agentSetName(agentSetName) if typeof agentSetName isnt "string"
    u.ctxLabelParams @contexts[agentSetName], color, xy
  
#### User Model Creation
# A user's model is made by subclassing Model and over-riding these
# two abstract methods. `super` need not be called.

  # Initialize your model here
  setup: -> # called at the end of model creation
  # Update/step your model here
  step: -> # called each step of the animation

#### Animation. 
# These will be called for you by Model. start/stop animation, increment ticks.

# A (possibly temporary) hook for the first run of the model.
# Similar to setup/step but `super` should be called in case
# AgentScript needs to do something here.
  startup: -> # called on first tick.  Used for optimization late binding.

# Initializes the animation and starts the animation by calling `animate`
  start: ->
    if @ticks is 1
      @startup()
    @startMS = Date.now()
    @startTick = @ticks
    @animStop = false
    @animate()

# Stop the animation at the end of the next call to `animate`
  stop: -> @animStop = true

# Call the agentset draw methods if either the first draw call or
# their "refresh" flags are set.  The latter are simple optimizations
# to avoid redrawing the same static scene.
  draw: ->
    @patches.draw @contexts.patches  if @refreshPatches or @ticks is 1
    @links.draw   @contexts.links    if @refreshLinks   or @ticks is 1
    @agents.draw  @contexts.agents   if @refreshAgents  or @ticks is 1
    @drawSpotlight() if @spotlightAgent?

# Runs the three methods used to increment the model and queues the next call to itself.
  animate: => # note fat arrow, animate bound to "this"
    @step()
    @draw()
    @tick() # Note: NL difference, called here not in user's step()
    requestAnimFrame @animate unless @animStop
# Updates the `ticks` counter and prints out the fps every 100 steps
# if the `showFPS` flag is set.
  tick: ->
    animTicks = @ticks-@startTick
    if @showFPS and (animTicks % 100) is 0 and animTicks isnt 0
      fps = Math.round (animTicks*1000/(Date.now()-@startMS))
      console.log "fps: #{fps} at #{animTicks} ticks"
    @ticks++

# Creates a spotlight effect on an agent, so we can follow it throughout the model
# We can pass in either an agent to be spotlighted or a breed. If we pass in a breed,
# we will find a random agent of that breed
  setSpotlight: (agent) ->
    if typeof agent is "string"
      agentSet = @[agent]()
      @spotlightAgent = agentSet.oneOf() unless not agentSet.any()
    else
      @spotlightAgent = agent

  removeSpotlight: ->
    @spotlightAgent = null
    u.clearCtx this.contexts.spotlight

  drawSpotlight: ->
    agent   = @spotlightAgent
    ctx     = this.contexts.spotlight

    return unless agent

    u.clearCtx ctx

    if !~this.agents.indexOf(agent)
      @spotlightAgent = null
      return

    u.fillCtx ctx, [0,0,0,0.6]

    ctx.beginPath()

    ctx.arc agent.x, agent.y, 3, 0, 2*Math.PI, false
    ctx.fill()


#### Breeds
# Two very primitive versions of NL's `breed` commands.
#
#     @agentBreeds "embers fires"
#     @linkBreeds "spokes rims"
#
# will create 4 dynamic methods: 
#
#     @embers() and @fires()
#
# which return agents with their breeds set to "embers" or "fires", and
#
#     @spokes() and @rims() 
#
# which return links with their breed set to either "spokes" or "rims"
#

  linkBreeds: (s) ->
    for b in s.split(" ")
      @[b] = do(b) =>
       -> @links.breed(b)
    null
  agentBreeds: (s) ->
    for b in s.split(" ")
      @[b] = do(b) =>
       -> @agents.breed(b)
    null

  
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
    ABM.root.ps = @patches
    ABM.root.p0 = @patches[0]
    ABM.root.as = @agents
    ABM.root.a0 = @agents[0]
    ABM.root.ls = @links
    ABM.root.l0 = @links[0]
    ABM.root.dr = @drawing
    ABM.root.u = ABM.util
    ABM.root.app = @
    ABM.root.cx = @contexts
    ABM.root.cl = (o) -> console.log o
    ABM.root.cla = (array) -> console.log a for a in array
    null
  
