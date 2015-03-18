# A *very* simple shapes module for drawing
# [NetLogo-like](http://ccl.northwestern.edu/netlogo/docs/) agents.

shapes = Shapes = do -> # TODO: Shapes is external name
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
  # The list of current shapes, via `ABM.Shapes.names()` below, is:
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

  # An async utility for delayed drawing of images into sprite slots
  fillSlot = (slot, img) ->
    slot.ctx.save(); slot.ctx.scale 1, -1
    slot.ctx.drawImage img, slot.x, -(slot.y+slot.spriteSize), slot.spriteSize, slot.spriteSize
    slot.ctx.restore()
  # The spritesheet data, indexed by slotSize
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
  filledRing:
    rotate: false
    draw: (c) ->
      circ(c,0,0,1)
      tempStyle = c.fillStyle # save fill style
      c.fillStyle = c.strokeStyle # use stroke style for larger circle
      c.fill()
      c.fillStyle = tempStyle
      c.beginPath()
      circ(c,0,0,.8)
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
  #     ABM.Shapes.add "test", true, (c) -> # bowtie/hourglass
  #       ABM.Shapes.poly c, [[-.5,-.5],[.5,.5],[-.5,.5],[.5,-.5]]
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
  draw: (ctx, shape, x, y, size, rad, color, strokeColor) ->
    if shape.shortcut?
      unless shape.img?
        ctx.fillStyle = color.css # u.colorStr color
      shape.shortcut ctx,x,y,size
    else
      ctx.save()
      ctx.translate x, y
      ctx.scale size, size if size isnt 1
      ctx.rotate rad if rad isnt 0
      if shape.img? # is an image, not a path function
        shape.draw ctx
      else
        ctx.fillStyle = color.css # u.colorStr color
        if strokeColor
          ctx.strokeStyle = strokeColor.css # u.colorStr strokeColor
          ctx.lineWidth = 0.05
        ctx.save()
        ctx.beginPath(); shape.draw ctx; ctx.closePath()
        ctx.restore()
        ctx.fill()
        ctx.stroke() if strokeColor

      ctx.restore()
    shape
  drawSprite: (ctx, s, x, y, size, rad) ->
    if rad is 0
      ctx.drawImage s.ctx.canvas, s.x, s.y, s.spriteSize, s.spriteSize, x-size/2, y-size/2, size, size
    else
      ctx.save()
      ctx.translate x, y # see http://goo.gl/VUlhY for drawing centered rotated images
      ctx.rotate rad
      ctx.drawImage s.ctx.canvas, s.x, s.y, s.spriteSize, s.spriteSize, -size/2,-size/2, size, size
      ctx.restore()
    s
  # Convert a shape to a sprite by allocating a sprite sheet "slot" and drawing
  # the shape to fit it. Return existing sprite if duplicate.
  shapeToSprite: (name, color, size, strokeColor) ->
    colorCss = Color.convertColor color, "css"
    strokeCss = Color.convertColor strokeColor, "css" if strokeColor?
    spriteSize = Math.ceil size
    strokePadding = 4
    slotSize = spriteSize + strokePadding
    shape = @[name]
    # index = if shape.img? then name else "#{name}-#{u.colorStr(color)}"
    index = if shape.img? then name else "#{name}-#{colorCss}"
    ctx = spriteSheets[slotSize]
    # Create sheet for this bit size if it does not yet exist
    unless ctx?
      spriteSheets[slotSize] = ctx = u.createCtx slotSize*10, slotSize
      ctx.nextX = 0; ctx.nextY = 0; ctx.index = {}
    # Return matching sprite if index match found
    return foundSlot if (foundSlot = ctx.index[index])?
    # Extend the sheet if we're out of space
    if (slotSize)*ctx.nextX is ctx.canvas.width
      u.resizeCtx ctx, ctx.canvas.width, ctx.canvas.height+slotSize
      ctx.nextX = 0; ctx.nextY++
    # Create the sprite "slot" object and install in index object
    x = (slotSize)*ctx.nextX+strokePadding/2; y = (slotSize)*ctx.nextY+strokePadding/2
    slot = {ctx, x, y, size, spriteSize, name, color, strokeColor, index}
    ctx.index[index] = slot
    # Draw the shape into the sprite slot
    if (img=shape.img)? # is an image, not a path function
      if img.height isnt 0 then fillSlot(slot, img)
      else img.onload = -> fillSlot(slot, img)
    else
      ctx.save()
      ctx.translate (ctx.nextX+0.5)*(slotSize), (ctx.nextY+0.5)*(slotSize)
      ctx.scale spriteSize, spriteSize
      ctx.fillStyle = colorCss # u.colorStr color
      if strokeColor
        ctx.strokeStyle = strokeCss # u.colorStr strokeColor
        ctx.lineWidth = 0.05
      ctx.save()
      ctx.beginPath(); shape.draw ctx; ctx.closePath()
      ctx.restore()
      ctx.fill()
      ctx.stroke() if strokeColor
      ctx.restore()
    ctx.nextX++; slot
