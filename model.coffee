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
  # Create initial animator for the model, specifying default rate (fps) and multiStep (async).
  # If multiStep, run the draw() and step() methods asynchronously by draw() using
  # requestAnimFrame and step() using setTimeout.
  constructor: (@model, @rate=30, @multiStep=false) -> @reset() # init all animation state
  # Adjust animator.  This is used by programmer as the default animator will already have
  # been created by the time her model runs.
  setRate: (@rate, @multiStep=false) -> @resetAnim()
  # start/stop model, often used for debugging
  start: ->
    if not @animStop then return # avoid multiple animates
    @resetAnim()
    @animStop = false
    @animate()
  resetAnim: ->
    @startMS = @now()
    @startTick = @ticks
    @startDraw = @draws
  stop: ->
    @animStop = true
    if @animHandle? then cancelAnimFrame @animHandle
    if @timeoutHandle? then clearTimeout @timeoutHandle
    if @intervalHandle? then clearInterval @intervalHandle
    @animHandle = @timerHandle = @intervalHandle = null
  reset: -> @stop(); @ticks = @draws = 0
  # step/draw the model.  Note ticks/draws counters separate due to async.
  step: -> @ticks++; @model.step()
  draw: -> @draws++; @model.draw()
  # step and draw the model once, mainly debugging
  once: -> @step(); @draw()
  # Get current time, with high resolution timer if available
  now: -> (performance ? Date).now()
  # Time in ms since starting animator
  ms: -> @now()-@startMS
  # Get the number of ticks/draws per second.  They will differ if async
  ticksPerSec: -> if (elapsed = @ticks-@startTick) is 0 then 0 else Math.round elapsed*1000/@ms()
  drawsPerSec: -> if (elapsed = @draws-@startDraw) is 0 then 0 else Math.round elapsed*1000/@ms()
  # Return a status string for debugging and logging performance
  toString: -> "ticks: #{@ticks}, draws: #{@draws}, rate: #{@rate} #{@ticksPerSec()}/#{@drawsPerSec()}"
  # Animation via setTimeout and requestAnimFrame
  animateSteps: =>
    @step()
    @timeoutHandle = setTimeout @animateSteps, 10 unless @animStop
  animateDraws: =>
    if @drawsPerSec() <= @rate
      @step() if not @multiStep
      @draw()
    @animHandle = requestAnimFrame @animateDraws unless @animStop
  animate: ->
    if @multiStep
      @animateSteps()
    @animateDraws()

# ### Class Model

class ABM.Model  
  
  # Class variable for layers parameters. 
  # Can be added to by programmer to modify/create layers, **before** starting your own model.
  # Example:
  # 
  #     v.z++ for k,v of ABM.Model::contextsInit # increase each z value by one
  contextsInit: {
    patches:   {z:0, ctx:"2d"}
    drawing:   {z:1, ctx:"2d"}
    links:     {z:2, ctx:"2d"}
    agents:    {z:3, ctx:"2d"}
    spotlight: {z:4, ctx:"2d"}
  }
  # Constructor: 
  #
  # * create agentsets, install them and ourselves in ABM global namespace
  # * create layers/contexts, install drawing layer in ABM global namespace
  # * setup patch coord transforms for each layer context
  # * intialize various instance variables
  # * call `setup` abstract method
  constructor: (
    @div, size, minX, maxX, minY, maxY,
    isTorus=true, hasNeighbors=true
  ) ->
    ABM.model = @ #; numX = maxX-minX+1; numY = maxY-minY+1    
    @setWorld size, minX, maxX, minY, maxY, isTorus, hasNeighbors
    @contexts = ABM.contexts = {}
    
    # * Create 2D canvas contexts layered on top of each other.
    # * Initialize a patch coord transform for each layer.
    # 
    # Note: this is permanent .. there isn't the usual ctx.restore().
    # To use the original canvas 2D transform temporarily:
    #
    #     u.setIdentity ctx
    #       <draw in native coord system>
    #     ctx.restore() # restore patch coord system
    
    for own k,v of @contextsInit
      @contexts[k] = ctx = u.createLayer div, @world.width, @world.height, v.z, v.ctx
      @setCtxTransform(ctx)

    # One of the layers is used for drawing only, not an agentset:
    @drawing = ABM.drawing = @contexts.drawing
    # Setup spotlight layer, also not an agentset:
    @contexts.spotlight.globalCompositeOperation = "xor"

    # Initialize animator to default: 30fps, not async
    @anim = new ABM.Animator(@)
    # Set drawing controls.  Default to drawing each agentset.
    # Optimization: If any of these is set to false, the associated
    # agentset is drawn only once, remaining static after that.
    @refreshLinks = @refreshAgents = @refreshPatches = true

    # Initialize agentsets.
    @patches = ABM.patches = new ABM.Patches ABM.Patch, "patches"
    @agents = ABM.agents = new ABM.Agents ABM.Agent, "agents"
    @links = ABM.links = new ABM.Links ABM.Link, "links"

    # Call the models setup function. Set the list of global variables to
    # the new variables created by setup(). Do not include agentsets, they
    # are available in the ABM global.
    @setup()
  
  # Stop and reset the model
  reset: () -> 
    @anim.reset() # stop & reset ticks/steps counters
    @patches = ABM.patches = new ABM.Patches ABM.Patch, "patches"
    @agents = ABM.agents = new ABM.Agents ABM.Agent, "agents"
    @links = ABM.links = new ABM.Links ABM.Link, "links"
    @setCtxTransform v for k,v of @contexts # clear/resize all contexts
    u.s.spriteSheets.length = 0 # possibly null out entries?
  # reset, then setup and start the model
  restart: -> @reset(); @setup(); @start()
  # Initialize/reset world parameters.
  setWorld: (size, minX, maxX, minY, maxY, isTorus=true, hasNeighbors=true) ->
    numX = maxX-minX+1; numY = maxY-minY+1; width = numX*size; height = numY*size
    ABM.world = @world = {size,minX,maxX,minY,maxY,numX,numY,width,height,isTorus,hasNeighbors}
  setCtxTransform: (ctx) ->
    ctx.canvas.width = @world.width; ctx.canvas.height = @world.height
    ctx.save()
    ctx.scale @world.size, -@world.size
    ctx.translate -(@world.minX-.5), -(@world.maxY+.5)
  

