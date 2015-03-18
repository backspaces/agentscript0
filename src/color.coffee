# Utilities for browser color types: css color strings, 32 bit integer pixels,
# and 4 element Uint8 TypedColors
#
# The rgba values below are ints in 0-255, including a (alpha).
# I.e. a is not in 0-1 as in css colors.
#
# Naming convention: `rgba` or `array` is generally a 3 or 4 element JavaScript
# Array, not a browser color, used for functions taking r,g,b,a=255 values.

Color = {

# ### CSS Color Strings.

  # CSS colors in HTML are strings, see [Mozilla's Color Reference](
  # https://developer.mozilla.org/en-US/docs/Web/CSS/color_value),
  # taking one of 7 forms:
  #
  # * Names: [140 color case-insensitive names](
  #   http://en.wikipedia.org/wiki/Web_colors#HTML_color_names) like
  #   Red, Green, CadetBlue, etc.
  # * Hex, short and long form: #0f0, #ff10a0
  # * RGB: rgb(255, 0, 0), rgba(255, 0, 0, 0.5)
  # * HSL: hsl(120, 100%, 50%), hsla(120, 100%, 50%, 0.8)

  # Convert 4 r,g,b,a ints in [0-255] to a css color string.
  # Alpha "a" is int in [0-255], not float in 0-1
  rgbaString: (r, g, b, a=255) ->
    a = a/255; a4 = a.toPrecision(4)
    if a is 1 then "rgb(#{r},#{g},#{b})" else "rgba(#{r},#{g},#{b},#{a4})"

  # Convert 3 ints, h in [0-360], s,l in [0-100]% to a css color string.
  # Alpha "a" is int in [0-255].
  #
  # Note h=0 and h=360 are the same, use h in 0-359 for unique colors.
  hslString: (h, s, l, a=255) ->
    a = a/255; a4 = a.toPrecision(4)
    if a is 1 then "hsl(#{h},#{s}%,#{l}%)" else "hsla(#{h},#{s}%,#{l}%,#{a4})"

  # Return a web/html/css hex color string for an r,g,b opaque color (a=255)
  #
  # Both #nnn and #nnnnnn forms supported.
  # Default is to check for the short hex form: #nnn.
  hexString: (r, g, b, shortOK=true) ->
    if shortOK
      if u.isInteger(r0=r/17) and u.isInteger(g0=g/17) and u.isInteger(b0=b/17)
        return @hexShortString r0, g0, b0
    "#" + (0x1000000 | (b | g << 8 | r << 16)).toString(16).slice(-6)
  # Return the 4 char short version of a hex color.  Each of the r,g,b values
  # must be in [0-15].  The resulting color will be equivalent
  # to `r*17`, `g*17`, `b*17`, resulting in the values:
  #
  #     0, 17, 34, 51, 68, 85, 102, 119, 136, 153, 170, 187, 204, 221, 238, 255
  #
  # This is equivalent u.aRamp(0,255,16), i.e. 16 values per rgb channel.
  hexShortString: (r, g, b) ->
    if (r>15) or (g>15) or (b>15)
      u.error "hexShortString: one of #{[r,g,b]} > 15"
    "#" + r.toString(16) + g.toString(16) + b.toString(16)

  # This is a hybrid string and generally our default.  It returns:
  #
  # * rgbaString if a not 255 (i.e. not opaque)
  # * hexString otherwise
  # * with the hexShortString if appropriate
  triString: (r, g, b, a=255) ->
    if a is 255 then @hexString(r, g, b, true) else @rgbaString(r, g, b, a)

# ### CSS String Conversions

  # Return 4 element array given any legal CSS string color.
  #
  # Legal strings vary widely: CadetBlue, #0f0, rgb(255,0,0), hsl(120,100%,50%)
  #
  # Note: The browser speaks for itself: we simply set a 1x1 canvas fillStyle
  # to the string and create a pixel, returning the r,g,b,a TypedArray.

  # The shared 1x1 canvas 2D context.
  sharedCtx1x1: u.createCtx 1, 1 # share across calls.
  # Convert css string to TypedArray.
  # If you need a JavaScript Array, use uint8sToRgba below
  stringToUint8s: (string) ->
    # @sharedCtx1x1.clearRect 0, 0, 1, 1 # is this needed?
    @sharedCtx1x1.fillStyle = string
    @sharedCtx1x1.fillRect 0, 0, 1, 1
    @sharedCtx1x1.getImageData(0, 0, 1, 1).data

# ### Pixel Colors.

  # Primitive Rgba <-> Pixel manipulation.
  #
  # These use two views onto a 4 byte TypedArray buffer.
  #
  # initSharedPixel called after Color module object exists,
  # see why at [Stack Overflow](http://goo.gl/qrHXwB)
  sharedPixel: null
  sharedUint8s: null
  initSharedPixel: ->
    @sharedPixel = new Uint32Array(1)
    @sharedUint8s = new Uint8ClampedArray(@sharedPixel.buffer)

  # Convert r,g,b,a to a single Uint32 pixel, correct endian format.
  rgbaToPixel: (r, g, b, a=255) ->
    @sharedUint8s.set [r, g, b, a]
    @sharedPixel[0]

  # Convert a pixel to Uint8s via the shared typed views.
  # sharedOK = true returns the sharedUint8s, useful
  # for one-time computations like finding the pixel r,g,b,a values.
  # Default is to clone the sharedUint8s.
  pixelToUint8s: (pixel, sharedOK = false) ->
    @sharedPixel[0] = pixel
    if sharedOK then @sharedUint8s else new Uint8ClampedArray @sharedUint8s

# ### Color Conversion and Scaling Functions.

  # Return rgb array with 3 random ints in 0-255.
  # Convert to random cssString or pixel via functions above
  # or arrayToColor below
  randomRgb: -> (u.randomInt(256) for i in [0..2])
  # Return random gray color, with intensities in [min,max).
  randomGrayRgb: (min = 0, max = 256) ->
    i = u.randomInt2 min, max
    [i, i, i]

  # Convert Uint8s to Array.
  # Useful after pixelToUint8s, stringToUint8s, hslToRgb.
  # (Use `Array` not `new Array`, better Coffee translation.)
  uint8sToRgba: (uint8s) -> Array uint8s...

  # Return the gray/intensity float value for a given r,g,b color.
  # Round to 0-255 int for gray values.
  rgbIntensity: (r, g, b) -> 0.2126*r + 0.7152*g + 0.0722*b

  # Convert h,s,l to r,g,b Uint8 TypedArray
  hslToRgb: (h, s, l) ->
    str = @hslString(h, s, l)
    @stringToUint8s(str).subarray(0,3) # a 3 byte view onto the 4 byte buffer.

  # Return a [distance metric](
  # http://www.compuphase.com/cmetric.htm) between two colors.
  # Max distance is roughly 765 (3*255), for black & white.
  rgbDistance: (r1, g1, b1, r2, g2, b2) ->
    rMean = Math.round( (r1 + r2) / 2 )
    [dr, dg, db] = [r1 - r2, g1 - g2, b1 - b2]
    Math.sqrt (((512+rMean)*dr*dr)>>8) + (4*dg*dg) + (((767-rMean)*db*db)>>8)

  # Scale a data value to an rgb color.
  # Value is in [min max], rgb's are two JS arrays.
  #
  # See ColorMap's scaleColor for related scaling method and
  # gradientColorMap for complex, MatLab-like, gradients.
  rgbLerp: (rgb1, value, min = 0, max = 1, rgb0 = [0,0,0]) ->
    scale = u.lerpScale value, min, max #(value - min)/(max - min)
    (Math.round(u.lerp(rgb0[i], rgb1[i], scale)) for i in [0..2])

# ### Typed Color
# A typedColor is a 4 element Uint8ClampedArray, with two properties:
#
# * pixelArray: A single element Uint32Array view on the Uint8ClampedArray
# * string: an optional, lazy evaluated, css color string.
#
# TypedColors are used in canvas's [ImageData pixels](
# https://developer.mozilla.org/en-US/docs/Web/API/ImageData),
# WebGL colors (4 rgba floats in 0-1), and in images.

  typedColor: do () -> # IIFE returns typedColor function.
    # Return a 4 element typedColor.
    #
    # Any change to the typedColor r,g,b,a elements will dynamically change
    # the pixel value as it is a view onto the same buffer, and vice versa.
    # See Mozilla [TypedArray Docs](http://goo.gl/3OOQzy).
    # If r is not a number but a TypedArray, use it for the typedColor.
    typedColor = (r, g, b, a=255, map, index) ->
      # Experimental: The map & index are for possible colormap use.
      if map # assume Uint8ClampedArray rgba array
        ua = map.subarray index*4, index*4 + 4
        ua.set [r,g,b,a]
      else
        ua = if r.buffer then r else new Uint8ClampedArray([r,g,b,a])
      ua.pixelArray = new Uint32Array(ua.buffer, ua.byteOffset, 1)
      # Make this an instance of TypedColorProto
      ua.__proto__ = TypedColorProto
      ua

    # Prototypal Inheritance: TypedColorProto has an Uint8ClampedArray
    # prototype. This allows TypedArrays to have prototype setters/getters,
    # including Object.defineProperties without enlarging the typedColor.
    TypedColorProto = {
      # Set TypedColorProto prototype to Uint8ClampedArray's prototype
      __proto__: Uint8ClampedArray.prototype
      # Set the TypedArray; no need for getColor, it *is* the typed Uint8 array
      setColor: (r,g,b,a=255) ->
        @string = null if @string # will be lazy evaluated via getString.
        @[0]=r; @[1]=g; @[2]=b; @[3]=a
        @
      # Set the pixel view, changing the shared array (Uint8) view too
      setPixel: (pixel)->
        @string = null if @string # will be lazy evaluated via getString.
        @pixelArray[0]=pixel
      # Get the pixel value
      getPixel: -> @pixelArray[0]
      # Set pixel/rgba values to equivalent of the css string.
      #
      # Does *not* set the chached @string, which will be lazily evaluated
      # to its triString. This lets the typedColor remain small without the
      # color string until required by its getter.
      #
      # Note if you set string to "red" or "rgb(255,0,0)", the resulting
      # css string will return the triString #f00 value.
      setString: (string) ->
        @setColor(Color.stringToUint8s(string)...)
      # Return the triString for this typedColor, cached in the @string value
      getString: () ->
        @string = Color.triString(@...) unless @string?
        @string
    }
    # Experiment: Sugar for converting getter/setters into properties.
    # Frequent rgba property setter very poor performance due to GC overhead.
    # These are in TypedColorProto, not in the typedColor,
    # thus shared and take no space in the color itself.
    Object.defineProperties TypedColorProto,
    # pixel: get/set typedColor.pixelArray[0] via pixel property
      pixel:
        get: -> @pixelArray[0]
        set: (val) -> @setPixel(val)
        enumerable: true # make visible in stack trace, remove after debugging
    # rgba: set Uint8 values via JavaScript or TypedArray. Getter not needed.
      rgba:
        get: -> @ #.. not needed, already array
        set: (val) -> @setColor(val...) # beware! array GC slows this down.
        enumerable: true # make visible in stack trace, remove after debugging
    # css: get/set typedColor.str via @string property. Updates TypedArrays.
      css:
        get: -> @getString()
        set: (val) -> @setString(val)
        enumerable: true # make visible in stack trace, remove after debugging
    # str: Legacy usage, identical to css getter property, will remove asap
      str:
        get: -> @getString()
        enumerable: true # make visible in stack trace, remove after debugging
    typedColor

# ### Color Types
#
# Utilities for color types: css, pixel, typed

  # Return the color type of a given color, null if not a color.
  # null useful for testing if color *is* a color.
  colorType: (color) ->
    if color.pixelArray  then return "typed"
    if u.isString color  then return "css"
    if u.isInteger color then return "pixel"
    null
  # Return new color of the given type, given an r,g,b,(a) array,
  # where a defaults to opaque (255).
  # The array can be a JavaScript Array, a TypedArray, or a TypedColor.
  # Use randomRgb & randomGrayRgb arrays to create random valid colors.
  arrayToColor: (array, type = "typed") ->
    switch type
      when "css"   then return @triString array...
      when "pixel" then return @rgbaToPixel array...
      when "typed"
        return if array.buffer then @typedColor array else @typedColor array...
    u.error "arrayToColor: incorrect type: #{type}"
  # Return rgba array (either typed or Array) representing the color.
  colorToArray: (color) ->
    switch @colorType(color)
      when "css"   then return @stringToUint8s color
      when "pixel" then return @pixelToUint8s color
      when "typed" then return color # already a (typed) array
    return color if u.isArray(color) or color.buffer
    u.error "colorToArray: bad color: #{color}"
  # Given a color or rgba array and a type, return color of that type.
  # Return color if color is already of type.
  convertColor: (color, type) ->
    type0 = @colorType(color)
    return color if type0 is type and type isnt "css" # convert to triColor
    return color[type] if type0 is "typed"
    @arrayToColor(@colorToArray(color), type)
  rgbaToColor: (r, g, b, a=255, type="typed") ->
    switch type
      when "css"   then return @triString r,g,b,a
      when "pixel" then return @rgbaToPixel r,g,b,a
      when "typed" then return @typedColor r,g,b,a
    u.error "rgbaToColor: incorrect type: #{type}"
  # Return true if two colors result in the same color
  # Colors can be of different type:
  #
  #    Color.colorsEqual("red", [255,0,0]) returns `true`
  colorsEqual: (color1, color2) ->
    @convertColor(color1, "pixel") is @convertColor(color2, "pixel")
};
Color.initSharedPixel() # Initialize the shared buffer pixel/rgb view

