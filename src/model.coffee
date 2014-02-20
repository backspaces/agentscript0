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
    divOrOpts, size=13, minX=-16, maxX=16, minY=-16, maxY=16,
    isTorus=false, hasNeighbors=true, isHeadless=false
  ) ->
    ABM.model = @
    if typeof divOrOpts is 'string'
      div = divOrOpts
      @setWorldDeprecated size, minX, maxX, minY, maxY, isTorus, hasNeighbors, isHeadless
    else
      div = divOrOpts.div
      isHeadless = divOrOpts.isHeadless = divOrOpts.isHeadless? or not div?
      @setWorld divOrOpts
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
  setWorld: (opts) ->
    w = defaults = { size: 13, minX: -16, maxX: 16, minY: -16, maxY: 16, isTorus: false, hasNeighbors: true, isHeadless: false }
    for own k,v of opts
      w[k] = v
    {size, minX, maxX, minY, maxY, isTorus, hasNeighbors, isHeadless} = w
    numX = maxX-minX+1; numY = maxY-minY+1; pxWidth = numX*size; pxHeight = numY*size
    minXcor=minX-.5; maxXcor=maxX+.5; minYcor=minY-.5; maxYcor=maxY+.5
    ABM.world = @world = {size,minX,maxX,minY,maxY,minXcor,maxXcor,minYcor,maxYcor,
      numX,numY,pxWidth,pxHeight,isTorus,hasNeighbors,isHeadless}
  setWorldDeprecated: (size, minX, maxX, minY, maxY, isTorus, hasNeighbors, isHeadless) ->
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
