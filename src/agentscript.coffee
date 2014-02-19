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
Array::indexOf or= (item) -> return i if x is item for x, i in @; -1


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
  
  # Two max/min int values. One for 2^53, largest int in float64, other for
  # bitwise ops which are 32 bit. See [discussion](http://goo.gl/WpAzT)
  MaxINT: Math.pow(2,53); MinINT: -Math.pow(2,53) # -@MaxINT fails, @ not defined yet
  MaxINT32: 0|0x7fffffff; MinINT32: 0|0x80000000
  
  # Good replacements for Javascript's badly broken`typeof` and `instanceof`
  # See [underscore.coffee](http://goo.gl/L0umK)
  isArray: Array.isArray or
    (obj) -> !!(obj and obj.concat and obj.unshift and not obj.callee)
  isFunction: (obj) -> 
    !!(obj and obj.constructor and obj.call and obj.apply)
  isString: (obj) -> 
    !!(obj is '' or (obj and obj.charCodeAt and obj.substr))
  
# ### Numeric Operations

  # Replace Math.random with a simple seedable generator.
  # See [StackOverflow](http://goo.gl/FafN3z)
  randomSeed: (seed=123456) ->
    Math.random = -> x=Math.sin(seed++)*10000; x-Math.floor(x)

  # Return random int in [0,max) or [min,max)
  randomInt: (max) -> Math.floor(Math.random() * max)
  randomInt2: (min, max) -> min + Math.floor(Math.random() * (max-min))
  # Return float Gaussian normal with given mean, std deviation.
  randomNormal: (mean = 0.0, sigma = 1.0) -> # Box-Muller
    u1 = 1.0-Math.random(); u2 = Math.random() # u1 in (0,1]
    norm = Math.sqrt(-2.0*Math.log(u1)) * Math.cos(2.0*Math.PI*u2)
    norm*sigma + mean
  # Return float in [0,max) or [min,max) or [-r/2,r/2)
  randomFloat: (max) -> Math.random() * max
  randomFloat2: (min, max) -> min + Math.random() * (max-min)
  randomCentered: (r) -> @randomFloat2 -r/2, r/2
  # Return log n where base is 10, base, e respectively.
  # Note ln: (n) -> Math.log n .. i.e. JS's log is log base e
  log10: (n) -> Math.log(n)/Math.LN10
  log2: (n) -> @logN n, 2
  logN: (n, base) -> Math.log(n)/Math.log(base)
  # Return true [mod functin](http://goo.gl/spr24), % is remainder, not mod.
  mod: (v, n) -> ((v % n) + n) % n
  # Return v to be between min, max via mod fcn
  wrap: (v, min, max) -> min + @mod(v-min, max-min)
  # Return v to be between min, max via clamping with min/max
  clamp: (v, min, max) -> Math.max(Math.min(v,max),min)
  # Return sign of a number as +/- 1
  sign: (v) -> if v<0 then -1 else 1
  # Return n to given precision, default 2
  # Considerably faster than equivalent: Number(n.toFixed(p))
  fixed: (n,p=2) -> p = Math.pow(10,p); Math.round(n*p)/p
  # Return an array of floating pt numbers as strings at given precision;
  # useful for printing
  aToFixed: (a, p=2) -> (i.toFixed p for i in a)
  # Return localized string for number, with commas etc
  tls: (n) -> n.toLocaleString()


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
  # Random color from a colormap set of r,g,b values.
  # Default is one of 125 (5^3) colors
  randomMapColor: (c = [], set = [0,63,127,191,255]) -> 
    @setColor c, @oneOf(set), @oneOf(set), @oneOf(set)
  randomBrightColor: (c=[]) -> @randomMapColor c, [0,127,255]
  # Modify an existing rgb or gray color.  Alpha optional, not set if not provided.
  # Modifying an existing array minimizes GC overhead
  setColor: (c, r, g, b, a) ->
    c.str = null if c.str?
    c[0] = r; c[1] = g; c[2] = b; c[3] = a if a?
    c
  setGray: (c, g, a) -> @setColor c, g, g, g, a
  # Return new color, c, by scaling each value of the rgb color max.
  scaleColor: (max, s, c = []) -> 
    c.str = null if c.str?
    c[i] = @clamp(Math.round(val*s),0,255) for val, i in max # [r,g,b] must be ints
    c
  # Return HTML color as used by canvas element.  Can include Alpha
  colorStr: (c) ->
    return s if (s = c.str)?
    @error "alpha > 1" if c.length is 4 and c[3] > 1
    c.str = if c.length is 3 then "rgb(#{c})" else "rgba(#{c})"
  # Compare two colors.  Alas, there is no array.Equal operator.
  colorsEqual: (c1, c2) -> c1.toString() is c2.toString()
  # Convert r,g,b to a luminance float value (not color array).
  # Round for 0-255 int for gray color value.
  # [Good post on image filters](http://goo.gl/pE9cV8)
  rgbToGray: (c) -> 0.2126*c[0] + 0.7152*c[1] + 0.0722*c[2]
  # RGB <> HSB (HSV) conversions.
  # RGB in [0-255], HSB in [0-1]
  # See [Wikipedia](http://en.wikipedia.org/wiki/HSV_color_space)
  # and [Blog Post](http://goo.gl/7yP4cO)
  rgbToHsb: (c) ->
    r=c[0]/255; g=c[1]/255; b=c[2]/255
    max = Math.max(r,g,b); min = Math.min(r,g,b); v = max
    h = 0; d = max-min; s = if max is 0 then 0 else d/max
    if max isnt min then switch max
      when r then h = (g - b) / d + (if g < b then 6 else 0)
      when g then h = (b - r) / d + 2
      when b then h = (r - g) / d + 4
    [Math.round(255*h/6), Math.round(255*s), Math.round(255*v)]
  hsbToRgb: (c) ->
    h=c[0]/255; s=c[1]/255; v=c[2]/255; i = Math.floor(h*6)
    f = h * 6 - i;        p = v * (1 - s)
    q = v * (1 - f * s);  t = v * (1 - (1 - f) * s)
    switch(i % 6)
      when 0 then r = v; g = t; b = p
      when 1 then r = q; g = v; b = p
      when 2 then r = p; g = v; b = t
      when 3 then r = p; g = q; b = v
      when 4 then r = t; g = p; b = v
      when 5 then r = v; g = p; b = q
    [Math.round(r*255), Math.round(g*255), Math.round(b*255)]
    
  # Colormap utilities.  Create an array of colors which are
  # shared by a set of objects.
  # Note: Experimental, will change.
  rgbMap: (R,G=R,B=R) ->
    R = (Math.round(i*255/(R-1)) for i in [0...R]) if typeof R is "number"
    G = (Math.round(i*255/(G-1)) for i in [0...G]) if typeof G is "number"
    B = (Math.round(i*255/(B-1)) for i in [0...B]) if typeof B is "number"
    map=[]; ((map.push [r,g,b] for b in B) for g in G) for r in R
    map
  grayMap: -> ([i,i,i] for i in [0..255])
  hsbMap: (n=256, s=255,b=255)-> 
    (@hsbToRgb [i*255/(n-1),s,b] for i in [0...n])
  gradientMap: (nColors, stops, locs) ->
    locs = (i/(stops.length-1) for i in [0...stops.length]) if not locs?
    ctx = @createCtx nColors, 1
    grad = ctx.createLinearGradient 0, 0, nColors, 0
    grad.addColorStop locs[i], @colorStr stops[i] for i in [0...stops.length]
    ctx.fillStyle = grad
    ctx.fillRect 0, 0, nColors, 1
    id = @ctxToImageData(ctx).data
    ([id[i], id[i+1], id[i+2]] for i in [0...id.length] by 4)

  # Return little/big endian-ness of hardware. 
  # See Mozilla pixel [manipulation article](http://goo.gl/Lxliq)
  isLittleEndian: ->
    # convert 1-int array to typed array
    d32 = new Uint32Array [0x01020304]
    # return true if byte order reversed
    (new Uint8ClampedArray d32.buffer)[0] is 4
  # Convert between degrees and radians.  We/Math package use radians.
  degToRad: (degrees) -> degrees * Math.PI / 180
  radToDeg: (radians) -> radians * 180 / Math.PI
  # Return angle in (-pi,pi] that added to rad2 = rad1
  # See NetLogo's [subtract-headings](http://goo.gl/CjoHuV) for explanation
  subtractRads: (rad1, rad2) ->
    dr = rad1-rad2; PI = Math.PI
    dr += 2*PI if dr <= -PI; dr -= 2*PI if dr > PI; dr

  
