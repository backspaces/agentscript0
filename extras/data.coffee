# DataSet is an addon for managing data arrays.
#
# DataSets do not need to be the same size as the patch sets. Rather they have
# methods for sampling and creating new datasets of any width/height.
# They also cam set patch variables resampled to the patch width/height.
# Several utilities are provided for creating datasets from Image and
# XmlHTTPRequest inputs, and for drawing into the patch drawing layer.

# Two specific subclasses are provided for Asc GIS elevation data,
# and an image-as-data class.

u = ABM.Util
ABM.DataSet = class DataSet
  # Static members:

  # Create a new dataset using function f on each patch.
  # If f is string, f set to fcn returning p[f]
  @patchDataSet: (f) -> new PatchDataSet f

  # Create a new dataset from an image file name.
  # Note that datasets can be built in two steps:
  # An empty constructor which then can be completed by an
  # async array, Image or XHR response.
  @importImageDataSet: (name, f, format=u.pixelByte(0), arrayType=Uint8ClampedArray, rowsPerSlice) ->
    ds = new ImageDataSet(null, format, arrayType, rowsPerSlice) # empty dataset
    u.importImage name, (img) -> # => not needed
      ds.parse img
      f(ds) if f?
    ds # async: ds will be empty until import finishes

  # Create a new dataset from an Asc GIS file.
  # The parse method converts a string into a dataset. Async
  @importAscDataSet: (name, f) ->
    ds = new AscDataSet() # empty dataset
    u.xhrLoadFile name, "GET", "text", (response) -> # -> OK, closure
      ds.parse response # complete the empty dataset
      f(ds) if f?
    ds # async: ds will be empty until import finishes

  # 2D Dataset: width/height and an array with length = width*height
  constructor: (width=0, height=0, data=[], @model) ->
    @setDefaults()
    @reset width, height, data
  # Reset a dataset to have new width, height and data.  Allows creating
  # an empty dataset and having it filled by another function.
  reset: (@width, @height, @data) ->
    if @data.length isnt @width*@height
      u.error """DataSet: data array length error:
      data.length: #{@data.length} width: #{@width} height: #{@height}
      """
    @
  # Check that x,y are valid coords (floats), from top-left of dataset.
  checkXY: (x,y) ->
    u.error "x,y out of range: #{x},#{y}" unless (0<=x<=@width-1 and 0<=y<=@height-1)

  # Set dataset transform parameters.
  setDefaults: ->
    @useNearest=false
    @crop=false
    @normalizeImage=true
    @alpha=255
    @gray=true
  setSampler: (@useNearest) ->
  setConvolveCrop: (@crop) ->
  setImageNormalize: (@normalizeImage) ->
  setImageAlpha: (@alpha) -> # pixel alpha: [0,255]
  setImageGray: (@gray) ->
  # Set the model to use by default for things like `toPatchVar()`,
  # `toDrawing()`, and `toPatchColors()`.
  setModel: (@model) ->

  # Sample the dataset.
  sample: (x,y) -> if @useNearest then @nearest x,y else @bilinear x,y
  # Sample dataset using nearest neighbor. x,y floats in range
  nearest: (x,y) -> @getXY Math.round(x), Math.round(y)
  # Sample dataset using bilinear (2D) interpolation. x,y floats in range
  bilinear: (x,y) -> # http://en.wikipedia.org/wiki/Bilinear_interpolation
    @checkXY x,y
    x0=Math.floor x; y0=Math.floor y; i=@toIndex x0,y0; w=@width
    # Edge case: If x is width-1, x0 is width-1, x is 0, dx is 1
    x=x-x0; y=y-y0; dx=1-x; dy=1-y
    # Edge case: fij is 0 if beyond data array; undefined -> 0
    # if fij wrap on x, x is 0, dx is 1; return f00*dy+f01*y, linear on y
    f00=@data[i]; f01=@data[i+w] ? 0; f10=@data[++i] ? 0; f11=@data[i+w] ? 0
    f00*dx*dy + f10*x*dy + f01*dx*y + f11*x*y
  # Convert x,y ints to index into data array
  toIndex: (x,y) -> x + y*@width
  # Convert int index into data array into x,y ints
  toXY: (i) -> [i % @width, Math.floor i/@width]
  # Get data at x,y int offset into data array
  getXY: (x,y) -> @checkXY x,y; @data[@toIndex x,y]
  # Set the data and int x,y coord of data array
  setXY: (x,y,num) -> @checkXY x,y; @data[@toIndex x,y] = num
  # Return a printable string for dataset.
  # If p < 0, print data, otherwise use toFixed to truncate to p precision
  toString: (p=2, sep=", ")->
    s = "width: #{@width} height: #{@height} data:"
    data = if p<0 then @data else u.aToFixed @data, p
    for i in [0...@height]
      s += "\n" + "#{i}: #{data.slice i*@width, (i+1)*@width}"
    s.replace /,/g, sep
  # Convert dataset into an image.
  toImage: -> @toContext().canvas
  toContext: ->
    ctx = u.createCtx @width, @height
    idata = ctx.getImageData(0, 0, @width, @height); ta = idata.data
    if @normalizeImage
      data = if @gray then u.normalize8 @data else u.normalizeInt @data, 0, Math.pow(2,24)-1
    else
      data = (Math.round d for d in @data)
    for num, i in data
      j=4*i
      if @gray
        ta[j] = ta[j+1] = ta[j+2] = Math.floor num
        ta[j+3] = @alpha
      else
        ta[j]=(num>>16)&0xff; ta[j+1]=(num>>8)&0xff; ta[j+2]=num&0xff
        ta[j+3] = if @normalizeImage then @alpha else ta[j+3]=(num>>24)&0xff
    ctx.putImageData idata, 0, 0
    ctx
  # Get a data url representing this dataset as an image. Useful for
  # debugging: console.log the data url to the console and open it
  # in a new browser tab for viewing.
  toDataUrl: () -> u.ctxToDataUrl @toContext()
  # Show dataset as image in patch drawing layer or patch colors, return image
  toDrawing: (model = @model) -> model.patches.installDrawing(img=@toImage()); img
  toPatchColors: (model = @model) -> model.patches.installColors(img=@toImage()); img
  # Resample dataset to patch width/height and set named patch variable.
  # Note this "insets" the dataset so the variable is sampled the center of the patch.
  # The dataset can be sampled directly to its edges .. i.e. in agent coords.
  toPatchVar: (name, model = @model) ->
    if (ps=model.patches).length is @data.length
    then p[name] = @data[i] for p,i in ps
    else p[name] = @patchSample p.x, p.y, model for p in ps
    null

  # Sample via transformed coords.
  # x,y is in topleft-bottomright box: [tlx,tly,tlx+w,tly-h]
  coordSample: (x, y, tlx, tly, w, h) -> #brx, bry) ->
    xs=(x-tlx)*(@width-1)/w;  ys=(tly-y)*(@height-1)/h # convert to sample space
    @sample xs,ys
  patchSample: (px, py, model = @model) ->
    w=model.world
    @coordSample px, py, w.minXcor, w.maxYcor, w.numX, w.numY

  # Normalize a dataset to linear interpolation: [min,max] -> [lo, hi], float
  normalize: (lo, hi) -> new DataSet @width, @height, u.normalize(@data, lo, hi), @model
  # Normalize a dataset to clamped Uint8 bytes [0-255]
  normalize8: -> new DataSet @width, @height, u.normalize8(@data), @model
  # Resample dataset to new width, height
  resample: (width, height) ->
    return new DataSet width,height,@data,@model if width is @width and height is @height
    data = []; xScale = (@width-1)/(width-1); yScale = (@height-1)/(height-1)
    for y in [0...height] by 1
      for x in [0...width] by 1
        xs=x*xScale; ys=y*yScale
        data.push @sample xs,ys
    new DataSet width, height, data, @model
  # Return neighbor values of the given x,y of the dataset.
  # Off-edge neighbors revert to nearest edge value.
  neighborhood: (x,y,array=[]) -> # return 3x3 neighborhood
    array.length = 0 # in case user supplied an array
    for dy in [-1..1]
      for dx in [-1..1]
        x0=u.clamp x+dx, 0, @width-1
        y0=u.clamp y+dy, 0, @height-1
        array.push @data[@toIndex x0, y0]
    array
  # Return a new dataset of same size convolved with the given kernel 3x3 matrix.
  # See [Convolution article](http://goo.gl/ubFiji)
  convolve: (kernel,factor=1) -> # Factory: return new convolved dataset
    array = []; n = []
    if @crop
    then x0=y0=1; h=@height-1; w=@width-1
    else x0=y0=0; h=@height; w=@width
    for y in [y0...h] by 1
      for x in [x0...w] by 1
        @neighborhood x,y,n
        array.push u.aSum(u.aPairMul(kernel, n))*factor
    new DataSet w-x0, h-y0, array, @model
  # A few common convolutions.  dzdx/y are also called horiz/vert Sobel
  dzdx: (n=2,factor=1/8) -> @convolve([-1,0,1,-n,0,n,-1,0,1],factor)
  dzdy: (n=2,factor=1/8) -> @convolve([1,n,1,0,0,0,-1,-n,-1],factor)
  laplace8: -> @convolve([-1,-1,-1,-1,8,-1,-1,-1,-1])
  laplace4: -> @convolve([0,-1,0,-1,4,-1,0,-1,0])
  blur: (factor=0.0625) -> @convolve([1,2,1,2,4,2,1,2,1], factor) # 1/16 = 0.0625
  edge: -> @convolve([1,1,1,1,-7,1,1,1,1])

  # Return filtered dataset by applying f to each dataset element
  filter: (f) -> new DataSet @width, @height, (f(d) for d in @data), @model

  # Create two new convolved datasets, slope and aspect, common in
  # the use of an elevation data set. See Esri tutorials for
  # [slope](http://goo.gl/ZcOl08) and [aspect](http://goo.gl/KoI4y5)
  # It also returns the two derivitive DataSets, dzdx, dzdy for
  # those wanting to use the results of the two convolutions.
  slopeAndAspect: (noNaNs=true, posAngle=true) ->
    dzdx = @dzdx() # sub left z from right
    dzdy = @dzdy() # sub bottom z from top
    aspect = []; slope = []; h = dzdx.height; w = dzdx.width
    for y in [0...h] by 1
      for x in [0...w] by 1
        gx = dzdx.getXY(x,y); gy = dzdy.getXY(x,y)
        slope.push Math.atan(Math.sqrt(gx*gx + gy*gy)) #/(@cellsize)) # radians
        while noNaNs and gx is gy
          gx += u.randomNormal 0,.0001; gy += u.randomNormal 0,.0001
        # radians in [-PI,PI], downhill
        rad = if gx is gy is 0 then NaN else Math.atan2 -gy,-gx
        # positive radians in [0,2PI] if desired
        rad += 2*Math.PI if posAngle and rad < 0
        aspect.push rad
    slope = new DataSet w, h, slope, @model
    aspect = new DataSet w, h, aspect, @model
    u.aToObj [slope, aspect, dzdx, dzdy], ["slope", "aspect", "dzdx", "dzdy"]
  # Return a subset of the dataset. x,y,width,height integers
  subset: (x, y, width, height) ->
    u.error "subSet: params out of range" if x+width>@width or y+height>@height
    data = []
    for j in [y...y+height] by 1
      for i in [x...x+width] by 1
        data.push @getXY i,j
    new DataSet width, height, data, @model

