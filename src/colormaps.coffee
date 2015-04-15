# ### Color Maps

# A colormap is an array of colors.  A ColorMapProto Array prototype is provided
# to simplify access to the colormap's colors.
#
# Maps are extremely useful:
#
# * Performance: Maps are created once, reducing the calls to primitives
#   whenever a color is changed.
# * Space Effeciency: They *vastly* reduce the number of colors used.
# * Data: Their index provides a MatLab/NumPy/NetLogo "color as data" feature.
#   Ex: "Heat" may be mapped to a gradient from green to red.

ColorMaps  = {

# ### Color Array Utilities
# Several utilities for creating color arrays

# ### Gradients

  # Ask the browser to use the canvas gradient feature
  # to create nColors given the gradient color stops and locs.
  #
  # Stops are css strings or rgba arrays. Locs are floats from 0-1
  #
  # This is a powerful browser feature, can be
  # used to create all the MatLab colormaps. See these gradient sites:
  # Mozilla [Gradient Doc](
  #   https://developer.mozilla.org/en-US/docs/Web/CSS/linear-gradient),
  # Colorzilla [Gradient Editor](
  #   http://www.colorzilla.com/gradient-editor/),
  # GitHub [ColorMap Project](
  #   https://github.com/bpostlethwaite/colormap)

  gradientImageData: (nColors, stops, locs) ->
    # Convert the color stops to css strings
    stops = (Color.convertColor c, "css" for c in stops)
    # default locations for colors is equally spaced
    locs = u.aRamp 0, 1, stops.length if not locs?
    # create a nColors x 1 canvas context
    ctx = u.createCtx nColors, 1
    # create a new gradient
    # and fill it with the color stops
    grad = ctx.createLinearGradient 0, 0, nColors, 0
    grad.addColorStop locs[i], stops[i] for i in [0...stops.length]
    # draw the gradient
    # returning the image data TypedArray
    ctx.fillStyle = grad
    ctx.fillRect 0, 0, nColors, 1
    u.ctxToImageData(ctx).data

# ### Array Conversion Utilities

  # Convert Uint8Array into Array of 4 element Uint8 subarrays,
  # 4 element JS Arrays, or colors.
  # Useful for converting ImageData objects like gradients to color arrays.
  uint8ArrayToUint8s: (a) ->
    ( a.subarray(i,i+4) for i in [0...a.length] by 4 )
  uint8ArrayToRgbas: (a) ->
    ( [ a[i], a[i+1], a[i+2], a[i+3] ] for i in [0...a.length] by 4 )
  uint8ArrayToColors: (array, type) ->
    return new Uint32Array( array.buffer ) if type is "pixel"
    @arrayToColors(@uint8ArrayToUint8s(array), type)

  # Convert array of colors or rgba arrays to array of colors of given type
  arrayToColors: (array, type) ->
    return array if Color.colorType(array[0]) is type
    array[i] = Color.convertColor(a, type) for a,i in array
    array

  # Utility to permute 3 arrays.
  #
  # * If any arg is array, no change made.
  # * If any arg is 1, replace with [max].
  # * If any arg is n>1, replace with u.aIntRamp(0,max,n).
  #
  # Result is an array of arrays of len 3 permuting A1, A2, A3.
  # Used by rgbColorMap and hslColorMap
  permuteColors: (A1, A2=A1, A3=A2, max=[255,255,255]) ->
    [A1, A2, A3] = for A, i in [A1, A2, A3] # multi-line comprehension
      if typeof A is "number"
        if A is 1 then [max[i]] else u.aIntRamp(0, max[i], A)
      else A
    @permuteArrays A1, A2, A3
  # Permute simple arrays w/o conversions above.
  permuteArrays: (A1, A2=A1, A3=A2) ->
    array = []
    ((array.push [a1,a2,a3] for a1 in A1) for a2 in A2) for a3 in A3
    array

# ### ColorMaps

  # Convert an array of colors to a colormap.
  # Returns the original array, just for convenience.
  colorMap: (array, indexToo = false) ->
    array.__proto__ = @ColorMapProto
    array.init indexToo

  # Use prototypal inheritance for converting array to colormap.
  ColorMapProto: {
    __proto__: Array.prototype
    # Initialize array to be colormap. Create an index object for
    # direct lookup of color in array if indexToo. If color type is "typed"
    # add properties for map and index in map.
    init: (indexToo = false) ->
      @type = Color.colorType @[0]
      @index = {} if indexToo
      u.error "ColorMap type error" unless @type?
      if @type is "typed"
        for color,i in @ then color.ix = i; color.map = @
      @index[ @indexKey(color) ] = i for color,i in @ if @index
      @ # this is just the original array, returned for convenience.

    # Given a color in the map, return the key it uses in the index object.
    # The value will be the array index of the color.
    indexKey: (color) -> # make css strings lower case?
      if @type is "typed" then color.pixel else color
    # Use the indexKey to test two map color's equality.
    colorsEqual: (color1, color2) ->
      @indexKey(color1) is @indexKey(color2)

    # Get a random index or color from this map given the
    # input range, defaults to entire map.
    randomIndex: (start=0, stop=@length) -> u.randomInt2 start, stop
    randomColor: (start=0, stop=@length) -> @[ @randomIndex start, stop ]

    # Use Array.sort, augmented by updating index if present
    # and color.ix for typedColors
    sort: (compareFcn) ->
      Array.prototype.sort.call @, compareFcn
      @index[ @indexKey(color) ] = i for color,i in @ if @index
      color.ix = i for color,i in @ if @type is "typed"
      @

    # Lookup color in map, returning index or undefined if not found
    lookup: (color) ->
      color = Color.convertColor color, @type # make sure color is our type
      return @index[ @indexKey(color) ] if @index
      for c,i in @ then return i if @colorsEqual(color, c)
      undefined

    # Return the map index or color proportional to the value between min, max.
    # This is a linear interpolation based on the map indices.
    # The optional minColor, maxColor args are for using a subset of the map.
    scaleIndex: (number, min=0, max=1, minColor = 0, maxColor = @length-1) ->
      scale = u.lerpScale number, min, max # (number-min)/(max-min)
      Math.round(u.lerp minColor, maxColor, scale)
    scaleColor: (number, min=0, max=1, minColor = 0, maxColor = @length-1) ->
      @[ @scaleIndex number, min, max, minColor, maxColor ]

    # Find the index/color closest to this r,g,b,a.
    # Alpha only used for exact lookup optimization.
    # Note: slow for large maps unless color cube or exact match.
    findClosestIndex: (r, g, b, a=255) -> # alpha not in rgbDistance function
      # convert r to r,g,b,a if g not set
      [r, g, b, a] = Color.colorToArray r unless g?
      # First directly find if rgb cube
      if @cube
        step = 255/(@cube-1)
        [rLoc, gLoc, bLoc] = (Math.round(c/step) for c in [r, g, b])
        return rLoc + gLoc*@cube + bLoc*@cube*@cube
      # Then check if is exact match. Only use of alpha for opacity maps
      return ix if ix = @lookup [r,g,b,a]
      # Finally use color distance to find closest color
      minDist = Infinity; ixMin = 0
      for color, i in @
        [r0, g0, b0] = Color.colorToArray color
        d = Color.rgbDistance r0, g0, b0, r, g, b
        if d < minDist then minDist = d; ixMin = i
      ixMin
    findClosestColor: (r, g, b, a=255) ->  @[ @findClosestIndex r, g, b, a ]
  }

# ### ColorMap Utilities
# Utilities for creating color arrays and associated maps. This is not
# exhaustive, you can follow these examples for your own use.

  # Convert any array of rgb(a) or color values into colormap.
  # Good for converting css names, pixels/image data
  basicColorMap: (array, type="typed", indexToo=false) ->
    array = @arrayToColors array, type
    @colorMap array, indexToo

  # Create a gray map (gray: r=g=b)
  # These are typically 256 entries but can be smaller
  # by passing a size parameter.
  grayColorMap: (size=256, type="typed", indexToo=false) ->
    array = ( [i,i,i] for i in u.aIntRamp 0, 255, size )
    @basicColorMap array, type, indexToo

  # Create a map with a random set of colors.
  # randomColorMap: (nColors, type="typed", indexToo=false) ->
  #   array = (Color.randomRgb() for i in [0...nColors])
  #   @basicColorMap array, type, indexToo

  # Create a colormap by permuted rgb values.
  #
  # R, G, B can be either a number, (the number of steps beteen 0-255),
  # or an array of values to use for the color.
  #
  # Ex: R = 3, corresponds to R = [0, 128, 255]
  #
  # The resulting map permutes the R, G, B values.  Thus if
  # R=G=B=4, the resulting map has `4*4*4=64` colors.
  rgbColorMap: (R, G=R, B=R, type="typed", indexToo=true) ->
    array = @permuteColors(R, G, B)
    array.cube = R if (typeof R is "number") and (R is G is B)
    @colorMap @arrayToColors(array, type), indexToo
  rgbColorCube: (cubeSide, type="typed", indexToo=false) ->
    @rgbColorMap cubeSide, cubeSide, cubeSide, type, indexToo

  # Create an hsl map, inputs similar to above.  Convert the
  # HSL values to typedColors, default to bright hue ramp (L=50).
  hslColorMap: (H, S=1, L=1, type="typed", indexToo=false) ->
    hslArray = @permuteColors(H, S, L, [359,100,50])
    array = (Color.hslString a... for a in hslArray)
    @colorMap @arrayToColors(array, type), indexToo

  # Use gradient to build an rgba array, then convert to colormap.
  # This easily creates all the MatLab colormaps.
  gradientColorMap: (nColors, stops, locs, type="typed", indexToo=false) ->
    id = @gradientImageData(nColors, stops, locs)
    @colorMap @uint8ArrayToColors(id, type), indexToo
  # The most popular MatLab gradient, "jet":
  jetColors: [ [0,0,127], [0,0,255], [0,127,255], [0,255,255],
    [127,255,127], [255,255,0], [255,127,0], [255,0,0], [127,0,0] ]

  # Ramp of a single color from black to color and to white if whiteToo
  # rampStops: (color, whiteToo) ->
  #   if whiteToo then ["black", color, "white"] else ["black", color]
  rampColorMap: (color, width, whiteToo = false) ->
    stops = if whiteToo then ["black", color, "white"] else ["black", color]
    @gradientColorMap width, stops # @rampStops(color, whiteToo)

  # [NetLogo maps](http://ccl.northwestern.edu/netlogo/docs/)
  # are sets of color ramps for the basic colors, but with
  # slightly different r,g,b values designed for good color ballance.
  # They typically go from black to near white shades. We provide
  # an alternative to ramp from black to full color as well.
  netLogoColorMap: (width = 10, whiteToo = true) ->
    @namedColorMap @netLogoColors, width, whiteToo
  cssBasicColorMap: (width=18, whiteToo=false) ->
    @namedColorMap @basicCssColors, width, whiteToo

  namedColorMap: (names, width, whiteToo) ->
    map = []; ramps = {}
    if u.isArray names # convert array of named colors to object of name: name
      o = {}; o[n] = n for n in names; names = o
    for name, color of names
      ramps[name] = @rampColorMap color, width, whiteToo
      map = map.concat ramps[name]
    map = @basicColorMap map
    map[k] = v for k, v of ramps
    # Hack: will remove; helps migration of agent/patch.scaleColor
    map[Color.convertColor k, "css"] = v for k, v of ramps
    map

  # Our basic css named color strings
  basicCssColors: ["gray", "red", "orange", "brown", "yellow", "green", "lime",
    "turquoise", "cyan", "skyblue", "blue", "violet", "magenta", "pink"]
  # Netlogo's basic named colors. NOTE: sky -> skyblue; css legal named color.
  netLogoColors:
    gray: [141, 141, 141],      red: [215, 50, 41]
    orange: [241, 106, 21],     brown: [157, 110, 72]
    yellow: [237, 237, 49],     green: [89, 176, 60]
    lime: [44, 209, 59],        turquoise: [29, 159, 120]
    cyan: [84, 196, 196],       skyblue: [45, 141, 190]
    blue: [52, 93, 169],        violet: [124, 80, 164]
    magenta: [167, 27, 106],    pink: [224, 127, 150]

  # Create opacity map of the given base r,g,b color,
  # with nOpacity opacity values, default to all 256
  opacityColorMap: (rgb, nOpacities = 256, type="typed", indexToo=false) ->
    [r, g, b] = rgb
    array = ( [r, g, b, a] for a in u.aIntRamp 0, 255, nOpacities )
    @colorMap @arrayToColors(array, type), indexToo

  # Create shared maps and utilities
  createSharedMaps: (whiteToo = true) ->
    # A map of all 256 gray colors
    @Gray    = @grayColorMap()
    # A popular rgb map of the best 256 colors
    @Rgb256  = @rgbColorMap(8,8,4)
    # A large 4K color map with good matches for most colors
    @Rgb     = @rgbColorCube(16)
    # The HTML ["web safe colors"](http://websafecolors.info/)
    @Safe    = @rgbColorCube(6)
    # The popular MatLab jet gradient
    @Jet     = @gradientColorMap 256, @jetColors
    # The netlogo map. NetLogo.yellow etc are individual netlogo hue ramps
    @NetLogo = @netLogoColorMap 10
    # Like above but largest < 256 map (252). Does not diminish to white.
    # Ramps.yellow is thus a ramp from black to brightest NetLogo yellow hue
    @NetLogoRamps = @netLogoColorMap 18, false
    @CssRamps     = @cssBasicColorMap 18, false

  # Return random gray/color from a shared map.
  # Colormap colors are immutable, so if you don't want
  # a shared gray/color but one who's color you will change
  # via color.setColor(..), then use clone:
  #
  #     color = ColorMaps.randomColor().clone()
  #     color = ColorMaps.Jet.scaleColor(.5).clone()
  randomGray: (min, max) -> @Gray.randomColor(min, max)
  randomColor: () -> @Rgb256.randomColor()

  # Legacy/Temporary: replace util/patch/agent scaleColor
  scaleColor: (color, number, min=0, max=1) ->
    if color.scaleColor? # colormap ramp
      return color.scaleColor number, min, max
    else if ramp = @CssRamps[Color.convertColor color, "css"]
      return ramp.scaleColor number, min, max
    else
      return @Rgb.findClosestColor Color.rgbLerp(color, number, min, max)
}
ColorMaps.createSharedMaps()