# ### Object Operations
  
  # Return object's own key or variable values
  ownKeys: (obj) -> (key for own key, value of obj)
  ownVarKeys: (obj) -> (key for own key, value of obj when not @isFunction value)
  ownValues: (obj) -> (value for own key, value of obj)

  # Parse a string to its JS value.
  # If s isn't a JS expression, return decoded string
  parseToPrimitive: (s) -> # http://goo.gl/jxb6Ae http://goo.gl/mQsQan
    try JSON.parse(s); catch e then decodeURIComponent(s)
  # Return URL queryString as object, defaulting to this page's.
  # If query element has no "=", set value to true.
  # Otherwise use parseToPrimitive. [StackOverflow](http://goo.gl/vIwdG6)
  parseQueryString: (query = window.location.search.substring(1)) ->
    res = {}
    for s in query.split "&" when query.length isnt 0
      t=s.split "="
      res[t[0]]=if t.length is 1 then true else @parseToPrimitive(t[1])
    res


# ### Array Operations
  
  # Does the array have any elements? Is the array empty?
  any: (array) -> array.length isnt 0
  empty: (array) -> array.length is 0
  # Make a copy of the array. Needed when you don't want to modify the given
  # array with mutator methods like sort, splice or your own functions.
  # By giving begin/arguments, retrieve a subset of the array.
  # Works with TypedArrays too.
  clone: (array, begin, end) ->
    op = if array.slice? then "slice" else "subarray"
    if begin? then array[op] begin, end else array[op] 0
  # Return last element of array.  Error if empty.
  last: (array) -> 
    @error "last: empty array" if @empty array
    array[array.length-1]
  # Return random element of array.  Error if empty.
  oneOf: (array) -> 
    @error "oneOf: empty array" if @empty array
    array[@randomInt array.length]
  # Return n random elements of array. Error if n > length
  # Note: array elements presumed unique, i.e. objects or distinct primitives
  nOf: (array, n) -> # Note: clone, shuffle then first n: poor performance
    n = Math.min(array.length, Math.floor(n)) # OK if n is float
    r = []; while r.length < n
      o = @oneOf(array); r.push o unless o in r
    r

  # True if item is in array. Binary search if f isnt null.
  contains: (array, item, f) -> @indexOf(array, item, f) >= 0
  # Remove an item from an array. Binary search if f isnt null.
  # Error if item not in array.
  removeItem: (array, item, f) ->
    unless (i = @indexOf array, item, f) < 0 then array.splice i, 1 
    else @error "removeItem: item not found" #; array
  # Remove elements in items from an array. Binary search if f isnt null.
  # Error if an item not in array.
  removeItems: (array, items, f) -> @removeItem(array,i,f) for i in items; array
  # Insert an item in a sorted array
  insertItem: (array, item, f) ->
    i = @sortedIndex array, item, f
    error "insertItem: item already in array" if array[i] is item
    array.splice i, 0, item
    
  # Randomize the elements of this array.
  # Clever! See [cookbook](http://goo.gl/TT2SY)
  shuffle: (array) -> array.sort -> 0.5 - Math.random()

  # Return o when f(o) min/max in array. Error if array empty.
  # If f is a string, return element with max value of that property.
  # If "valueToo" then return a 2-array of the element and the value;
  # used for cases where f is costly function.
  # 
  #     array = [{x:1,y:2}, {x:3,y:4}]
  #     # returns {x: 1, y: 2} 5
  #     [min, dist2] = minOneOf array, ((o)->o.x*o.x+o.y*o.y), true
  #     # returns {x: 3, y: 4}
  #     max = maxOneOf array, "x"
  minOneOf: (array, f=@identity, valueToo=false) ->
    @error "minOneOf: empty array" if @empty array
    r = Infinity; o = null; f = @propFcn f if @isString f
    for a in array
      (r = r1; o = a) if (r1=f(a)) < r
    if valueToo then [o, r] else o
  maxOneOf: (array, f=@identity, valueToo=false) ->
    @error "maxOneOf: empty array" if @empty array
    r = -Infinity; o = null; f = @propFcn f if @isString f
    for a in array
      (r = r1; o = a) if (r1=f(a)) > r
    if valueToo then [o, r] else o
  firstOneOf: (array, f) ->
    return i for a,i in array when f(a); return -1

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
  histOf: (array, bin=1, f=(i)->i) ->
    r = []; f = @propFcn f if @isString f
    for a in array
      i = Math.floor f(a)/bin
      r[i] = if (ri=r[i])? then ri+1 else 1
    r[i] = 0 for val,i in r when not val?
    r

  # Mutator. Sort array of objects in place by the function f.
  # If f is string, f returns property of object.
  # Returns array.
  # Clone first if you want to preserve the original array.
  #
  #     array = [{i:1},{i:5},{i:-1},{i:2},{i:2}]
  #     sortBy array, "i"
  #     # array now is [{i:-1},{i:1},{i:2},{i:2},{i:5}]
  sortBy: (array, f) -> 
   f = @propFcn f if @isString f # use item[f] if f is string
   array.sort (a,b) -> f(a) - f(b)

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
    return array if array.length < 2 # return if empty or singlton
    array.splice i,1 for i in [array.length-1..1] by -1 when array[i-1] is array[i]
    array
  
  # Return a new array composed of the rows of a matrix. I.e. convert
  #
  #     [[1,2,3],[4,5,6]] to [1,2,3,4,5,6]
  flatten: (matrix) -> matrix.reduce( (a,b) -> a.concat b )
  
  # Return array of property values of given array of objects
  aProp: (array, prop) -> (a[prop] for a in array)

  # Return scalar max/min/sum/avg of numeric array
  # Iterate rather than reduce: work with typed arrays
  aMax: (array) -> v=array[0]; v=Math.max v,a for a in array; v
  aMin: (array) -> v=array[0]; v=Math.min v,a for a in array; v
  aSum: (array) -> v=0; v += a for a in array; v
  aAvg: (array) -> @aSum(array)/array.length
  aMid: (array) -> 
    array = if array.sort? then @clone array else @typedToJS array
    array.sort()
    array[Math.floor(array.length/2)]

  aNaNs: (array) -> (i for v,i in array when isNaN v)
  
  # Return array composed of f pairwise on both arrays
  aPairwise: (a1, a2, f) -> v=0; f(v,a2[i]) for v,i in a1 
  aPairSum: (a1, a2) -> @aPairwise a1, a2, (a,b)->a+b
  aPairDif: (a1, a2) -> @aPairwise a1, a2, (a,b)->a-b
  aPairMul: (a1, a2) -> @aPairwise a1, a2, (a,b)->a*b

  # Return a JS array given a TypedArray.
  # To create TypedArray from JS array: new Uint8Array(jsa) etc
  typedToJS: (typedArray) -> (i for i in typedArray)
  
  # Return a linear interpolation between lo and hi.
  # Scale is in [0-1], and the result is in [lo,hi]
  # [Why the name `lerp`?](http://goo.gl/QrzMc)
  lerp: (lo, hi, scale) -> lo + (hi-lo)*scale # @clamp(scale, 0, 1)
  # Return point interpolated between two points.
  lerp2: (x0, y0, x1, y1, scale) -> [@lerp(x0,x1,scale), @lerp(y0,y1,scale)]
  # Return an array with values in [lo,hi], defaults to [0,1].
  # Note: to have a half-open interval, [lo,hi), try hi=hi-.00009
  normalize: (array, lo = 0, hi = 1) ->
    min = @aMin array; max = @aMax array; scale = 1/(max-min)
    (@lerp(lo, hi, scale*(num-min)) for num in array)

  # Return array index of item, or index for item if array to remain sorted.
  # f is used to return an integer for sorting, primarily for object properties.
  # If f is a string, it is the object property to sort by.
  # Adapted from underscore's _.sortedIndex.
  sortedIndex: (array, item, f=(o)->o) -> # update to _.sortedIndex someday
    f = @propFcn f if @isString f # use item[f] if f is string
    # Why not array.length - 1? Because we can insert 1 after end of array.
    value = f(item); low = 0; high = array.length
    while low < high
      mid = (low + high) >>> 1 # floor (low+high)/2
      if f(array[mid]) < value then low = mid + 1 else high = mid
    low

  # Return argument unchanged; for primitive arrays or objs sorted by reference
  identity: (o) -> o
  # Return a function that returns an object's property.  Property in fcn closure.
  propFcn: (prop) -> (o)->o[prop]
  # Return index of value in array or -1 if not found.
  # If no property given, use Array.indexOf.
  # If property given, use binary search.
  # Property can be string or function. If property is "", use identity default.
  indexOf: (array, item, property)->
    if property?
      i = @sortedIndex array, item, if property is "" then null else property
      if array[i] is item then i else -1
    else array.indexOf item

