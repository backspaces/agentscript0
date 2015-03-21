# This documentation uses Jeremy Ashkenas's
# [docco](http://jashkenas.github.com/docco/) which allows
# [markdown](http://daringfireball.net/projects/markdown/syntax).

# **Util** contains the general utilities for the project. Note that within
# a **Util** function `@` referrs to Util, *not* the global name space.
# Alias: u is an alias for ABM.Util within the agentscript module (not outside)
#
#      u.clearCtx(ctx) is equivalent to
#      ABM.Util.clearCtx(ctx)

Util = util = u = # TODO: "util" deprecated in favor of Util

  # Shortcut for throwing an error.  Good for debugging:
  #
  #     error("wtf? foo=#{foo}") if fooProblem
  error: (s) -> throw new Error s

  # Alert for a deprecated function.
  deprecatedAlert: false
  deprecatedMsgs: []
  deprecated: (s) ->
    if @deprecatedMsgs.length is 0 and @deprecatedAlert
      alert "Deprecated functions, see console.log"
    if @deprecatedMsgs.indexOf(s) < 0
      console.log "DEPRECATED - #{s}"
      @deprecatedMsgs.push s
    null


  # Two max/min int values. One for 2^53, largest int in float64, other for
  # bitwise ops which are 32 bit. See [discussion](http://goo.gl/WpAzT)
  MaxINT: Math.pow(2,53); MinINT: -Math.pow(2,53) # -@MaxINT fails, @ not defined yet
  MaxINT32: 0|0x7fffffff; MinINT32: 0|0x80000000

  # Replacements for Javascript's iffy `typeof` and `instanceof`
  # See [underscore docs](http://underscorejs.org/docs/underscore.html)
  isArray: Array.isArray or # returns a function that is then applied to arg.
    (obj) -> toString.call(obj) is '[object Array]'
  # Can use: !!(obj and obj.constructor and obj.call and obj.apply)
  isFunction: (obj) -> typeof obj is "function"
  # Can use: !!(obj is '' or (obj and obj.charCodeAt and obj.substr))
  isString: (obj) -> typeof obj is 'string' || obj instanceof String
  isInteger: Number.isInteger or # like isArray
    (num) -> Math.floor(num) is num

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
  # Return v to be between min, max via clamping with Math.min/max
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

# ### String Operations

  # Convert camelCase to CamelCase, capitolizing first character
  upperCamelCase: (str) -> str.charAt(0).toUpperCase() + str.substr(1)

