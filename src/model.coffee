# Class Model is the control center for our AgentSets: Patches, Agents and Links.
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
    divOrOpts, size=13, minX=-16, maxX=16, minY=-16, maxY=16,
    isTorus=false, hasNeighbors=true, isHeadless=false
  ) ->
    u.mixin(@, new Evented())
    if typeof divOrOpts is 'string'
      div = divOrOpts
      @setWorldDeprecated size, minX, maxX, minY, maxY,
        isTorus, hasNeighbors, isHeadless
    else
      div = divOrOpts.div
      isHeadless = divOrOpts.isHeadless = divOrOpts.isHeadless or not div?
      @setWorld divOrOpts
    @contexts = {}
    unless isHeadless
      (@div=document.getElementById(div)).setAttribute 'style',
        "position:relative; width:#{@world.pxWidth}px; height:#{@world.pxHeight}px"

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
    @refreshLinks = @refreshAgents = @refreshPatches = true

    # Create model-local versions of AgentSets and their
    # agent class.  Clone the agent classes so that they
    # can use "defaults" in isolation when multiple
    # models run on a page.
    @Patch = u.cloneClass(Patch)
    @Agent = u.cloneClass(Agent)
    @Link = u.cloneClass(Link)

    # Initialize agentsets.
    @patches = new Patches @, @Patch, "patches"
    @agents = new Agents @, @Agent, "agents"
    @links = new Links @, @Link, "links"

    # Initialize model global resources
    @debugging = false
    @modelReady = false
    @globalNames = null; @globalNames = u.ownKeys @
    @globalNames.set = false
    @startup()
    u.waitOnFiles => @modelReady=true; @setupAndEmit(); @globals() unless @globalNames.set

  # Initialize/reset world parameters.
  setWorld: (opts) ->
    w = defaults = { size: 13, minX: -16, maxX: 16, minY: -16, maxY: 16, isTorus: false, hasNeighbors: true, isHeadless: false }
    for own k,v of opts
      w[k] = v
    {size, minX, maxX, minY, maxY, isTorus, hasNeighbors, isHeadless} = w
    numX = maxX-minX+1; numY = maxY-minY+1; pxWidth = numX*size; pxHeight = numY*size
    minXcor=minX-.5; maxXcor=maxX+.5; minYcor=minY-.5; maxYcor=maxY+.5
    @world = {size,minX,maxX,minY,maxY,minXcor,maxXcor,minYcor,maxYcor,
      numX,numY,pxWidth,pxHeight,isTorus,hasNeighbors,isHeadless}
  setWorldDeprecated: (size, minX, maxX, minY, maxY, isTorus, hasNeighbors, isHeadless) ->
    u.deprecated "Model.setWorldDeprecated: ctor should use options object"
    numX = maxX-minX+1; numY = maxY-minY+1; pxWidth = numX*size; pxHeight = numY*size
    minXcor=minX-.5; maxXcor=maxX+.5; minYcor=minY-.5; maxYcor=maxY+.5
    @world = {size,minX,maxX,minY,maxY,minXcor,maxXcor,minYcor,maxYcor,
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
    console.log "reset: contexts" # clear/resize canvas xfms b4 agentsets
    (v.restore(); @setCtxTransform v) for k,v of @contexts when v.canvas?
    console.log "reset: patches"
    @patches = new Patches @, @Patch, "patches"
    console.log "reset: agents"
    @agents = new Agents @, @Agent, "agents"
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
      console.log @anim.toString() if @anim.draws % 100 is 0

    @patches.draw @contexts.patches  if force or @refreshPatches
    @links.draw   @contexts.links    if force or @refreshLinks
    @agents.draw  @contexts.agents   if force or @refreshAgents
    @drawSpotlight @spotlightAgent, @contexts.spotlight if @spotlightAgent?
    @emit('draw')

#### Wrappers around user-implemented methods

  setupAndEmit: ->
    @setup()
    @emit('setup')
  stepAndEmit: ->
    @step()
    @emit('step')

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
    u.fillCtx ctx, Color.typedColor(0,0,0,.6*255)
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
# These agentsets' `create` methods create subclasses of Agent/Link.
# Use of <breed>.setDefault methods work as for agents/links, creating default
# values for the breed set:
#
#     @embers.setDefault "color", [255,0,0]
#
# ..will set the default color for just the embers. Note: patch breeds are currently
# not usable due to the patches being prebuilt.  Stay tuned.

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
    @agents.breeds = @createBreeds breedNames, @Agent, Agents
  linkBreeds:  (breedNames) ->
    @links.breeds = @createBreeds breedNames, @Link, Links

  # Utility for models to create agentsets from arrays.  Ex:
  #
  #     even = @asSet (a for a in @agents when a.id % 2 is 0)
  #     even.shuffle().getProp("id") # [6, 0, 4, 2, 8]
  asSet: (a, setType = AgentSet) -> AgentSet.asSet a, setType

  # A simple debug aid which places short names in the global name space.
  # Note we avoid using the actual name, such as "patches" because this
  # can cause our modules to mistakenly depend on a global name.
  # See [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension too.
  debug: (@debugging=true)->u.waitOn (=>@modelReady),(=>@setRootVars()); @
  setRootVars: ->
    window.psc = Patches
    window.asc = Agents
    window.lsc = Links
    window.pc  = @Patch
    window.ac  = @Agent
    window.lc  = @Link
    window.ps  = @patches
    window.as  = @agents
    window.ls  = @links
    window.p0  = @patches[0]
    window.a0  = @agents[0]
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
      console.log sheet
      if divName?
        document.getElementById(divName).appendChild(sheet.canvas)
      else
        sheet.canvas.setAttribute "style", "float:right"
        @div.parentElement.insertBefore(sheet.canvas, @div)
    else
      console.log "showSpriteSheet: no sprite sheet found"

# Create the namespace **ABM** for our project.
# Note here `this` or `@` == window due to coffeescript wrapper call.
# Thus @ABM is placed in the global scope.
# @ABM={}


@ABM = {
  util    # deprecated, Util
  shapes  # deprecated, Shapes
  Util
  Color
  ColorMaps
  colorMixin
  Shapes
  AgentSet
  Patch
  Patches
  Agent
  Agents
  Link
  Links
  Animator
  Evented
  Model
}