# ### Topology Operations
  
  # Return angle in [-pi,pi] radians from x1,y1 to x2,y2
  # [See: Math.atan2](http://goo.gl/JS8DF)
  radsToward: (x1, y1, x2, y2) -> Math.atan2 y2-y1, x2-x1
  # Return true if x2,y2 is in cone radians around heading radians from x1,x2
  # and within distance radius from x1,x2.
  # I.e. is p2 in cone/heading/radius from p1?
  inCone: (heading, cone, radius, x1, y1, x2, y2) ->
    if radius < @distance x1, y1, x2, y2 then return false
    angle12 = @radsToward x1, y1, x2, y2 # angle from 1 to 2
    cone/2 >=Math.abs @subtractRads(heading, angle12)
  # Return the Euclidean distance and distance squared between x1,y1, x2,y2.
  # The squared distance is used for comparisons to avoid the Math.sqrt fcn.
  distance: (x1, y1, x2, y2) -> dx = x1-x2; dy = y1-y2; Math.sqrt dx*dx + dy*dy
  sqDistance: (x1, y1, x2, y2) -> dx = x1-x2; dy = y1-y2; dx*dx + dy*dy
  
  # Convert polar r,theta to cartesian x,y.
  # Default to 0,0 origin, optional x,y origin.
  polarToXY: (r, theta, x=0, y=0) -> [x+r*Math.cos(theta), y+r*Math.sin(theta)]

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
  importImage: (name, f = ->) ->
    if (img=@fileIndex[name])? # wtf? or ((img=name).width and img.height)
      f(img) #if img.isDone
    else
      @fileIndex[name] = img = new Image()
      img.isDone = false
      img.crossOrigin = "Anonymous"
      img.onload = -> f(img); img.isDone = true
      img.src = name
    img
    
  # Use XMLHttpRequest to fetch data of several types. Data Types: text,
  # arraybuffer, blob, json, document, [See specification](http://goo.gl/y3r3h).
  # method is "GET" or "POST". f is function to call onload, default to no-op.
  xhrLoadFile: (name, method="GET", type="text", f = ->) -> # AJAX async request
    if (xhr=@fileIndex[name])?
      f(xhr.response)
    else
      @fileIndex[name] = xhr = new XMLHttpRequest()
      xhr.isDone = false
      xhr.open method, name # POST mainly for security and large files
      xhr.responseType = type
      xhr.onload = -> f(xhr.response); xhr.isDone = true
      xhr.send()
    xhr
  
  # Return true if all files are loaded.
  filesLoaded: (files = @fileIndex) ->
    array = (v.isDone for v in (@ownValues files))
    array.reduce ((a,b)->a and b), true
  # Wait for files to be loaded before executing callback f
  waitOnFiles: (f, files = @fileIndex) -> @waitOn (=> @filesLoaded files), f
  # Wait for function done() to return true before calling callback f
  waitOn: (done, f) ->
    if done() then f() else setTimeout (=> @waitOn(done, f)), 1000

