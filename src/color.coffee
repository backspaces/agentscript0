Color = {
  # Color utilities.

  # Convert 3 or 4 ints to a html/css color string
  rgbString: (r, g, b, a=1) ->
    throw new Error "alpha > 1" if a > 1 # a: 0-1 not 0-255
    if a is 1 then "rgb(#{r},#{g},#{b})" else "rgba(#{r},#{g},#{b},#{a})"

  # Return the gray/intensity value for a given r,g,b color
  rgbIntensity: (r, g, b) -> 0.2126*r + 0.7152*g + 0.0722*b

  # Return a web/html/css hex color string for an r,g,b color
  rgbToHex: (r, g, b) ->
    "#" + (0x1000000 | (b | g << 8 | r << 16)).toString(16).slice(-6)

  # Return 2 typed array colors: a single Uint32 pixel, correct endian format,
  # and a 4 Uint8Array, r,g,b,a255 (i.e. a int in 0-255)
  typedArrayColor: (r, g, b, a=255) ->
    rgba = new Uint8ClampedArray([r, g, b, a])
    pixel = new Uint32Array(rgba.buffer)[0]
    {pixel, rgba}

  # Return an RGB array given any legal CSS color, null otherwise.
  # http://www.w3schools.com/cssref/css_colors_legal.asp
  # The string can be CadetBlue, #0f0, rgb(255,0,0), hsl(120,100%,50%)
  # The rgba/hsla forms ok too, but we don't return the a.
  # Note: The browser speaks for itself: we simply set a 1x1 canvas fillStyle
  # to the string and create a pixel, returning the r,g,b values.
  # Warning: r=g=b=0 can indicate an illegal string.  We test
  # for a few obvious cases but beware of unexpected [0,0,0] results.
  ctx1x1: u.createCtx 1, 1 # share across calls. closure wrapper better?
  stringToRGB: (string) ->
    @ctx1x1.fillStyle = string
    @ctx1x1.fillRect 0, 0, 1, 1
    [r, g, b, a] = @ctx1x1.getImageData(0, 0, 1, 1).data
    return [r, g, b] if (r+g+b isnt 0) or
      (string.match(/^black$/i)) or
      (string in ["#000","#000000"]) or
      (string.match(/rgba{0,1}\(0,0,0/i)) or
      (string.match(/hsla{0,1}\(0,0%,0%/i))
    null

  # Convert rgb color to hsb/hsv color array
  rgbToHsv: (r, g, b) ->
    r=r/255; g=g/255; b=b/255
    max = Math.max(r,g,b); min = Math.min(r,g,b); v = max
    h = 0; d = max-min; s = if max is 0 then 0 else d/max
    if max isnt min then switch max
      when r then h = (g - b) / d + (if g < b then 6 else 0)
      when g then h = (b - r) / d + 2
      when b then h = (r - g) / d + 4
    [Math.round(255*h/6), Math.round(255*s), Math.round(255*v)]

  # Convert hsv back to rgb
  hsvToRgb: (h, s, v) ->
    h=h/255; s=s/255; v=v/255; i = Math.floor(h*6)
    f = h * 6 - i;        p = v * (1 - s)
    q = v * (1 - f * s);  t = v * (1 - (1 - f) * s)
    switch(i % 6)
      when 0 then r = v; g = t; b = p
      when 1 then r = q; g = v; b = p
      when 2 then r = p; g = v; b = t
      when 3 then r = p; g = q; b = v
      when 4 then r = t; g = p; b = v
      when 5 then r = v; g = p; b = q
    [Math.round(r*255), Math.round(g*255), Math.round(b*255)] # floor??

  # Return array of 3 random values in 0-255.  OK for both RGB/HSV
  randomColor: -> (u.randomInt(256) for i in [0..2])

  # Return a distance metric between two colors.
  # Max distance is roughly 765 (3*255), between black & white
  # http://www.compuphase.com/cmetric.htm
  rgbDistance: (r1, g1, b1, r2, g2, b2) ->
    rMean = Math.round( (r1 + r2) / 2 )
    [dr, dg, db] = [r1 - r2, g1 - g2, b1 - b2]
    Math.sqrt (((512+rMean)*dr*dr)>>8) + (4*dg*dg) + (((767-rMean)*db*db)>>8)

  # A very crude way to scale a data value to an rgb color.
  # value is in [min max], rgb's are two color.
  # See ColorMap.scaleColor for another method
  rgbLerp: (value, min, max, rgb1, rgb0 = [0,0,0]) ->
    scale = u.lerpScale value, min, max #(value - min)/(max - min)
    (Math.round(u.lerp(rgb0[i], rgb1[i], scale))) for i in [0..2]

  # Create color object from r,g,b,a
  # Note a between 0-1, not 0-255
  # The object contains many properties relating to
  # the r,g,b,a color:
  #   r, g, b, h, s, v: color integers, 0-255 based
  #   a, a255: alpha, a float in 0-1, a255 integer in 0-255
  #   rgb, hsb: array forms of the two colors
  #   intensity: the gray value for the rgb color
  #   rgba, pixel: typed array values.
  #   rgbString, hexString: two html/css color formats

  # Experimental:
  # Control the number of color features in colorObject.
  # To remove intensity, call options() for a
  # set of all-true options, and turn off the ones you don't need.
  # If all options false, only r,g,b,a remain.
  options: ->
    rgb: true
    hsv: true
    pixel: true
    rgbString: true
    hexString: true
    intensity: true

  colorObject: (r, g, b, a=1, opt=@options()) ->
    o = {r,g,b,a}
    if opt.rgb
      o.rgb = [r, g, b]
    if opt.hsv
      o.hsv = @rgbToHsv r, g, b
      [o.h, o.s, o.v] = o.hsv
    if opt.pixel
      o.a255 = Math.round(a*255)
      {pixel, rgba} = @typedArrayColor r, g, b, o.a255
      [o.pixel, o.rgba] = [pixel, rgba]
    if opt.rgbString
      o.rgbString = @rgbString r, g, b, a
    if opt.hexString
      o.hexString = @rgbToHex r, g, b
    if opt.intensity
      o.intensity = @rgbIntensity r, g, b
    o

  # A colormap is an array of ColorObjects which have two additional
  # properties: map: the colormap and ix: the color's index w/in map
  ColorMap: class ColorMap extends Array
    # A colormap is an array of Color objects. Each ColorObject has
    # two new properties: ix, the array index, and map, the colormap
    # The ctor takes an array of [r,g,b] arrays. See factories above.
    constructor: (rgbArray, @options = Color.options(), @dupsOK = false) ->
      # Note we keep a copy of the color options
      super(0)
      @rgbIndex = {}
      @nameIndex = {}
      for rgb, i in rgbArray
        @addColor rgb...

    # Append a color to the the map if it isn't already
    # in the map unless dupsOK.  Return the color object
    addColor: (r, g, b, a=1) ->
      rgbString = Color.rgbString r, g, b, a
      if not @dupsOK
        color = @rgbIndex[ rgbString ]
        console.log("dup color", color) if color
      if not color
        color = Color.colorObject r, g, b, a, @options
        color.ix = @length
        color.map = @
        @rgbIndex[rgbString] = color
        @push color
      color

    # The Array.sort, augmented by updating color.ix to correspond
    # to the new place in the array
    sort: (f) ->
      super f
      color.ix = i for color, i in @
      @

    # Sugar for sorting by color.key, mainly intensity.
    sortBy: (key, ascenting=true) ->
      compare = (a, b) ->
        if ascenting then a[key]-b[key] else b[key]-a[key]
      @sort compare

    # Find an rgb color in the map, return undefined if not found
    findRGB: (r, g, b, a=1) ->
      @rgbIndex[ Color.rgbString(r, g, b, a) ]

    # Find first color with the given key/value, undefined if not found
    findKey: (key, value) ->
      for color, i in @
        return color if color[key] is value
      undefined

    # Return an random color or index in a map.
    randomIndex: -> u.randomInt @length
    randomColor: -> @[@randomIndex()]

    # Return the map color proportional to the value between min, max.
    # This is a linear interpolation based on the map indices.
    # The optional minColor, maxColor args are for using a subset of the map.
    scaleColor: (number, min, max, minColor = 0, maxColor = @length-1) ->
      scale = u.lerpScale number, min, max # (number-min)/(max-min)
      minColor = minColor.ix if minColor.ix?
      maxColor = maxColor.ix if maxColor.ix?
      index = Math.round(u.lerp minColor, maxColor, scale)
      @[index]

    # Find the color closest to this color, using Color.rgbDistance.
    findClosest: (r, g, b) ->
      return color if ( color = @findRGB(r, g, b) )
      minDist = Infinity
      ixMin = 0
      for color, i in @
        d = Color.rgbDistance color.rgb..., r, g, b
        if d < minDist
          minDist = d
          ixMin = i
      @[ixMin]

  # Utilities for creating color maps.
  # https://github.com/bpostlethwaite/colormap

  # Create a gray map of gray values (gray: r=g=b)
  # The optional size argument is the size of the map for
  # maps that are not all 256 grays.
  intensityArray: (size = 256) ->
    (Math.round(i*255/(size-1)) for i in [0...size])
  grayColorArray: (size = 256) ->
    ([i,i,i] for i in @intensityArray(size))
  grayColorMap: (size = 256, options) ->
    new ColorMap ([i,i,i] for i in @intensityArray(size)), options

  # Utility to create 3 uniform array ramps from 3 number arguments
  # If any arg is array, no change made.
  # If any arg is 1, replace with [255]
  threeArrays: (A1,A2=A1,A3=A1) ->
    # [A1, A2, A3] = ( (if A is 1 then [255] else A) for A in [A1, A2, A3] )
    [A1, A2, A3] = for A in [A1, A2, A3] # multi-line comprehension
      if A is 1 then A = [255]
      if typeof A is "number" then u.aRamp(0, 255, A, true) else A
    [A1, A2, A3]


  # Create a colormap by rgb values. R, G, B can be either a number,
  # the number of steps beteen 0-255, or an array of values to use
  # for the color.  Ex: R = 3, corresponds to [0, 128, 255]
  # The resulting map permutes the R, G, V values.  Thus if
  # R=G=B=4, the resulting map has 4*4*4=64 colors.
  rgbColorArray: (R, G=R, B=R) ->
    [R, G, B] = @threeArrays(R, G, B)
    array=[]; ((array.push [r,g,b] for b in B) for g in G) for r in R
    array
  rgbColorMap: (R, G=R, B=R, options) ->
    new ColorMap @rgbColorArray(R, G, B), options

  # Create an hsb map with n hues, with constant saturation
  # and brightness.
  # hsvColorArray: (nHues=256, s=255, b=255) ->
  #   # (Color.hsvToRgb(i*255/(nHues-1), s, b) for i in [0...nHues])
  #   (@hsvToRgb(i*255/(nHues-1), s, b) for i in [0...nHues])
  hsvColorArray: (H, S=H, V=H) ->
    [H, S, V] = @threeArrays(H, S, V)
    array=[]; ((array.push [h, s, v] for h in H) for s in S) for v in V
    ( (@hsvToRgb a...) for a in array )
  hsvColorMap: (H, S=[255], V=H, options) ->
    new ColorMap @hsvColorArray(H, S, V), options

  # Use the canvas gradient feature to create nColors.
  # This is a really sophisticated technique, see:
  #  https://developer.mozilla.org/en-US/docs/Web/CSS/linear-gradient
  #  http://www.colorzilla.com/gradient-editor/
  #  https://github.com/bpostlethwaite/colormap
  gradientColorArray: (nColors, stops, locs) ->
    locs = (i/(stops.length-1) for i in [0...stops.length]) if not locs?
    ctx = u.createCtx nColors, 1
    grad = ctx.createLinearGradient 0, 0, nColors, 0
    for i in [0...stops.length]
      grad.addColorStop locs[i], @rgbString(stops[i]...)
    ctx.fillStyle = grad
    ctx.fillRect 0, 0, nColors, 1
    id = u.ctxToImageData(ctx).data
    ([id[i], id[i+1], id[i+2]] for i in [0...id.length] by 4)
  gradientColorMap: (nColors, stops, locs, options) ->
    new ColorMap @gradientColorArray(nColors, stops, locs), options

  # Create a color map via the 140 html standard colors.
  # The input is an object of name: [r,g,b] pairs
  nameColorMap: (colorPairs, options) ->
    rgbs = ( v for k, v of colorPairs )
    names = ( k for k, v of colorPairs )
    map = new ColorMap rgbs, options, true
    for color, i in map
      name = names[i]
      # color.name = name # bad idea, named colors can have duplicates
      map.nameIndex[name] = color
      # map.nameIndex[name.toLowerCase()] = color
    map

  # Create a map with a random set of colors.
  # Sometimes useful to sort by intensity afterwards.
  randomColorArray: (nColors) ->
    rand255 = -> u.randomInt(256)
    ([rand255(), rand255(), rand255()] for i in [0...nColors])
  randomColorMap: (nColors, options) ->
    new ColorMap @randomColorArray(nColors), options

};