ABM.AscDataSet = class AscDataSet extends DataSet
  # An .asc GIS file a text file with a header:
  #
  #     ncols 195
  #     nrows 195
  #     xllcorner -84.355652
  #     yllcorner 39.177963
  #     cellsize 0.000093
  #     NODATA_value -9999
  #
  # ..followed by a ncols X nrows matrix of numbers

  # Constructor takes a string generally via an xhr request.
  # It can be "empty" .. i.e. needing a second parse() call
  # so that it can be used in an async file operation.
  constructor: (@str="", @model) ->
    super() # start out as an empty dataset
    return if @str.length is 0
    @parse @str
  # Complete an initial, empty dataset object who's string
  # is read via an xhr request.
  parse: (@str) ->
    textData = @str.split "\n"; @header = {}; #gisData.data = []
    for i in [0..5]
      keyVal = textData[i].split /\s+/
      @header[keyVal[0].toLowerCase()] = parseFloat keyVal[1]
    for i in [0...@header.nrows] by 1
      nums = textData[6+i].trim().split(" ")
      nums[i] = parseFloat nums[i] for i in [0...nums.length]
      @data = @data.concat nums
    @reset @header.ncols, @header.nrows, @data

ABM.ImageDataSet = class ImageDataSet extends DataSet
  # An image-as-data dataset.  The parser takes an image
  # data Uint8Array, enumerates it in 4-byte segments converting
  # the segments into a data element for the given array type.
  # If rowsPerSlice is set, incrementally traverse image in image
  # slice of that height; used for huge images.
  # Defaults to gray scale and Uint8ClampedArray
  # img may be a canvas
  constructor: (img, @f=u.pixelByte(0), @arrayType=Uint8ClampedArray, @rowsPerSlice, @model) ->
    super() # start out as an empty dataset
    return unless img?
    @parse img
  parse: (img) ->
    @rowsPerSlice or= img.height
    data = u.imageRowsToData img, @rowsPerSlice, @f, @arrayType
    @reset img.width, img.height, data

ABM.PatchDataSet = class PatchDataSet extends DataSet
  constructor: (f, arrayType=Array, @model) ->
    data = new arrayType (ps=@model.patches).length
    f = u.propFcn f if u.isString f
    data[i] = f(p) for p,i in ps
    super ps.numX, ps.numY, data
    @useNearest = true
  toPatchVar: (name) ->
    p[name] = @data[i] for p,i in @model.patches; null