# ### Image Data Operations
  # Make a copy of an image.
  # Note: new image will have the naturalWidth/Height of input img.
  # Should be sync
  cloneImage: (img) -> (i=new Image()).src = img.src; i

  # Create a data array from an image's imageData
  # img may be a canvas.
  # The function f = f(imageData, rgbIndex) -> number
  imageToData: (img, f=@pixelByte(0), arrayType=Uint8ClampedArray) ->
    @imageRowsToData img, img.height, f, arrayType
  imageRowsToData: (img, rowsPerSlice, f=@pixelByte(0), arrayType=Uint8ClampedArray) ->
    rowsDone = 0; data = new arrayType img.width*img.height
    while rowsDone < img.height
      rows = Math.min img.height - rowsDone, rowsPerSlice
      ctx = @imageSliceToCtx img, 0, rowsDone, img.width, rows # REMIND: pass ctx
      idata = @ctxToImageData(ctx).data
      dataStart = rowsDone*img.width
      data[dataStart+i] = f(idata,4*i) for i in [0...idata.length/4] by 1
      rowsDone += rows
    data
  # Two utilities for Image data extraction.
  # They return a fcn in a closure which "sees" the args and variables
  pixelBytesToInt: (a) ->
    ImageByteFmts = [[2],[1,2],[0,1,2],[3,0,1,2]]
    a=ImageByteFmts[a-1] if typeof a is "number"
    (id,i)->val = 0; val = val*256 + id[i+j] for j in a; val
  pixelByte: (n) -> (id,i)->id[i+n]

# ### Canvas/Context Operations

  # Create a new canvas of given width/height
  createCanvas: (width, height) ->
    can = document.createElement 'canvas'
    can.width = width; can.height = height
    can
  # As above, but returing the context object.
  # Note ctx.canvas is the canvas for the ctx, and can be use as an image.
  createCtx: (width, height, ctxType="2d") ->
    can = @createCanvas width, height
    if ctxType is "2d"
    then can.getContext "2d" 
    else can.getContext("webgl") ? can.getContext("experimental-webgl")

  # Return a "layer" 2D/3D rendering context within the specified HTML `<div>`,
  # with the given width/height positioned absolutely at top/left within the div,
  # and with the z-index of z.
  #
  # The z level gives us the capability of buildng a "stack" of coordinated canvases.
  createLayer: (div, width, height, z, ctx = "2d") -> # a canvas ctx object
    if ctx is "img" 
    then element = ctx = new Image(); ctx.width = width; ctx.height=height
    else element = (ctx=@createCtx(width, height, ctx)).canvas
    @insertLayer div, element, width, height, z
    ctx
  insertLayer: (div, element, w, h, z) ->
    element.setAttribute 'style', # Note: this erases existing style, el.style.position doesnt
    "position:absolute;top:0;left:0;width:#{w};height:#{h};z-index:#{z}"
    div.appendChild(element)

  setCtxSmoothing: (ctx, smoothing) ->
    ctx.imageSmoothingEnabled = smoothing
    ctx.mozImageSmoothingEnabled = smoothing
    ctx.oImageSmoothingEnabled = smoothing
    ctx.webkitImageSmoothingEnabled = smoothing


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
  # Draw string of the given color at the xy location, in ctx pixel coords.
  # Use setIdentity .. reset if a transform is being used by caller.
  ctxDrawText: (ctx, string, x, y, color = [0,0,0], setIdentity = true) ->
    @setIdentity(ctx) if setIdentity
    ctx.fillStyle = @colorStr color;  ctx.fillText(string, x, y)
    ctx.restore() if setIdentity
  # Set the element text align and baseline drawing parameters
  #
  # * font is a HTML/CSS string like: "9px sans-serif"
  # * align is left right center start end
  # * baseline is top hanging middle alphabetic ideographic bottom
  #
  # See [reference](http://goo.gl/AvEAq) for details.
  ctxTextParams: (ctx, font, align = "center", baseline = "middle") -> 
    ctx.font = font; ctx.textAlign = align; ctx.textBaseline = baseline
  elementTextParams: (e, font, align = "center", baseline = "middle") -> 
    e = e.canvas if e.canvas?
    e.style.font = font; e.style.textAlign = align; e.style.textBaseline = baseline

  # Convert an image to a context. ctx.canvas gives the created canvas.
  # If w, h provided, scale to that size. img may be a canvas
  # Note: to convert a ctx to an "image" (drawImage) use ctx.canvas
  imageToCtx: (img, w, h) ->
    if w? and h?
      ctx = @createCtx w, h
      ctx.drawImage img, 0, 0, w, h
    else
      ctx = @createCtx img.width, img.height
      ctx.drawImage img, 0, 0
    ctx
  imageSliceToCtx: (img, sx, sy, sw, sh, ctx) ->
    if ctx?
    then ctx.canvas.width = sw; ctx.canvas.height = sh
    else ctx = @createCtx sw, sh
    ctx.drawImage img, sx, sy, sw, sh, 0, 0, sw, sh
    ctx
  imageToCtxDownStepped: (img, tw, th) -> # http://goo.gl/UnLJSZ
    ctx1 = u.createCtx tw, th
    w = img.width; h = img.height; ihalf = (n) -> Math.ceil n/2
    steps = Math.ceil(u.log2( if (w/tw)>(h/th) then (w/tw) else (h/th)) )
    console.log "steps", steps
    if steps <= 1
      ctx1.drawImage img, 0, 0, tw, th
    else
      console.log "img w/h", w, h, "->", ihalf(w), ihalf(h)
      ctx = u.createCtx w = ihalf(w), h = ihalf(h); can = ctx.canvas
      ctx.drawImage img, 0, 0, w, h
      for step in [steps...2] # 2 not 1 due to initial halving above
        console.log "can w/h", w, h, "->", ihalf(w), ihalf(h)
        ctx.drawImage can, 0, 0, w, h, 0, 0, w = ihalf(w), h = ihalf(h)
      console.log "target w/h", w, h, "->", tw, th
      ctx1.drawImage can, 0, 0, w, h, 0, 0, tw, th
    ctx1

  # Convert a canvas to an image, executing fcn f on completion.
  # Generally can skip callback but see [stackoverflow](http://goo.gl/kIk2U)
  # Note: uses toDataURL thus possible cross origin problems.
  # Fix: use ctx.canvas for programatic imaging.
  ctxToDataUrl: (ctx) -> ctx.canvas.toDataURL "image/png"
  ctxToDataUrlImage: (ctx, f) ->
    img = new Image()
    (img.onload = -> f(img)) if f?
    img.src = ctx.canvas.toDataURL "image/png"
    img
  # Convert a ctx to an imageData object
  ctxToImageData: (ctx) ->
    ctx.getImageData 0, 0, ctx.canvas.width, ctx.canvas.height

  # Canvas versions of above
  # canvasToImage: (canvas) -> ctxToImage(canvas.getContext "2d")
  # canvasToImageData: (canvas) -> ctxToImageData(canvas.getContext "2d")
  # imageToCanvas: (image) -> imageToCtx(image).canvas
  
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
  circle: # Note: NetLogo's dot is simply circle with a small size
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
  add: (name, rotate, draw, shortcut) -> # draw can be an image, shortcut defaults to null
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
      ctx.fillStyle = u.colorStr color unless shape.img?
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
    bits = Math.ceil ABM.patches.toBits size
    shape = @[name]
    index = if shape.img? then name else "#{name}-#{u.colorStr(color)}"
    ctx = spriteSheets[bits]
    # Create sheet for this bit size if it does not yet exist
    unless ctx?
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
  #        [{id:1,x:0,y:1}, {id:2,x:8,y:0}, {id:3,x:6,y:4},
  #         {id:4,x:1,y:3}, {id:5,x:1,y:1}]