# Here are the 140 case insensitive legal color names (the X11 set)
# To include them in your model, use:
#
#     namedColors = "AliceBlue AntiqueWhite Aqua Aquamarine Azure Beige Bisque Black BlanchedAlmond Blue BlueViolet Brown BurlyWood CadetBlue Chartreuse Chocolate Coral CornflowerBlue Cornsilk Crimson Cyan DarkBlue DarkCyan DarkGoldenRod DarkGray DarkGreen DarkKhaki DarkMagenta DarkOliveGreen DarkOrange DarkOrchid DarkRed DarkSalmon DarkSeaGreen DarkSlateBlue DarkSlateGray DarkTurquoise DarkViolet DeepPink DeepSkyBlue DimGray DodgerBlue FireBrick FloralWhite ForestGreen Fuchsia Gainsboro GhostWhite Gold GoldenRod Gray Green GreenYellow HoneyDew HotPink IndianRed Indigo Ivory Khaki Lavender LavenderBlush LawnGreen LemonChiffon LightBlue LightCoral LightCyan LightGoldenRodYellow LightGray LightGreen LightPink LightSalmon LightSeaGreen LightSkyBlue LightSlateGray LightSteelBlue LightYellow Lime LimeGreen Linen Magenta Maroon MediumAquaMarine MediumBlue MediumOrchid MediumPurple MediumSeaGreen MediumSlateBlue MediumSpringGreen MediumTurquoise MediumVioletRed MidnightBlue MintCream MistyRose Moccasin NavajoWhite Navy OldLace Olive OliveDrab Orange OrangeRed Orchid PaleGoldenRod PaleGreen PaleTurquoise PaleVioletRed PapayaWhip PeachPuff Peru Pink Plum PowderBlue Purple Red RosyBrown RoyalBlue SaddleBrown Salmon SandyBrown SeaGreen SeaShell Sienna Silver SkyBlue SlateBlue SlateGray Snow SpringGreen SteelBlue Tan Teal Thistle Tomato Turquoise Violet Wheat White WhiteSmoke Yellow YellowGreen".split(" ")
#
# NetLogo's 14 base colors names are:
#
#     gray red orange brown yellow green lime turquoise cyan sky blue violet magenta pink
# but do not match exactly the css named colors:
#
#     netLogoColors={gray:[141,141,141], red:[215,50,41], orange:[241,106,21], brown:[157,110,72], yellow:[237,237,49], green:[89,176,60], lime:[44,209,59], turquoise:[29,159,120], cyan:[84,196,196], sky:[45,141,190], blue:[52,93,169], violet:[124,80,164], magenta:[167,27,106], pink:[224,127,150]}
