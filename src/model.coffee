# Class Model is the control center for our AgentSets: Patches, Turtles and Links.
# Creating new models is done by subclassing class Model and overriding two
# virtual/abstract methods: `setup()` and `step()`

# ### Class Model

class Model
  # Class variable for layers parameters.
  # Can be added to by programmer to modify/create layers, **before** starting your own model.
  # Example:
  #
  #     v.z++ for k,v of Model::contextsInit # increase each z value by one
  contextsInit: { # Experimental: image:   {z:15,  ctx:"img"}
    patches:   {z:10, ctx:"2d"}
    drawing:   {z:20, ctx:"2d"}
    links:     {z:30, ctx:"2d"}
    turtles:   {z:40, ctx:"2d"}
    spotlight: {z:50, ctx:"2d"}
  }

  # Static method: return defaulted Model options object.
  # Access by (ABM.)Model.defaultOptions() etc
  @nonWorldOptions = ["div"]
  @defaultOptions: ->
    div: null
    size: 13
    minX: -16
    maxX: 16
    minY: -16
    maxY: 16
    isTorus: false
    hasNeighbors: true

  # Constructor:
  #
  # * create agentsets, install them and ourselves in ABM global namespace
  # * create layers/contexts, install drawing layer in ABM global namespace
  # * setup patch coord transforms for each layer context
  # * intialize various instance variables
  # * call `setup` abstract method
  constructor: (args) ->
    # Setup and error check args
    options = Model.defaultOptions()
    unless u.isObject args # remove after a while
      console.log "option defaults:", options
      u.error "Model constructor: use options object; see console for defaults."
    u.deprecated "Model: isHeadless no longer used" if args.isHeadless?

    # Merge args into options. Insures newer options/defaults included
    for k,v of args # when k isnt "isHeadless" # Remove headless test shortly
      u.error "Bad Model arg: #{k}: #{v}" if options[k] is undefined
      options[k] = v
    @setWorld options

    u.mixin(@, new Evented())

    @contexts = {}
    if options.div?
      @div=document.getElementById(options.div)
      # el.setAttribute 'style' erases existing style, el.style.xx does not
      s=@div.style
      s.position="relative"; s.width=@world.pxWidth; s.height=@world.pxHeight

      # * Create 2D canvas contexts layered on top of each other.
      # * Initialize a patch coord transform for each layer.
      #
      # Note: The transform is permanent .. there isn't the usual ctx.restore().
      # To use the original canvas 2D transform temporarily:
      #
      #     u.setIdentity ctx
      #       <draw in native coord system>
      #     ctx.restore() # restore patch coord system
      for own k,v of @contextsInit
        @contexts[k] = ctx = u.createLayer @div, @world.pxWidth, @world.pxHeight, v.z, v.ctx
        @setCtxTransform ctx if ctx.canvas?
        if ctx.canvas? then ctx.canvas.style.pointerEvents = 'none'
        u.elementTextParams ctx, "10px sans-serif", "center", "middle"

      # One of the layers is used for drawing only, not an agentset:
      @drawing = @contexts.drawing
      @drawing.clear = => u.clearCtx @drawing
      # Setup spotlight layer, also not an agentset:
      @contexts.spotlight.globalCompositeOperation = "xor"

    @anim = new Animator @
    # Set drawing controls.  Default to drawing each agentset.
    # Optimization: If any of these is set to false, the associated
    # agentset is drawn only once, remaining static after that.
    @refreshLinks = @refreshTurtles = @refreshPatches = true

    # Create model-local versions of AgentSets and their
    # agent class.  Clone the agent classes so that they
    # can use "defaults" in isolation when multiple
    # models run on a page.
    @Patch = u.cloneClass(Patch)
    @Turtle = u.cloneClass(Turtle)
    @Link = u.cloneClass(Link)

    # Initialize agentsets.
    @patches = new Patches @, @Patch, "patches"
    @turtles = new Turtles @, @Turtle, "turtles"
    @links = new Links @, @Link, "links"

    # Initialize model global resources
    @debugging = false
    @modelReady = false
    @globalNames = null; @globalNames = u.ownKeys @
    @globalNames.set = false
    @startup()
    u.waitOnFiles => @modelReady=true; @setupAndEmit(); @globals() unless @globalNames.set

  # Initialize/reset world parameters by expanding options.
  setWorld: (opts) ->
    w = {}; w[k] = v for own k,v of opts when k not in Model.nonWorldOptions
    w.numX    = w.maxX-w.minX+1;  w.numY    = w.maxY-w.minY+1
    w.pxWidth = w.numX*w.size;    w.pxHeight= w.numY*w.size
    w.minXcor = w.minX-.5;        w.maxXcor = w.maxX+.5
    w.minYcor = w.minY-.5;        w.maxYcor = w.maxY+.5
    @world = w

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
  # `@refreshLinks, @refreshTurtles, @refreshPatches`<br>
  # and by the following helper methods:

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support imageSmoothingEnabled or equivalent.
  setFastPatches: -> @patches.usePixels()

  # Patches are all the same static default color, just "clear" entire canvas.
  # Don't use if patch breeds have different colors.
  setMonochromePatches: -> @patches.monochrome = true

  # Have patches cache the turtles currently on them.
  # Optimizes Patch p.turtlesHere method
  setCacheTurtlesHere: -> @patches.cacheTurtlesHere()

  # Have turtles cache the links with them as a node.
  # Optimizes Turtle a.myLinks method
  setCacheMyLinks: -> @turtles.cacheLinks()