# ### Constructor and add/remove agents.
  
  # Create an empty `AgentSet` and initialize the `ID` counter for add().
  # If mainSet is supplied, the new agentset is a sub-array of mainSet.
  # This sub-array feature is how breeds are managed, see class `Model`
  constructor: (@agentClass, @name, @mainSet) ->
    super(0) # doesn't yield empty array if already instances in the mainSet
    @breeds = [] unless @mainSet?
    @agentClass::breed = @ # let the breed know I'm it's agentSet
    @ownVariables = [] # keep list of user variables
    @ID = 0 unless @mainSet? # Do not set ID if I'm a subset

  # Abstract method used by subclasses to create and add their instances.
  create: ->
    
  # Add an agent to the list.  Only used by agentset factory methods. Adds
  # the `id` property to all agents. Increment `ID`.
  # Returns the object for chaining. The set will be sorted by `id`.
  #
  # By "agent" we mean an instance of `Patch`, `Agent` and `Link` and their breeds
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
    u.removeItem @mainSet, o if @mainSet?
    u.removeItem @, o
    @

  # Set the default value of a agent class, return agetnset
  setDefault: (name, value) -> @agentClass::[name] = value; @
  # Declare variables of an agent class. 
  # Vars = a string of space separated names or an array of name strings
  # Return agentset.
  own: (vars) -> # maybe not set default if val is null?
    # vars = vars.split(" ") if not u.isArray vars
    # for name in vars#.split(" ") # if not u.isArray vars
    for name in vars.split(" ")
      @setDefault name, null
      @ownVariables.push name
    @

  # Move an agent from its AgentSet/breed to be in this AgentSet/breed.
  # REMIND: match NetLogo sematics in terms of own variables.
  setBreed: (a) -> # change agent a to be in this breed
    u.removeItem a.breed, a, "id" if a.breed.mainSet?
    u.insertItem @, a, "id" if @mainSet?
    proto = a.__proto__ = @agentClass.prototype
    delete a[k] for own k,v of a when proto[k]?
    a

  # Return all agents that are not of the given breeds argument.
  # Breeds is a string of space separated names:
  #   @patches.exclude "roads houses"
  exclude: (breeds) ->
    breeds = breeds.split(" ")
    @asSet (o for o in @ when o.breed.name not in breeds)

  # Recursive floodfill:
  # Arguments:
  #
  # * aset: Initial array of agents, often a single agent: [a]
  # * fCandidate(a) -> true if a is elegible to be added to the set.
  # * fJoin(a, lastSet) -> adds a to the agentset, usually by setting a variable
  # * fNeighbors(a) -> returns the neighbors of this agent
  # * asetLast: the array of the last set of agents to join the set.
  #
  # asetLast generally [] but can used if the join function uses the prior
  # agents for a distance calculation, for example.
  #
  floodFill: (aset, fCandidate, fJoin, fNeighbors, asetLast=[]) ->
    fJoin p, asetLast for p in aset
    asetNext = []
    for p in aset
      for n in fNeighbors(p) when fCandidate n
        asetNext.push n if asetNext.indexOf(n) < 0
    @floodFill asetNext, fCandidate, fJoin, fNeighbors, aset if asetNext.length > 0

    
  
  # Remove adjacent duplicates, by reference, in a sorted agentset.
  # Use `sortById` first if agentset not sorted.
  #
  #     as = (AS.oneOf() for i in [1..4]) # 4 random agents w/ dups
  #     ABM.AgentSet.asSet as # [{id:1,x:8,y:0}, {id:0,x:0,y:1},
  #                              {id:0,x:0,y:1}, {id:2,x:6,y:4}]
  #     as.sortById().uniq() # [{id:0,x:0,y:1}, {id:1,x:8,y:0}, 
  #                             {id:2,x:6,y:4}]
  uniq: -> u.uniq(@)

  # The static `ABM.AgentSet.asSet` as a method.
  # Used by agentset methods creating new agentsets.
  asSet: (a, setType = @) -> ABM.AgentSet.asSet a, setType # setType = ABM.AgentSet

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

  # Return an array of agents with the property equal to the given value
  #
  #     AS.getPropWith "x", 1
  #     [{id:4,x:1,y:3},{id:5,x:1,y:1}]
  getPropWith: (prop, value) -> @asSet (o for o in @ when o[prop] is value)

  # Set the property of the agents to a given value.  If value
  # is an array, its values will be used, indexed by agentSet's index.
  # This is generally used via: getProp, modify results, setProp
  #
  #     # increment x for agents with x=1
  #     AS1 = ABM.AgentSet.asSet AS.getPropWith("x",1)
  #     AS1.setProp "x", 2 # {id:4,x:2,y:3},{id:5,x:2,y:1}
  #
  # Note this changes the last two objects in the original AS above
  setProp: (prop, value) ->
    if u.isArray value
    then o[prop] = value[i] for o,i in @; @
    else o[prop] = value for o in @; @
  
  # Get the agent with the min/max prop value in the agentset
  #
  #     min = AS.minProp "y"  # 0
  #     max = AS.maxProp "y"  # 4
  maxProp: (prop) -> u.aMax @getProp(prop)
  minProp: (prop) -> u.aMin @getProp(prop)
  histOfProp: (prop, bin=1) -> u.histOf @, bin, prop
  
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
  minOneOf: (f, valueToo=false) -> u.minOneOf @, f, valueToo
  maxOneOf: (f, valueToo=false) -> u.maxOneOf @, f, valueToo