#### Optimizations:
  
  # Modelers "tune" their model by adjusting flags:<br>
  # `@refreshLinks, @refreshAgents, @refreshPatches`<br>
  # and by the following methods:

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support imageSmoothingEnabled or equivalent.
  setFastPatches: -> @patches.usePixels()
    
  # Have patches cache the agents currently on them.
  # Optimizes Patch p.agentsHere method
  setCacheAgentsHere: -> @patches.cacheAgentsHere()
  
  # Have agents cache the links with them as a node.
  # Optimizes Agent a.myLinks method
  setCacheMyLinks: -> @agents.cacheLinks()
  
  # Have patches cache the given patchRect.
  # Optimizes patchRect, inRadius and inCone
  setCachePatchRects: (radius, meToo=false) -> @patches.cacheRect radius, meToo

#### Text Utilities:
  
  # Set the text parameters for an agentset's context.  See ABM.util.
  setTextParams: (agentset, domFont, align="center", baseline="middle") ->
    u.ctxTextParams @contexts[agentset.name], domFont, align, baseline
  setLabelParams: (agentset, color, xy) ->
    u.ctxLabelParams @contexts[agentset.name], color, xy
  
#### User Model Creation
# A user's model is made by subclassing Model and over-riding these
# two abstract methods. `super` need not be called.
  
  # Initialize your model here.
  setup: -> # called at the end of model creation
  # Update/step your model here
  step: -> # called each step of the animation

# Convenience access to animator:

  # Start/stop the animation
  start: -> @anim.start()
  stop: -> @anim.stop()
  # Animate once by `step(); draw()`. For debugging from console.
  once: -> @anim.once() 

#### Animation.
  
# Call the agentset draw methods if either the first draw call or
# their "refresh" flags are set.  The latter are simple optimizations
# to avoid redrawing the same static scene. Called by animator.
  draw: ->
    @patches.draw @contexts.patches  if @refreshPatches or @anim.draws is 1
    @links.draw   @contexts.links    if @refreshLinks   or @anim.draws is 1
    @agents.draw  @contexts.agents   if @refreshAgents  or @anim.draws is 1
    @drawSpotlight @spotlightAgent, @contexts.spotlight  if @spotlightAgent?

# Creates a spotlight effect on an agent, so we can follow it throughout the model.
# Use:
#
#     @setSpotliight breed.oneOf()
#
# to draw one of a random breed. Remove spotlight by passing `null`
  setSpotlight: (@spotlightAgent) ->
    u.clearCtx @contexts.spotlight if not @spotlightAgent?

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
#     @embers.setDefaultColor [255,0,0]
#
# ..will set the default color for just the embers.
  
  createBreeds: (s, agentClass, breedSet) ->
    breeds = []; breeds.classes = {}; breeds.sets = {}
    for b in s.split(" ")
      c = class Breed extends agentClass
      @[b] = # add @<breed> to local scope
        new breedSet c, b, agentClass::breed # create subset agentSet
      breeds.push @[b]
      breeds.sets[b] = @[b]
      breeds.classes["#{b}Class"] = c
    breeds
  patchBreeds: (s) -> ABM.patchBreeds = @createBreeds s, ABM.Patch, ABM.Patches
  agentBreeds: (s) -> ABM.agentBreeds = @createBreeds s, ABM.Agent, ABM.Agents
  linkBreeds:  (s) -> ABM.linkBreeds  = @createBreeds s, ABM.Link,  ABM.Links
  
  # Utility for models to create agentsets from arrays.  Ex:
  #
  #     even = @asSet (a for a in @agents when a.id % 2 is 0)
  #     even.shuffle().getProp("id") # [6, 0, 4, 2, 8]
  asSet: (a) -> # turns an array into an agent set
    ABM.AgentSet.asSet(a)

  # A simple debug aid which places short names in the global name space.
  # Note we avoid using the actual name, such as "patches" because this
  # can cause our modules to mistakenly depend on a global name.
  # See [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension too.
  setRootVars: ->
    root.ps  = @patches
    root.p0  = @patches[0]
    root.as  = @agents
    root.a0  = @agents[0]
    root.ls  = @links
    root.l0  = @links[0]
    root.dr  = @drawing
    root.u   = ABM.util
    root.sh  = ABM.shapes
    root.app = @
    root.cx  = @contexts
    root.ab  = ABM.agentBreeds
    root.lb  = ABM.linkBreeds
    root.an  = @anim
    root.wd  = ABM.world
    root.gl  = @globals
    root.root= root
    null
  