#### User Model Creation
# A user's model is made by subclassing Model and over-riding these
# two abstract methods. `super` need not be called.

  # Initialize model resources (images, files) here.
  # Uses Util.waitOn so can be be async.
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
    console.log "reset: contexts" # clear/resize canvas xfms b4 agentsets
    (v.restore(); @setCtxTransform v) for k,v of @contexts when v.canvas?
    console.log "reset: patches"
    @patches = new Patches @, @Patch, "patches"
    console.log "reset: turtles"
    @turtles = new Turtles @, @Turtle, "turtles"
    console.log "reset: links"
    @links = new Links @, @Link, "links"
    Shapes.spriteSheets.length = 0 # possibly null out entries?
    console.log "reset: setup"
    @setupAndEmit()
    @setRootVars() if @debugging
    @start() if restart

#### Animation.

# Call the agentset draw methods if either the first draw call or
# their "refresh" flags are set.  The latter are simple optimizations
# to avoid redrawing the same static scene. Called by animator.
  draw: (force = @anim.stopped or @anim.draws is 1) ->
    if @debugging
      console.log @anim.toString()  if @anim.draws % 100 is 0
      @showSpriteSheet() if (@anim.draws is 2)# and @turtles[0]?.useSprites
    if @div?
      @patches.draw  @contexts.patches  if force or @refreshPatches
      @links.draw    @contexts.links    if force or @refreshLinks
      @turtles.draw  @contexts.turtles  if force or @refreshTurtles
      @drawSpotlight @spotlightTurtle, @contexts.spotlight if @spotlightTurtle?
    @emit('draw')
  toggleDrawing: ->
    if @div?
      @div0 = @div; @div = null
    else
      @div = @div0; @div0 = null

#### Wrappers around user-implemented methods

  setupAndEmit: ->
    @setup()
    @emit('setup')
  stepAndEmit: ->
    @step()
    @emit('step')

# Creates a spotlight effect on a turtle, so we can follow it throughout the model.
# Use:
#
#     @setSpotlight breed.oneOf()
#
# to draw one of a random breed. Remove spotlight by passing `null`
  setSpotlight: (@spotlightTurtle) ->
    u.clearCtx @contexts.spotlight unless @spotlightTurtle?

  drawSpotlight: (turtle, ctx) ->
    u.clearCtx ctx
    u.fillCtx ctx, Color.typedColor(0,0,0,.6*255)
    ctx.beginPath()
    ctx.arc turtle.x, turtle.y, 3, 0, 2*Math.PI, false
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
# These agentsets' `create` methods create subclasses of Turtle/Link.
# Use of <breed>.setDefault methods work as for turtles/links, creating default
# values for the breed set:
#
#     @embers.setDefault "color", [255,0,0]
#
# ..will set the default color for just the embers. Note: patch breeds are
# experimental, using setBreed, due to the patches being prebuilt.

  createBreeds: (breedNames, baseClass, baseSet) ->
    breeds = []; breeds.classes = {}; breeds.sets = {}
    for breedName in breedNames.split(" ")
      className = u.upperCamelCase breedName
      breedClass = u.cloneClass baseClass, className
      breed = @[breedName] =
        new baseSet @, breedClass, breedName, baseClass::breed
      breeds.push breed
      breeds.sets[breedName] = breed
      breeds.classes["#{breedName}Class"] = breedClass
    breeds
  patchBreeds: (breedNames) ->
    @patches.breeds = @createBreeds breedNames, @Patch, Patches
  agentBreeds: (breedNames) ->
    @turtles.breeds = @createBreeds breedNames, @Turtle, Turtles
  linkBreeds:  (breedNames) ->
    @links.breeds = @createBreeds breedNames, @Link, Links

  # Utility for models to create agentsets from arrays.  Ex:
  #
  #     even = @asSet (a for a in @turtles when a.id % 2 is 0)
  #     even.shuffle().getProp("id") # [6, 0, 4, 2, 8]
  asSet: (a, setType = AgentSet) -> AgentSet.asSet a, setType

  # A simple debug aid which places short names in the global name space.
  # Note we avoid using the actual name, such as "patches" because this
  # can cause our modules to mistakenly depend on a global name.
  # See [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension too.
  debug: (@debugging=true)->u.waitOn (=>@modelReady),(=>@setRootVars()); @
  setRootVars: ->
    window.psc = Patches
    window.tsc = Turtles
    window.lsc = Links
    window.pc  = @Patch
    window.tc  = @Turtle
    window.lc  = @Link
    window.ps  = @patches
    window.ts  = @turtles
    window.ls  = @links
    window.p0  = @patches[0]
    window.t0  = @turtles[0]
    window.l0  = @links[0]
    window.dr  = @drawing
    window.u   = Util
    window.cx  = @contexts
    window.an  = @anim
    window.gl  = @globals()
    window.dv  = @div
    window.app = @

  # Debug aid: Fill a named div with the (last) sprite sheet
  # Typically the div should be before the model div, float right:
  #
  #    <div id="sprites" style="float:right;"></div>
  #
  # If no divName given, use spriteSheet itself w/ float:right style
  showSpriteSheet: (divName) ->
    if Shapes.spriteSheets.length isnt 0
      sheet = Util.last(Shapes.spriteSheets)
      if divName?
        document.getElementById(divName).appendChild(sheet.canvas)
      else
        sheet.canvas.setAttribute "style", "float:right"
        @div.parentElement.insertBefore(sheet.canvas, @div)
    else
      console.log "showSpriteSheet: not using sprites"

# Create the namespace **ABM** for our project.
# Note here `this` or `@` == window due to coffeescript wrapper call.
# Thus @ABM is placed in the global scope.

@ABM = {
  Util
  Color
  ColorMaps
  colorMixin
  Shapes
  AgentSet
  Patch
  Patches
  Turtle
  Turtles
  Link
  Links
  Animator
  Evented
  Model
}