# ### Drawing
  
  # For agentsets who's agents have a `draw` method.
  # Clears the graphics context (transparent), then
  # calls each agent's draw(ctx) method.
  draw: (ctx) -> 
    u.clearCtx(ctx); o.draw(ctx) for o in @ when not o.hidden; null
  
  # Show/Hide all of an agentset or breed.
  # To show/hide an individual object, set its prototype: o.hidden = bool
  show: -> o.hidden = false for o in @; @draw(ABM.contexts[@name])
  hide: -> o.hidden = true for o in @; @draw(ABM.contexts[@name])

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

  floodFill: (aset, fCandidate, fJoin, fNeighbors=((p)->p.n), asetLast=[]) ->
    super aset, fCandidate, fJoin, fNeighbors, asetLast

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

# ### Agent & Agents
  
# Class Agent instances represent the dynamic, behavioral element of ABM.
# Each agent knows the patch it is on, and interacts with that and other
# patches, as well as other agents.
class ABM.Agent
  # Constructor & Class Variables:
  #
  # * id:         unique identifier, promoted by agentset create() factory method
  # * breed:      the agentset this agent belongs to
  # * x,y:        position on the patch grid, in patch coordinates, default: 0,0
  # * size:       size of agent, in patch coords, default: 1
  # * color:      the color of the agent, default: randomColor
  # * shape:      the shape name of the agent, default: "default"
  # * label:      a text label drawn on my instances
  # * labelColor: the color of my label text
  # * labelOffset:the x,y offset of my label from my x,y location
  # * heading:    direction of the agent, in radians, from x-axis
  # * hidden:     whether or not to draw this agent
  # * p:          patch at current x,y location
  # * penDown:    true if agent pen is drawing
  # * penSize:    size in pixels of the pen, default: 1 pixel
  # * sprite:     an image of the agent if non null
  # * cacheLinks: if true, keep array of links in/out of me
  # * links:      array of links in/out of me.  Only used if @cacheLinks is true
  #
  # These class variables are "defaults" and many are "promoted" to instance variables.
  # To have these be set to a constant for all instances, use breed.setDefault.
  # This can be a huge savings in memory.
  id: null            # unique id, promoted by agentset create factory method
  breed: null         # my agentSet, set by the agentSet owning me
  x: 0; y:0; p: null  # my location and the patch I'm on
  size: 1             # my size in patch coords
  color: null         # default color, overrides random color if set
  shape: "default"    # my shape
  hidden: false       # draw me?
  label: null         # my text
  labelColor: [0,0,0] # its color
  labelOffset: [0,0]  # its offset from my x,y
  penDown: false      # if my pen is down, I draw my path between changes in x,y
  penSize: 1          # the pen thickness in pixels
  heading: null       # the direction I'm pointed in, in radians
  sprite: null        # an image of me for optimized drawing
  cacheLinks: false   # should I keep links to/from me in links array?.
  links: null         # array of links to/from me as an endpoint; init by ctor
  constructor: -> # called by agentSets create factory, not user
    @x = @y = 0
    @p = ABM.patches.patch @x, @y
    @color = u.randomColor() unless @color? # promote color if default not set
    @heading = u.randomFloat(Math.PI*2) unless @heading? 
    @p.agents.push @ if @p.agents? # ABM.patches.cacheAgentsHere
    @links = [] if @cacheLinks

  # Set agent color to `c` scaled by `s`. Usage: see patch.scaleColor
  scaleColor: (c, s) -> 
    @color = u.clone @color unless @hasOwnProperty "color" # promote color to inst var
    u.scaleColor c, s, @color
  
  # Return a string representation of the agent.
  toString: -> "{id:#{@id} xy:#{u.aToFixed [@x,@y]} c:#{@color} h: #{@heading.toFixed 2}}"
  
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
      drawing.lineWidth = ABM.patches.fromBits @penSize
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
      @setSprite() unless @sprite? # lazy evaluation of useSprites
      ABM.shapes.drawSprite ctx, @sprite, @x, @y, @size, rad
    else
      ABM.shapes.draw ctx, shape, @x, @y, @size, rad, @color
    if @label?
      [x,y] = ABM.patches.patchXYtoPixelXY @x, @y
      u.ctxDrawText ctx, @label, x+@labelOffset[0], y+@labelOffset[1], @labelColor
  
  # Set an individual agent's sprite, synching its color, shape, size
  setSprite: (sprite)->
    if (s=sprite)?
      @sprite = s; @color = s.color; @shape = s.shape; @size = s.size
    else
      @color = u.randomColor unless @color?
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
  # Used internally to determine how to draw links between two agents.
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
    if (ps=ABM.patches).isTorus
    then u.torusRadsToward @x, @y, x, y, ps.numX, ps.numY
    else u.radsToward @x, @y, x, y

  # Return heading towards given agent/patch using patch topology.
  towards: (o) -> @towardsXY o.x, o.y
  
  # Return patch ahead of me by given distance and heading.
  # Returns null if non-torus and off patch world
  patchAtHeadingAndDistance: (h,d) ->
    [x,y] = u.polarToXY d, h, @x, @y; patchAt x,y
  patchLeftAndAhead: (dh, d) -> @patchAtHeadingAndDistance @heading+dh, d
  patchRightAndAhead: (dh, d) -> @patchAtHeadingAndDistance @heading-dh, d
  patchAhead: (d) -> @patchAtHeadingAndDistance @heading, d
  canMove: (d) -> @patchAhead(d)?
  patchAt: (dx,dy) ->
    x=@x+dx; y=@y+dy
    if (ps=ABM.patches).isOnWorld x,y then ps.patch x,y else null
  
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
  cacheLinks: -> @agentClass::cacheLinks = true # all agents, not individual breeds

  # Use sprites rather than drawing
  setUseSprites: (@useSprites=true) ->
  
  # Filter to return all instances of this breed.  Note: if used by
  # the mainSet, returns just the agents that are not subclassed breeds.
  in: (array) -> @asSet (o for o in array when o.breed is @)

  # Factory: create num new agents stored in this agentset.The optional init
  # proc is called on the new agent after inserting in its agentSet.
  create: (num, init = ->) -> # returns array of new agents too
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
    u.removeItem rect, a unless meToo
    rect
  
  # Return the members of this agentset that are within radius distance
  # from me, and within cone radians of my heading using patch topology
  inCone: (a, heading, cone, radius, meToo=false) -> # heading? .. so p ok?
    as = @inRect a, radius, radius, true
    super a, heading, cone, radius, meToo #as.inCone a, heading, cone, radius, meToo
  
  # Return the members of this agentset that are within radius distance
  # from me, using patch topology
  inRadius: (a, radius, meToo=false)->
    as = @inRect a, radius, radius, true
    super a, radius, meToo # as.inRadius a, radius, meToo