# ### Color and Angle Operations
# Our colors are r,g,b,[a] arrays, with an optional color.str HTML
# color string property. The str value is set on the first call to colorStr

  # Return a random RGB or gray color. Array passed to minimize garbage collection
  randomColor: (c = []) ->
    # c.str = null if c.str?
    # c[i] = @randomInt(256) for i in [0..2]
    # c
    @deprecated "Util.randomColor: use ColorMaps.randomColor"
    @error "Util.randomColor: c cannot be exiting color" if c.length isnt 0
    ColorMaps.randomColor()
  # Note: if 2 args passed, assume they're min, max w/ default c
  randomGray: (c = [], min = 64, max = 192) ->
    if arguments.length is 2 then return @randomGray null, c, min
    # c.str = null if c.str?
    # r=@randomInt2 min,max
    # c[i] = r for i in [0..2]
    # c
    @deprecated "Util.randomGray: use ColorMaps.randomGray"
    @error "Util.randomGray: c cannot be exiting color" if c.length isnt 0
    ColorMaps.randomGray(min, max)
  # Random color from a colormap set of r,g,b values.
  # Default is one of 125 (5^3) colors
  randomMapColor: (c = [], set = [0,63,127,191,255]) ->
    @deprecated "Util.randomMapColor: use ColorMaps.randomColor() or similar"
    @error "Util.randomMapColor: c cannot be exiting color" if c.length isnt 0
    ColorMaps.randomColor()
    # @setColor c, @oneOf(set), @oneOf(set), @oneOf(set)
  # randomBrightColor: (c=[]) -> @randomMapColor c, [0,127,255]
  # randomHSBColor: (c=[]) ->
  #   c = @hsbToRgb([@randomInt(51)*5,255,255])
  # Modify an existing rgb or gray color.  Alpha optional, not set if not provided.
  # Modifying an existing array minimizes GC overhead
  setColor: (c, r, g, b, a) ->
    @deprecated "Util.setColor: use the Color/ColorMaps modules"
    if c.setColor? # typedColor
      if c.map
        @error "Util.setColor: cannot modify colormap colors"
      else
        c.setColor r, g, b, a
    else
      c[0] = r; c[1] = g; c[2] = b; c[3] = a if a?
    c
    # c.str = null if c.str?
    # c[0] = r; c[1] = g; c[2] = b; c[3] = a if a?
    # c
  setGray: (c, g, a) ->
    @deprecated "Util.setGray: use the Color/ColorMaps modules"
    @setColor c, g, g, g, a
  # Return new color, c, by scaling each value of the rgb color max.
  scaleColor: (max, s, c = []) ->
    @deprecated "Util.scaleColor: use the Color/ColorMaps modules"
    @error "Util.scaleColor: cannot modify colormap colors"
    ColorMaps.Rgb.findClosestColor Color.rgbLerp(max, s)
    # c.str = null if c.str?
    # c[i] = @clamp(Math.round(val*s),0,255) for val, i in max # [r,g,b] must be ints
    # c
  # Return color with new opacity, result, by scaling a value of rgba.
  scaleOpacity: (rgba, scale, c = @clone(rgba)) ->
    @deprecated "Util.scaleOpacity: use the Color/ColorMaps modules"
    if @isArray rgba
      c[3] = 1 unless c[3]?
      c[3] = @lerp 0, c[3], scale
    else # typed color
      c[3] = @lerp 0, c[3], scale
      if c.map
        c = Color.typedColor c...
      else
        c.setColor c...
    c
    # result.str = null if result.str?
    # if rgba.length == 3
    # then rgba.push(1)
    # result[3] = parseFloat(@clamp((rgba[3]*scale),0,1).toFixed(3))
    # result

  # Return HTML color as used by canvas element.  Can include Alpha
  colorStr: (c) ->
    @deprecated "Util.colorStr: use Color module or typedColor"
    c.css ? Color.arrayToColor c, "css"
    # return s if (s = c.str)?
    # @error "alpha > 1" if c.length is 4 and c[3] > 1
    # c.str = if c.length is 3 then "rgb(#{c})" else "rgba(#{c})"
  # Compare two colors.  Alas, there is no array.Equal operator.
  colorsEqual: (c1, c2) ->
    @deprecated "Util.colorsEqual: use Color/ColorMaps or typedColor.pixel"
    Color.colorsEqual c1, c2
    # c1.toString() is c2.toString()
  # Convert r,g,b to a luminance float value (not color array).
  # Round for 0-255 int for gray color value.
  # [Good post on image filters](http://goo.gl/pE9cV8)
  rgbToGray: (c) ->
    @deprecated "Util.rgbToGray: use Color.rgbIntensity"
    Color.rgbIntensity c...
    # 0.2126*c[0] + 0.7152*c[1] + 0.0722*c[2]
  # RGB <> HSB (HSV) conversions.
  # RGB in [0-255], HSB in [0-1]
  # See [Wikipedia](http://en.wikipedia.org/wiki/HSV_color_space)
  # and [Blog Post](http://goo.gl/7yP4cO)
  rgbToHsb: (c) ->
    @deprecated "Util.rgbToHsb: use extras/rgbToHsl"
    r=c[0]/255; g=c[1]/255; b=c[2]/255
    max = Math.max(r,g,b); min = Math.min(r,g,b); v = max
    h = 0; d = max-min; s = if max is 0 then 0 else d/max
    if max isnt min then switch max
      when r then h = (g - b) / d + (if g < b then 6 else 0)
      when g then h = (b - r) / d + 2
      when b then h = (r - g) / d + 4
    [Math.round(255*h/6), Math.round(255*s), Math.round(255*v)]
  hsbToRgb: (c) ->
    @deprecated "Util.hsbToRgb: use Color.hslToRgb"
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

  # Colormap factories, building a colormap of a particular type

  # Create a colormap by rgb values. R, G, B can be either a number,
  # the number of steps beteen 0-255, or an array of values to use
  # for the color.  Ex: R = 3, corresponds to [0, 128, 255]
  # The resulting map permutes the R, G, V values.  Thus if
  # R=G=B=4, the resulting map has 4*4*4=64 colors.
  rgbMap: (R,G=R,B=R) ->
    @deprecated "Util.rgbMap: use ColorMaps.rgbColorMap or Rgb/Rgb256"
    ColorMaps.rgbColorMap R, G, B
    # R = (Math.round(i*255/(R-1)) for i in [0...R]) if typeof R is "number"
    # G = (Math.round(i*255/(G-1)) for i in [0...G]) if typeof G is "number"
    # B = (Math.round(i*255/(B-1)) for i in [0...B]) if typeof B is "number"
    # map=[]; ((map.push [r,g,b] for b in B) for g in G) for r in R
    # map
  # Create a gray map of all 256 gray values
  grayMap: ->
    @deprecated "Util.grayMap: use ColorMaps.grayColorMap or Gray"
    ColorMaps.Gray
    # ([i,i,i] for i in [0..255])
  # Create an hsb map with n hues, with constant saturation
  # and brightness.
  hsbMap: (n=256, s=255,b=255)->
    @deprecated "Util.hsbMap: use ColorMaps.hslColorMap"
    ColorMaps.hslColorMap n, 1, 1
    # (@hsbToRgb [i*255/(n-1),s,b] for i in [0...n])
  # Use the canvas gradient feature to create nColors.
  # This is a really sophisticated technique, see:
  #  https://developer.mozilla.org/en-US/docs/Web/CSS/linear-gradient
  # gradientMap: (nColors, stops, locs) ->
  #   locs = (i/(stops.length-1) for i in [0...stops.length]) if not locs?
  #   ctx = @createCtx nColors, 1
  #   grad = ctx.createLinearGradient 0, 0, nColors, 0
  #   grad.addColorStop locs[i], @colorStr stops[i] for i in [0...stops.length]
  #   ctx.fillStyle = grad
  #   ctx.fillRect 0, 0, nColors, 1
  #   id = @ctxToImageData(ctx).data
  #   ([id[i], id[i+1], id[i+2]] for i in [0...id.length] by 4)

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

  # Mix the attributes from one object into another
  mixinObject: (destObj, srcObject) ->
    # Get *all* own props, not just enumerable.
    keys = Object.getOwnPropertyNames(srcObject)
    for key in keys
      prop = Object.getOwnPropertyDescriptor(srcObject, key)
      Object.defineProperty(destObj, key, prop)
    destObj
  # Return a copy of an object, with the prototype also set in the copy
  # when the object has a prototype other than Object.prototype
  cloneObject: (obj) ->
    newObj = Object.create(Object.getPrototypeOf(obj))
    @mixinObject newObj, obj
  # Clone a class (a constructor function) including
  # a copied prototype.  This is used when we have multiple
  # models in a page when the prototype has global variables.
  cloneClass: (oldClass, newName) ->
    ctorStr = oldClass.toString().replace(/^/, "var ctor = ")
    if newName
      ctorStr = ctorStr.replace(/function.*(?=\()/, "function #{newName}")
    eval(ctorStr)
    ctor.prototype = @cloneObject(oldClass.prototype)
    ctor
  # Mix the attributes from one class into another;
  # an alternative to prototypal inheritance. Similar to extend, but
  # mixin() knows to copy prototype functions into the prototype
  mixin: (destObj, srcObject) ->
    destObj[key] = srcObject[key] for own key of srcObject
    destProto = Object.getPrototypeOf destObj
    srcProto = Object.getPrototypeOf srcObject
    destProto[key] = srcProto[key] for own key of srcProto
    # destObj.__proto__[key] = srcObject.__proto__[key] for own key of srcObject.__proto__

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

  # Return histogram of numbers or objects in array.
  # f(obj) converts objects to numbers for histogram, defaults to identity.
  # Histogram interval is bin.
  # If f is a string, return histogram of that property in objects.
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

  # Numeric sort, default to ascending. Mutator, see clone above.
  # Works with TypedArrays too
  sortNums: (array, ascending=true) ->
    f = if ascending then (a,b) -> a-b else (a,b) -> b-a
    if array.sort? then array.sort(f) else Array.prototype.sort.call(array, f)



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
  aProp: (array, propOrFn) ->
    if typeof propOrFn is 'function'
    then propOrFn(a) for a in array
    else a[propOrFn] for a in array

  # Return hybred array with object named properties. Good for returning multiple
  # values from a function, and destructured assignment.
  #
  #     a = aToObj [1,2,3,4], ["one", "two", "three", "four"]
  #     a = [1,2,3,4], a.one = 1, .. a.four = 4
  aToObj: (array, names) -> array[n] = array[i] for n,i in names; array

  # Return scalar max/min/sum/avg of numeric array
  # Iterate rather than reduce: work with typed arrays
  aMax: (array) -> v=array[0]; v=Math.max v,a for a in array; v
  aMin: (array) -> v=array[0]; v=Math.min v,a for a in array; v
  aSum: (array) -> v=0; v += a for a in array; v
  aAvg: (array) -> @aSum(array)/array.length
  aMid: (array) -> # mid == median
    array = if array.sort? then @clone array else @typedToJS array
    @sortNums array
    array[Math.floor(array.length/2)]
  aStats: (array) ->
    min = @aMin array
    max = @aMax array
    avg = @aAvg array
    mid = @aMid array
    {min, max, avg, mid}

  # Return array indices for which array value is NaN
  aNaNs: (array) -> (i for v,i in array when isNaN v)

  # Return a range, an array [start..stop] by optional step.
  # If start>stop, use step negative, like -1.
  # All three args can be floats
  # with the usual caveat that floats can be surprising!
  # Warning: if step isn't exact, stop may not be in array.
  aRange: (start, stop, step=1) -> (x for x in [start..stop] by step)
  # Return a "ramp" (array of sorted floats)
  # in [start,stop] (floats) with numItems (positive integer).
  # OK for start>stop. Unlike aRange, this will always
  # include start/stop w/in float accuracy.
  aRamp: (start, stop, numItems) ->
  # Note: start + step*i, where step is (stop-start)/(numItems-1),
  # has float accuracy problems
    ( start + (stop-start)*(i/(numItems-1)) for i in [0...numItems] )
  # Integer version of aRamp, rounding each element
  aIntRamp: (start, stop, numItems) ->
    (Math.round(num) for num in @aRamp start, stop, numItems)



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
  # If lo>hi, scaling is from hi end of range.
  # [Why the name `lerp`?](http://goo.gl/QrzMc)
  lerp: (lo, hi, scale) ->
    scale = @clamp scale, 0, 1
    if lo <= hi then lo + (hi-lo)*scale else lo - (lo-hi)*scale
  # Calculate the lerp scale given a number and a lo/hi pair.
  lerpScale: (number, lo, hi) -> (number-lo)/(hi-lo)
  # Return point interpolated between two points.
  lerp2: (x0, y0, x1, y1, scale) -> [@lerp(x0,x1,scale), @lerp(y0,y1,scale)]
  # Return an array with values in [lo,hi], defaults to [0,1].
  # Note: to have a half-open interval, [lo,hi), try hi=hi-.00009
  normalize: (array, lo = 0, hi = 1) ->
    min = @aMin array; max = @aMax array; scale = 1/(max-min)
    (@lerp(lo, hi, scale*(num-min)) for num in array)
  # Return a Uint8ClampedArray, normalized to [.5,255.5] then round/clamp to [0,255]
  normalize8: (array) -> new Uint8ClampedArray @normalize(array,-.5,255.5)
  normalizeInt: (array, lo, hi) -> (Math.round i for i in @normalize array, lo, hi) # clamp?

  # Binary search:
  # Return array index of item, where array is sorted.
  # if item not found, return index for item for array to remain sorted.
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

  # Convert polar r,theta, theta in radians, to cartesian x,y.
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
    # Don'cha love standards!
    aliases = ["imageSmoothingEnabled", "mozImageSmoothingEnabled", "oImageSmoothingEnabled", "webkitImageSmoothingEnabled", "msImageSmoothingEnabled"]
    for name in aliases when ctx[name]?
      return ctx[name] = smoothing # lets hope the first one works. Sheesh!
    # ctx.imageSmoothingEnabled = smoothing
    # ctx.mozImageSmoothingEnabled = smoothing
    # ctx.oImageSmoothingEnabled = smoothing
    # ctx.webkitImageSmoothingEnabled = smoothing

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
      ctx.fillStyle = color.css ? Color.convertColor color, "css" # @colorStr(color)
      ctx.fillRect 0, 0, ctx.canvas.width, ctx.canvas.height
      ctx.restore()
    else # 3D
      ctx.clearColor color..., 1 # alpha = 1 unless color is rgba
      ctx.clear ctx.COLOR_BUFFER_BIT | ctx.DEPTH_BUFFER_BIT
  # Draw string of the given color at the xy location, in ctx pixel coords.
  # Use setIdentity .. reset if a transform is being used by caller.
  ctxDrawText: (ctx, string, x, y, color, setIdentity = true) ->
    @setIdentity(ctx) if setIdentity
    ctx.fillStyle = color.css # @colorStr color
    ctx.fillText(string, x, y)
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
    ctx1 = @createCtx tw, th
    w = img.width; h = img.height; ihalf = (n) -> Math.ceil n/2
    steps = Math.ceil(@log2( if (w/tw)>(h/th) then (w/tw) else (h/th)) )
    console.log "steps", steps
    if steps <= 1
      ctx1.drawImage img, 0, 0, tw, th
    else
      console.log "img w/h", w, h, "->", ihalf(w), ihalf(h)
      ctx = @createCtx w = ihalf(w), h = ihalf(h); can = ctx.canvas
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
