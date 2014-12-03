# This module contains three color areas:
#
# * typedColor: A Uint8 (clamped) r,g,b,a TypedArray
#   with both rgba and pixel views onto the same buffer.
# * Several simple core color primitive functions
# * A color map class and several colormap "factories"
#
# In the functions below, rgb(a) values are ints in 0-255, including a.
# Note a is not in 0-1 as in css colors.
#
# Numeric Typed Arrays are used in canvas's [ImageData pixels](
# https://developer.mozilla.org/en-US/docs/Web/API/ImageData),
# WebGL colors (4 rgba floats in 0-1), and in images.
#
# There are many other representations, such as floats in 0-1 (webgl)
# and odd mixtures of values, some in degrees, some in percentages.
#
# Our typedColors can optionally contain a css string representation.

Color = {
  # ### Typed Color

  # A typed color is a typed array with r,g,b,a in 0-255.
  # Note that a is *not* in 0-1 as in some color formats.
  #
  # Return a 4 element Uint8ClampedArray, with two properties:
  #
  # * pixelArray: A single element Uint32Array view on the Uint8ClampedArray
  # * str: an optional css color string.
  #
  # Any change to the typedColor r,g,b,a elements will dynamically change
  # the pixel value as it is a view onto the same buffer.
  #
  # Setting the pixelArray[0] also dynamically changes all 4 r,g,b,a, values.
  # See [Mozilla Docs](http://goo.gl/3OOQzy)
  typedColor: (r, g, b, a=255, stringToo = true) ->
    # check for missing "a" but existing stringToo
    # i.e. typedColor [r,g,b]...,false
    if typeof a is "boolean"
      stringToo = a
      a = 255
    @checkAlpha "typedCcolor", a
    ta=new Uint8ClampedArray([r, g, b, a])
    ta.pixelArray = new Uint32Array(ta.buffer)
    # Convert r,g,b,a to string.
    # If opaque (a=255), use either #nnn or #nnnnnn hex format,
    # otherwise the rgba(r,g,b,a) with alpha format
    if stringToo # str: legacy name
      ta.str = if a is 255 then @hexString(r,g,b) else @rgbaString(r,g,b,a)
    ta

  # Four getter/setters for typedColors.

  # Get pixel Uint32 from a typedColor. Sugar for color.pixelArray[0].
  # We don't need a getter for r,g,b,a; the color is a Uint8 rgba array.
  # Similarly, the css string is color.str.
  # These are functions rather than properties to insure memory effeciency.
  getPixel: (color) -> color.pixelArray[0]

  # setter for typedColor; including update to color string if present.
  setRgba: (color, r, g, b, a=255) ->
    @checkAlpha "setColor", a
    [color[0], color[1], color[2], color[3]] = [r, g, b, a]
    color.str = @rgbaString(r, g, b, a) if color.str
    color
  # as above, with pixel argument.
  setPixel: (color, pixel) ->
    color.pixelArray[0] = pixel
    color.str = @rgbaString color... if color.str
    color
  # as above, using a css string.
  # Uses string as color.str if color created with stringToo = true
  setString: (color, string) ->
    [color[0], color[1], color[2], color[3]] = @stringToRgba(color)
    color.str = string if color.str

# Utilities for typedColors

  # The conversion to string, used for printing in console
  toString: (color) ->
    [r,g,b,a] = color
    str = color.str
    "[#{[r,g,b,a].toString()}#{if str then "; str:"+str}]"

  # Legacy: Check alpha to be int in 0-255, not float in (0-1].
  # The name is the function, for clearer error message in console.
  checkAlpha: (name, a) ->
    if 0 < a <= 1 # well, 1 *could* be OK, it's in 0-255.
      console.log "#{name}: a=#{a}. Alpha float in (0-1], not int in [0-255]"

  # Legacy: return typed color as a JavaScript array, a in 0-1
  # This was earlier format.
  colorToArray: (color) -> # Legacy, alpha conversion
    [r, g, b, a] = color
    if a is 255 then [r, g, b] else  [r, g, b, a/255]

  # Return typedColor with r,g,b random in 0-255, with default a=255.
  randomColor: -> @typedColor (u.randomInt(256) for i in [0..2])...

# ### Pixel functions.

  # Primitive Rgba<>Pixel manipulation.
  #
  # These use two views onto a 4 byte typed array buffer.
  # Called after Color module exists,
  # see [Stack Overflow](http://goo.gl/qrHXwB)

  sharedPixel: null
  sharedRgba: null
  initSharedPixel: ->
    @sharedPixel = new Uint32Array(1)
    @sharedRgba = new Uint8ClampedArray(@sharedPixel.buffer)

  # Return a single Uint32 pixel, correct endian format.
  rgbaToPixel: (r, g, b, a=255) ->
    uint8 = @sharedRgba # shorter name
    [uint8[0], uint8[1], uint8[2], uint8[3]] = [r, g, b, a]
    @sharedPixel[0]

  # Convert a pixel to the shared rgba uInt8 typed view.
  # Good for computations like finding the pixel r,g,b,a values.
  # Use pixelToColor & pixelToArray below if you need a copy of the shared color
  pixelToRgba: (pixel) ->
    @sharedPixel[0] = pixel
    @sharedRgba

  pixelToArray: (pixel) ->
    @sharedColor.pixelArray[0] = pixel
    new Array(@sharedColor...)

  # Convert a pixel to a new typedColor
  # pixelToColor: (pixel) -> @typedColor(@pixelToUint8(pixel)...)
  pixelToColor: (pixel) -> @typedColor(@pixelToRgba(pixel)...)

# ### CSS Color functions.

  # CSS colors in HTML are strings, see [legal CSS string colors](
  # http://www.w3schools.com/cssref/css_colors_legal.asp)
  # and [Mozilla's Color Reference](
  # https://developer.mozilla.org/en-US/docs/Web/CSS/color_value)
  # as wall as the [future CSS4](http://dev.w3.org/csswg/css-color/) spec.
  #
  # The strings can be may forms:
  #
  # * Names: [140 color case-insensitive names](
  #   http://en.wikipedia.org/wiki/Web_colors#HTML_color_names) like CadetBlue
  # * Hex, short and long form: #0f0, #ff10a0
  # * RGB: rgb(255, 0, 0), rgba(255, 0, 0, 0.5)
  # * HSL: hsl(120, 100%, 50%), hsla(120, 100%, 50%, 0.8)

  # Convert 3 r,g,b ints in [0-255] to a css color string.
  # Alpha "a" is int in [0-255], allowing destructuring of typedColor
  rgbaString: (r, g, b, a=255) ->
    @checkAlpha "rgbaString", a
    a = a/255; a4 = a.toPrecision(4)
    if a is 1 then "rgb(#{r},#{g},#{b})" else "rgba(#{r},#{g},#{b},#{a4})"

  # Convert 3 ints, h in [0-360], s,l in [0-100]% to a css color string.
  # Alpha "a" is int in [0-255].
  #
  # Note h=0 and h=360 are the same, use h in 0-359 for unique colors.
  hslString: (h, s, l, a=255) ->
    @checkAlpha "hslString", a
    a = a/255; a4 = a.toPrecision(4)
    if a is 1 then "hsl(#{h},#{s}%,#{l}%)" else "hsla(#{h},#{s}%,#{l}%,#{a4})"

  # Return a web/html/css hex color string for an r,g,b color.
  # Identical color will be drawn as if using rgbaString above
  # but without an alpha capability.
  # Default is to check for the short hex form: #nnn.
  hexString: (r, g, b, checkShort = true) ->
    [r0, g0, b0] = [r/17, g/17, b/17]
    if checkShort and u.isInteger(r0) and u.isInteger(g0) and u.isInteger(b0)
      return @hexShortString r0, g0, b0
    "#" + (0x1000000 | (b | g << 8 | r << 16)).toString(16).slice(-6)
  # Return the 4 char short version of a hex color.  Each of the r,g,b values
  # must be in [0-15].  The resulting color will be equivalent
  # to r*17, g*17, b*17, resulting in the values:
  #
  #     0, 17, 34, 51, 68, 85, 102, 119, 136, 153, 170, 187, 204, 221, 238, 255
  #
  # This is equivalent u.aRamp(0,255,16), i.e. 16 values per rgb channel.
  hexShortString: (r, g, b) ->
    if (r>15) or (g>15) or (b>15)
      u.error "hexShortString: one of #{[r,g,b]} > 15"
    "#" + r.toString(16) + g.toString(16) + b.toString(16)

  # Return 4 element rgba Array given any legal CSS string color
  # [legal CSS string color](
  # http://www.w3schools.com/cssref/css_colors_legal.asp)
  #
  # Legal strings vary widely: CadetBlue, #0f0, rgb(255,0,0), hsl(120,100%,50%)
  #
  # Note: The browser speaks for itself: we simply set a 1x1 canvas fillStyle
  # to the string and create a pixel, returning the r,g,b,a typedColor
  # Odd results if string is not recognized by browser.
  sharedCtx1x1: u.createCtx 1, 1 # share across calls.
  stringToRgba: (string) ->
    string = string.toLowerCase()
    @sharedCtx1x1.clearRect 0, 0, 1, 1 # is this needed?
    @sharedCtx1x1.fillStyle = string
    @sharedCtx1x1.fillRect 0, 0, 1, 1
    string = string.replace(/\ */g, '') # "\ " a coffee disambiguation problem
    [r, g, b, a] = @sharedCtx1x1.getImageData(0, 0, 1, 1).data
    [r, g, b, a]
  stringToColor: (string) -> @typedColor @stringToRgba(string)...

  # Similarly, ask the browser to use the canvas gradient feature
  # to create nColors given the gradient color stops and locs.
  # This is a really powerful technique, see:
  #
  # * [Mozilla Gradient Doc](
  #   https://developer.mozilla.org/en-US/docs/Web/CSS/linear-gradient)
  # * [Colorzilla Gradient Editor](
  #   http://www.colorzilla.com/gradient-editor/)
  # * [GitHub ColorMap Project](
  #   https://github.com/bpostlethwaite/colormap)
  gradientRgbaArray: (nColors, stops, locs) ->
    locs = (i/(stops.length-1) for i in [0...stops.length]) if not locs?
    ctx = u.createCtx nColors, 1
    grad = ctx.createLinearGradient 0, 0, nColors, 0
    for i in [0...stops.length]
      grad.addColorStop locs[i], @rgbaString(stops[i]...)
    ctx.fillStyle = grad
    ctx.fillRect 0, 0, nColors, 1
    id = u.ctxToImageData(ctx).data
    ( [ id[i], id[i+1], id[i+2], id[i+3] ] for i in [0...id.length] by 4)
  # gradientColorArray: (nColors, stops, locs) ->
  #   (@typedColor rgba for rgba in @gradientRgbaArray nColors, stops, locs)

# ### Color Conversion and Scaling Functions.

  # Return the gray/intensity float value for a given r,g,b color
  # Use Math.round to convert to 0-255 int for gray color value.
  # [Good post on image filters](
  # http://www.html5rocks.com/en/tutorials/canvas/imagefilters/)
  rgbIntensity: (r, g, b) -> 0.2126*r + 0.7152*g + 0.0722*b

  # RGB <> HSL (Hue, Saturation, Lightness) conversions.
  #
  # r,g,b are ints in [0-255], i.e. 3 unsigned bytes of a pixel.
  # h int in [0-360] degrees; s,l ints [0-100] percents; (h=0 same as h=360)
  # See [Wikipedia](http://en.wikipedia.org/wiki/HSV_color_space)
  # and [Blog Post](
  # http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c)
  #
  # This is a [good table of hues](
  # http://dev.w3.org/csswg/css-color/#named-hue-examples)
  # and this is the [W3C HSL standard](
  # http://www.w3.org/TR/css3-color/#hsl-color)
  #
  # Note that HSL is [not the same as HSB/HSV](
  # http://en.wikipedia.org/wiki/HSL_and_HSV)

  # Convert r, g, b to [h, s, l] Array.
  rgbToHsl: (r, g, b) ->
    r = r/255; g = g/255; b = b/255
    max = Math.max(r,g,b); min = Math.min(r,g,b)
    sum = max + min; diff = max - min
    l = sum/2 # lightness is the average of the largest and smallest rgb's
    if max is min
      h = s = 0 # achromatic, a shade of gray
    else
      s = if l > 0.5 then diff/(2-sum) else diff/sum
      switch max
        when r then h = ((g - b) / diff) + (if g < b then 6 else 0)
        when g then h = ((b - r) / diff) + 2
        when b then h = ((r - g) / diff) + 4
    [Math.round(360*h/6), Math.round(s*100), Math.round(l*100)]

  # Convert h,s,l to r,g,b Array via stringToRgba.
  hslToRgb: (h, s, l) ->
    str = @hslString(h, s, l)
    @stringToRgba(str).slice(0,3)

  # Return a [distance metric](
  # http://www.compuphase.com/cmetric.htm) between two colors.
  # Max distance is roughly 765 (3*255), between black & white.
  rgbDistance: (r1, g1, b1, r2, g2, b2) ->
    rMean = Math.round( (r1 + r2) / 2 )
    [dr, dg, db] = [r1 - r2, g1 - g2, b1 - b2]
    Math.sqrt (((512+rMean)*dr*dr)>>8) + (4*dg*dg) + (((767-rMean)*db*db)>>8)

  # A very crude way to scale a data value to an rgb color.
  # value is in [min max], rgb's are two colors.
  # See ColorMap.scaleColor for preferred method
  rgbLerp: (value, min, max, rgb1, rgb0 = [0,0,0]) ->
    scale = u.lerpScale value, min, max #(value - min)/(max - min)
    (Math.round(u.lerp(rgb0[i], rgb1[i], scale))) for i in [0..2]

  # ### Color Maps

  # A colormap is an array of colors. Maps are extremely useful:
  #
  # * Performance: Maps are created once, reducing the calls to primitives
  #   whenever a color is changed.
  # * Space Effeciency: They *vastly* reduce the number of colors used.
  # * Data: Their index provides a MatLab/NumPy/NetLogo "color as data" feature.
  #   Ex: "Heat" may be mapped to a gradient from green to red.
  #
  # There are two types of colormaps:
  #
  # * ColorMap: composed of typedColors with several methods.
  # * PrimitiveMap: composed of strings or pixel primitive colors.
  #
  # And you can simply make your own array of colors, works fine.

  ColorMap: class ColorMap extends Array
    # A colormap is an array of typedColors with an optional index.
    # The index will be the rgb/rgba color strings and color strings ("red")
    # if the input colorsArray has string entries.
    #
    # Each typedColor is given two additional properties:
    # ix, the array index, and map, the colormap.
    #
    # The ctor takes either an integer (RGB color cube size), or an array
    # of css strings, pixels or color arrays which may be:
    #
    # The value of "type" can be:
    #
    # * "array": Use typedColor Uint8 array
    # * "pixel": Use a 32 bit pixel
    # * "string": Use a css sstring
    #
    # * A [r,g,b,a=255] 3 or 4 element array, a defaulting to opaque.
    # * A typedColor.
    #
    #
    # If color cube size, it is converted into an array of [r, g, b] values.
    #
    # Note we do not check for duplicates.  Dups are often useful.
    # Ex: For a name colormap, there are 2 dups in the legal 140 names.
    # If keeping an index, you want the name dups.
    #
    # The resulting color map array will generally be typed arrays, but
    # if useNative is true and the input array is pixels or strings, they
    # will be used for the color values.

    constructor: (colorsArray, indexToo = false) ->
      super(0)
      # We also keep an index for rapid lookup of a color within the map.
      # It will always have the rgb string for the color.  It can also have
      # values such as the color name (green) or other string values.
      @index = {} if indexToo
      if typeof colorsArray is "number"
        @cube = colorsArray
        colorsArray = Color.permuteColors @cube
      @appendColor color for color in colorsArray

    # Append a color to the the map. If index object exists
    # keep an index by rgb string and the color if it is a string.
    # Return the typedColor.
    appendColor: (color, useNative) ->
      typedColor =
        if color.buffer then color # typedColor
        else if u.isArray color then Color.typedColor color... # rgb(a) array
        else if u.isString color then Color.stringToColor color # css string
        else if typeof color is "number" then Color.pixelToColor color # pixel
        else u.error "ColorMap: bad color = #{color}"
      typedColor.ix = @length
      typedColor.map = @
      @push typedColor
      if @index
        str = typedColor.str ? Color.rgbaString typedColor...
        @index[ typedColor.str ] = typedColor if typedColor.str
        if u.isString color
          @index[ color ] = typedColor
          @index[ color.toLowerCase() ] = typedColor
      typedColor

    # Use Array.sort, augmented by updating color.ix to correspond
    # to the new position in the array
    sort: (compareFcn) ->
      super compareFcn
      color.ix = i for color, i in @
      @

    # Return an random color or index in a map.
    randomIndex: -> u.randomInt @length
    randomColor: -> @[@randomIndex()]

    # Return the map index or color proportional to the value between min, max.
    # This is a linear interpolation based on the map indices.
    # The optional minColor, maxColor args are for using a subset of the map.
    scaleIndex: (number, min, max, minColor = 0, maxColor = @length-1) ->
      scale = u.lerpScale number, min, max # (number-min)/(max-min)
      Math.round(u.lerp minColor, maxColor, scale)
    scaleColor: (number, min, max, minColor = 0, maxColor = @length-1) ->
      @[@scaleIndex number, min, max, minColor, maxColor]

    # Get an exact rgb color in the map, return undefined if not in map.
    # First trys the index if it exists, then enumerates based on pixel.
    getRgb: (r, g, b, a=255) ->
      return @index[ Color.rgbaString(r, g, b, a) ] if @index
      pixel = Color.rgbaToPixel(r, g, b, a)
      i = u.firstOneOf @, (color) -> color.pixelArray[0] is pixel
      if i is -1 then undefined else @[i]

    # Find closest value in an RGB color cube by direct lookup in cube.
    # Much faster than more general findClosest.
    getClosestRgbCube: (r, g, b, itemsPerChannel) ->
      step = 255/(itemsPerChannel-1)
      [rLoc, gLoc, bLoc] = (Math.round(color/step) for color in [r, g, b])
      i = rLoc + gLoc*itemsPerChannel + bLoc*itemsPerChannel*itemsPerChannel
      @[i]

    # Find the color closest to this color, using Color.rgbDistance.
    # Note: slow for large maps unless color cube or in index or exact match.
    findClosest: (r, g, b) -> # alpha not in rgbDistance function
      return color if ( color = @getRgb(r, g, b) )
      return @getClosestRgbCube r, g, b, @cube if @cube
      minDist = Infinity
      ixMin = 0
      for color, i in @
        [r0, g0, b0] = color
        d = Color.rgbDistance r0, g0, b0, r, g, b
        if d < minDist
          minDist = d
          ixMin = i
      @[ixMin]

  # Utilities for creating color maps, inspired [by this repo](
  # https://github.com/bpostlethwaite/colormap).

  # Utility to permute 3 arrays.
  #
  # * If any arg is array, no change made.
  # * If any arg is 1, replace with [max].
  # * If any arg is n>1, replace with u.aIntRamp(0,max,n).
  #
  # Resulting array is an array of arrays of len 3 permuting A1, A2, A3
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

  # Convert array of colors to a native colortype.  Input array
  # elements can be rgba array, typedColor, css string or pixel.
  # The type parameter is one of:
  #
  # * "typed" for typedColors
  # * "string" for css strings
  # * "pixel" for 32bit integer pixel

  # Convert an array to one of the other types. The array can be
  # either a typedColor Uint8 array or a JS r,g,b,a=255 array.
  convertArray: (rgba, type) ->
    isTyped = rgba.buffer?
    return switch type
      when "typed"
        if isTyped then rgba else @typedColor rgba...
      when "string" # note typedColors don't have to have str so test str?
        rgba.str ? @rgbaString rgba...
      when "pixel"
        if isTyped then @getPixel rgba else @rgbaToPixel rgba...
      else u.error "convertColors: unknown color type: #{type}"
  convertColor: (color, type) ->
    return @convertArray(color, type) if u.isArray(color) or color.buffer
    # only pixels and strings left
    isPixel = u.isInteger color
    rgba = if isPixel then @pixelToColor color else @stringToRgba color
    convertArray rgba, type
    # return switch type
    #   when "typed"
    #     if isPixel then @pixelToColor color else @typedColor rgba...
    #   when "string"
    #     rgba.str ? @rgbaString rgba...
    #   when "pixel"
    #     if isTyped then @getPixel rgba else @rgbaToPixel rgba...
    #   else u.error "convertColors: unknown color type: #{type}"


  # convertColor: (color, type = "typed") ->
  #   if u.isArray color
  #   switch type
  #     when "typed"
  #       break if color.buffer
  #       if u.isNumber color then @typedColor @pixelToRgba
  #       else if
  #   if (color.buffer and type is "typed")
  #     return color if
  #   newColor = if type is "typed"
  #     (a) -> @typedColor a... if not a.
  #   else if type is "string"
  #     (a) -> @rgbaString a...
  #   else if type is "pixel"
  #     (a) -> @rgbaToPixel
  #   else
  #     u.error "convertColors: unknown color type"
  #
  # convertColors: (array, type = "typed") ->
  #   f = null
  #
  #   f = if type is "typed"
  #     (a) -> @typedColor a... if not a.
  #   else if type is "string"
  #     (a) -> @rgbaString a...
  #   else if type is "pixel"
  #     (a) -> @rgbaToPixel
  #   else
  #     u.error "convertColors: unknown color type"
  #
  #   return array if f is null
  #   (f(a) for a in array)

  # Create a gray map of gray values (gray: r=g=b)
  # These are typically 256 entries but can be smaller
  # by passing a size parameter.
  grayColorMap: (size = 256) ->
    new ColorMap ( [i,i,i] for i in u.aIntRamp 0, 255, size )

  # Create a colormap by rgb values. R, G, B can be either a number,
  # the number of steps beteen 0-255, or an array of values to use
  # for the color.  Ex: R = 3, corresponds to [0, 128, 255]
  # The resulting map permutes the R, G, V values.  Thus if
  # R=G=B=4, the resulting map has 4*4*4=64 colors.
  rgbColorMap: (R, G=R, B=R) ->
    if (typeof R is "number") and (R is G is B)
      new ColorMap R # lets ColorMap know its a color cube
    else
      new ColorMap @permuteColors(R, G, B)

  # Create an hsl map, inputs similar to above.  Convert the
  # HSL values to RGB, default to bright hue ramp.
  hslColorMap: (H, S=1, L=1) ->
    hslArray = @permuteColors(H, S, L, [359,100,50])
    rgbArray = (@hslToRgb a... for a in hslArray)
    new ColorMap rgbArray

  gradientColorMap: (nColors, stops, locs) ->
    new ColorMap @gradientRgbaArray(nColors, stops, locs)

  # Create a color map via the 140 html standard colors
  # or any of the other forms of css color strings.
  # The input is an array of strings (no nameColorArray fcn needed!)
  nameColorMap: (strings) ->
    new ColorMap strings

  # Create a color map via an array of pixels
  pixelColorMap: (pixels) ->
    if typeof pixels[0] isnt "number"
      pixels = ( rgbaToPixel rgba... for rgba in rgbas )
    new ColorMap pixels

  # Create a map with a random set of colors.
  # Sometimes useful to sort by intensity afterwards.
  randomColorMap: (nColors) ->
    new ColorMap (@randomColor() for i in [0...nColors])

  # Create alpha map of the given base r,g,b color,
  # with nOpacity opacity values, default to all 256
  alphaColorMap: (rgb, nOpacities = 256) ->
    ( u.clone(rgb).push a for a in u.aIntRamp 0, 255, nOpacities )
    new ColorMap @alphaColorArray rgb, nOpacities

};
Color.initSharedPixel() # Initialize  the shared buffer pixel/rgb view