# ### Link and Links
  
# Class Link connects two agent endpoints for graph modeling.
class ABM.Link
  # Constructor initializes instance variables:
  #
  # * id:         unique identifier, promoted by agentset create() factory method
  # * breed:      the agentset this agent belongs to
  # * end1, end2: two agents being connected
  # * color:      defaults to light gray
  # * thickness:  thickness in pixels of the link, default 2
  # * label:      a text label drawn on my instances
  # * labelColor: the color of my label text
  # * labelOffset:the x,y offset of my label from my x,y location
  # * hidden:     whether or not to draw this link

  id: null            # unique id, promoted by agentset create factory method
  breed: null         # my agentSet, set by the agentSet owning me
  end1:null; end2:null# My two endpoints, using agents. Promoted by ctor
  color: [130,130,130]# my color
  thickness: 2        # my thickness in pixels, default to 2
  hidden: false       # draw me?
  label: null         # my text
  labelColor: [0,0,0] # its color
  labelOffset: [0,0]  # its offset from my midpoint
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
    ctx.lineWidth = ABM.patches.fromBits @thickness
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
    if @label?
      [x0, y0]  = u.lerp2 @end1.x, @end1.y, @end2.x, @end2.y, .5
      [x,y] = ABM.patches.patchXYtoPixelXY x0, y0
      u.ctxDrawText ctx, @label, x+@labelOffset[0], y+@labelOffset[1], @labelColor
  
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

  # Factory: Add 1 or more links from the from agent to the to agent(s) which
  # can be a single agent or an array of agents. The optional init
  # proc is called on the new link after inserting in the agentSet.
  create: (from, to, init = ->) -> # returns array of new links too
    to = [to] unless to.length?
    ((o) -> init(o); o) @add new @agentClass from, a for a in to # too tricky?
  
  # Remove all links from set via link.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list

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
  # Create initial animator for the model, specifying default rate (fps) and multiStep.
  # If multiStep, run the draw() and step() methods separately by draw() using
  # requestAnimFrame and step() using setTimeout.
  constructor: (@model, @rate=30, @multiStep=model.world.isHeadless) -> 
    @isHeadless = model.world.isHeadless; @reset()
  # Adjust animator.  Call before model.start()
  # in setup() to change default settings
  setRate: (@rate, @multiStep=@isHeadless) -> @resetTimes() # Change rate while running?
  # start/stop model, often used for debugging and resetting model
  start: ->
    return unless @stopped # avoid multiple animates
    @resetTimes()
    @stopped = false
    @animate()
  stop: ->
    @stopped = true
    if @animHandle? then cancelAnimFrame @animHandle
    if @timeoutHandle? then clearTimeout @timeoutHandle
    if @intervalHandle? then clearInterval @intervalHandle
    @animHandle = @timerHandle = @intervalHandle = null
  # Internal util: reset time instance variables
  resetTimes: ->
    @startMS = @now()
    @startTick = @ticks
    @startDraw = @draws
  # Reset used by model.reset when resetting model.
  reset: -> @stop(); @ticks = @draws = 0
  # Two handlers used by animation loop
  step: -> @ticks++; @model.step()
  draw: -> @draws++; @model.draw()
  # step and draw the model once, mainly debugging
  once: -> @step(); @draw()
  # Get current time, with high resolution timer if available
  now: -> (performance ? Date).now()
  # Time in ms since starting animator
  ms: -> @now()-@startMS
  # Get ticks/draws per second. They will differ if multiStep.
  # The "if" is to avoid from ms=0
  ticksPerSec: -> if (elapsed = @ticks-@startTick) is 0 then 0 else Math.round elapsed*1000/@ms()
  drawsPerSec: -> if (elapsed = @draws-@startDraw) is 0 then 0 else Math.round elapsed*1000/@ms()
  # Return a status string for debugging and logging performance
  toString: -> "ticks: #{@ticks}, draws: #{@draws}, rate: #{@rate} tps/dps: #{@ticksPerSec()}/#{@drawsPerSec()}"
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
    @animHandle = requestAnimFrame @animateDraws unless @stopped
  animate: ->
    @animateSteps() if @multiStep
    @animateDraws() unless @isHeadless and @multiStep

# ### Class Model

ABM.models = {} # user space, put your models here
class ABM.Model  
  
  # Class variable for layers parameters. 
  # Can be added to by programmer to modify/create layers, **before** starting your own model.
  # Example:
  # 
  #     v.z++ for k,v of ABM.Model::contextsInit # increase each z value by one
  contextsInit: { # Experimental: image:   {z:15,  ctx:"img"} 
    patches:   {z:10, ctx:"2d"}
    drawing:   {z:20, ctx:"2d"}
    links:     {z:30, ctx:"2d"}
    agents:    {z:40, ctx:"2d"}
    spotlight: {z:50, ctx:"2d"}
  }
  # Constructor: 
  #
  # * create agentsets, install them and ourselves in ABM global namespace
  # * create layers/contexts, install drawing layer in ABM global namespace
  # * setup patch coord transforms for each layer context
  # * intialize various instance variables
  # * call `setup` abstract method
  constructor: (
    div, size=13, minX=-16, maxX=16, minY=-16, maxY=16,
    isTorus=false, hasNeighbors=true, isHeadless=false
  ) ->
    ABM.model = @
    @setWorld size, minX, maxX, minY, maxY, isTorus, hasNeighbors, isHeadless
    @contexts = ABM.contexts = {}
    unless isHeadless
      (@div=document.getElementById(div)).setAttribute 'style',
        "position:relative; width=#{@world.pxWidth}; height={@world.pxHeight}"

      # * Create 2D canvas contexts layered on top of each other.
      # * Initialize a patch coord transform for each layer.
      # 
      # Note: this transform is permanent .. there isn't the usual ctx.restore().
      # To use the original canvas 2D transform temporarily:
      #
      #     u.setIdentity ctx
      #       <draw in native coord system>
      #     ctx.restore() # restore patch coord system
      for own k,v of @contextsInit
        @contexts[k] = ctx = u.createLayer @div, @world.pxWidth, @world.pxHeight, v.z, v.ctx
        @setCtxTransform ctx if ctx.canvas?
        u.elementTextParams ctx, "10px sans-serif", "center", "middle"

      # One of the layers is used for drawing only, not an agentset:
      @drawing = ABM.drawing = @contexts.drawing
      @drawing.clear = => u.clearCtx @drawing
      # Setup spotlight layer, also not an agentset:
      @contexts.spotlight.globalCompositeOperation = "xor"

    # if isHeadless
    # # Initialize animator to headless default: 30fps, async  
    # then @anim = new ABM.Animator @, null, true
    # # Initialize animator to default: 30fps, not async
    # else 
    @anim = new ABM.Animator @
    # Set drawing controls.  Default to drawing each agentset.
    # Optimization: If any of these is set to false, the associated
    # agentset is drawn only once, remaining static after that.
    @refreshLinks = @refreshAgents = @refreshPatches = true

    # Initialize agentsets.
    @patches = ABM.patches = new ABM.Patches ABM.Patch, "patches"
    @agents = ABM.agents = new ABM.Agents ABM.Agent, "agents"
    @links = ABM.links = new ABM.Links ABM.Link, "links"

    # Initialize model global resources
    @debugging = false
    @modelReady = false
    @globalNames = null; @globalNames = u.ownKeys @
    @globalNames.set = false
    @startup()
    u.waitOnFiles => @modelReady=true; @setup(); @globals() unless @globalNames.set

  # Initialize/reset world parameters.
  setWorld: (size, minX, maxX, minY, maxY, isTorus, hasNeighbors, isHeadless) ->
    numX = maxX-minX+1; numY = maxY-minY+1; pxWidth = numX*size; pxHeight = numY*size
    minXcor=minX-.5; maxXcor=maxX+.5; minYcor=minY-.5; maxYcor=maxY+.5
    ABM.world = @world = {size,minX,maxX,minY,maxY,minXcor,maxXcor,minYcor,maxYcor,
      numX,numY,pxWidth,pxHeight,isTorus,hasNeighbors,isHeadless}
  setCtxTransform: (ctx) ->
    ctx.canvas.width = @world.pxWidth; ctx.canvas.height = @world.pxHeight
    ctx.save()
    ctx.scale @world.size, -@world.size
    ctx.translate -(@world.minXcor), -(@world.maxYcor)
  globals: (globalNames) ->
    if globalNames? 
    then @globalNames = globalNames; @globalNames.set = true
    else @globalNames = u.removeItems u.ownKeys(@), @globalNames

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
    
  # Have patches cache the agents currently on them.
  # Optimizes Patch p.agentsHere method
  setCacheAgentsHere: -> @patches.cacheAgentsHere()
  
  # Have agents cache the links with them as a node.
  # Optimizes Agent a.myLinks method
  setCacheMyLinks: -> @agents.cacheLinks()
  
  # Have patches cache the given patchRect.
  # Optimizes patchRect, inRadius and inCone
  setCachePatchRect:(radius,meToo=false)->@patches.cacheRect radius,meToo
  
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
  start: -> u.waitOn (=> @modelReady), (=> @anim.start()); @
  stop:  -> @anim.stop()
  # Animate once by `step(); draw()`. For UI and debugging from console.
  # Will advance the ticks/draws counters.
  once: -> @stop() unless @anim.stopped; @anim.once() 

  # Stop and reset the model, restarting if restart is true
  reset: (restart = false) -> 
    console.log "reset: anim"
    @anim.reset() # stop & reset ticks/steps counters
    console.log "reset: contexts"
    (v.restore(); @setCtxTransform v) for k,v of @contexts when v.canvas? # clear/resize b4 agentsets
    console.log "reset: patches"
    @patches = ABM.patches = new ABM.Patches ABM.Patch, "patches"
    console.log "reset: agents"
    @agents = ABM.agents = new ABM.Agents ABM.Agent, "agents"
    @links = ABM.links = new ABM.Links ABM.Link, "links"
    u.s.spriteSheets.length = 0 # possibly null out entries?
    console.log "reset: setup"
    @setup()
    @setRootVars() if @debugging
    @start() if restart

#### Animation.
  
# Call the agentset draw methods if either the first draw call or
# their "refresh" flags are set.  The latter are simple optimizations
# to avoid redrawing the same static scene. Called by animator.
  draw: (force=@anim.stopped) ->
    @patches.draw @contexts.patches  if force or @refreshPatches or @anim.draws is 1
    @links.draw   @contexts.links    if force or @refreshLinks   or @anim.draws is 1
    @agents.draw  @contexts.agents   if force or @refreshAgents  or @anim.draws is 1
    @drawSpotlight @spotlightAgent, @contexts.spotlight  if @spotlightAgent?

# Creates a spotlight effect on an agent, so we can follow it throughout the model.
# Use:
#
#     @setSpotliight breed.oneOf()
#
# to draw one of a random breed. Remove spotlight by passing `null`
  setSpotlight: (@spotlightAgent) ->
    u.clearCtx @contexts.spotlight unless @spotlightAgent?

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
#     @embers.setDefault "color", [255,0,0]
#
# ..will set the default color for just the embers. Note: patch breeds are currently
# not usable due to the patches being prebuilt.  Stay tuned.
  
  createBreeds: (s, agentClass, breedSet) ->
    breeds = []; breeds.classes = {}; breeds.sets = {}
    for b in s.split(" ")
      c = class Breed extends agentClass
      breed = @[b] = # add @<breed> to local scope
        new breedSet c, b, agentClass::breed # create subset agentSet
      breeds.push breed
      breeds.sets[b] = breed
      breeds.classes["#{b}Class"] = c
    breeds
  patchBreeds: (s) -> @patches.breeds = @createBreeds s, ABM.Patch, ABM.Patches
  agentBreeds: (s) -> @agents.breeds  = @createBreeds s, ABM.Agent, ABM.Agents
  linkBreeds:  (s) -> @links.breeds   = @createBreeds s, ABM.Link,  ABM.Links
  
  # Utility for models to create agentsets from arrays.  Ex:
  #
  #     even = @asSet (a for a in @agents when a.id % 2 is 0)
  #     even.shuffle().getProp("id") # [6, 0, 4, 2, 8]
  asSet: (a, setType = ABM.AgentSet) -> ABM.AgentSet.asSet a, setType

  # A simple debug aid which places short names in the global name space.
  # Note we avoid using the actual name, such as "patches" because this
  # can cause our modules to mistakenly depend on a global name.
  # See [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension too.
  debug: (@debugging=true)->u.waitOn (=>@modelReady),(=>@setRootVars()); @
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
    root.an  = @anim
    root.gl  = @globals
    root.dv  = @div
    root.root= root
    root.app = @