# Here are the 140 case insensitive legal color names (the X11 set)
# To include them in your model, use:
#
#     namedColorString = "AliceBlue AntiqueWhite Aqua Aquamarine Azure Beige Bisque Black BlanchedAlmond Blue BlueViolet Brown BurlyWood CadetBlue Chartreuse Chocolate Coral CornflowerBlue Cornsilk Crimson Cyan DarkBlue DarkCyan DarkGoldenRod DarkGray DarkGreen DarkKhaki DarkMagenta DarkOliveGreen DarkOrange DarkOrchid DarkRed DarkSalmon DarkSeaGreen DarkSlateBlue DarkSlateGray DarkTurquoise DarkViolet DeepPink DeepSkyBlue DimGray DodgerBlue FireBrick FloralWhite ForestGreen Fuchsia Gainsboro GhostWhite Gold GoldenRod Gray Green GreenYellow HoneyDew HotPink IndianRed Indigo Ivory Khaki Lavender LavenderBlush LawnGreen LemonChiffon LightBlue LightCoral LightCyan LightGoldenRodYellow LightGray LightGreen LightPink LightSalmon LightSeaGreen LightSkyBlue LightSlateGray LightSteelBlue LightYellow Lime LimeGreen Linen Magenta Maroon MediumAquaMarine MediumBlue MediumOrchid MediumPurple MediumSeaGreen MediumSlateBlue MediumSpringGreen MediumTurquoise MediumVioletRed MidnightBlue MintCream MistyRose Moccasin NavajoWhite Navy OldLace Olive OliveDrab Orange OrangeRed Orchid PaleGoldenRod PaleGreen PaleTurquoise PaleVioletRed PapayaWhip PeachPuff Peru Pink Plum PowderBlue Purple Red RosyBrown RoyalBlue SaddleBrown Salmon SandyBrown SeaGreen SeaShell Sienna Silver SkyBlue SlateBlue SlateGray Snow SpringGreen SteelBlue Tan Teal Thistle Tomato Turquoise Violet Wheat White WhiteSmoke Yellow YellowGreen"
#     namedColors = namedColorString.split(" ")
