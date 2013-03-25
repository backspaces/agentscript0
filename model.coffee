# Class Model is the control center for our AgentSets: Patches, Agents and Links.
# Creating new models is done by subclassing class Model and overriding two 
# virtual/abstract methods: `setup()` and `step()`

# The usual alias for **ABM.util**.
u = ABM.util

# ### Class Model

class ABM.Model  
  # Constructor: 
  #
  # * create agentsets, install them and ourselves in ABM global namespace
  # * create layers/contexts, install drawing layer in ABM global namespace
  # * setup patch coord transforms for each layer context
  # * intialize various instance variables
  # * call `setup` abstract method
  constructor: (
    div, size, minX, maxX, minY, maxY,
    torus=true, neighbors=true
  ) ->
    ABM.model = @
    
    # Create 4 2D canvas contexts layered on top of each other.
    layers = for i in [0..3] # multi-line array comprehension
      u.createLayer div, size*(maxX-minX+1), size*(maxY-minY+1), i, "2d"
    # One of the layers is used for drawing only, not an agentset:
    @drawing = ABM.drawing = layers[1]

    # Initialize a patch coord transform for each layer.<br>
    # Note: this is permanent .. there is no ctx.restore() call.<br>
    # To use the original canvas 2D transform temporarily:
    #
    #     ctx.save()
    #     ctx.setTransform(1, 0, 0, 1, 0, 0) # reset to identity
    #       <draw in native coord system>
    #     ctx.restore() # restore back to patch coord system
    for ctx in layers # install permenant (no ctx.restore) patch coordinates
      ctx.save()
      ctx.scale size, -size
      ctx.translate -(minX-.5), -(maxY+.5); 
    # Create instance variable object with names for each layer
    @contexts = ABM.contexts =
      patches: layers[0]
      drawing: layers[1]
      links:   layers[2]
      agents:  layers[3]
    # Set a variable in each context with its name 
    v.agentSetName = k for k,v of @contexts
    
    # Initialize agentsets.
    @patches = ABM.patches = \
      new ABM.Patches size,minX,maxX,minY,maxY,torus,neighbors
    @agents = ABM.agents = new ABM.Agents
    @links = ABM.links = new ABM.Links

    # Initialize instance variables
    @showFPS = true # show fps in console. generally use chrome fps instead
    @ticks = 1 # initial tick/frame
    @refreshLinks = @refreshAgents = @refreshPatches = true # drawing flags
    @fastPatches = false

    @stepFrequency = 1000/60    # call step method 60 times/second

    # Call the models setup function.
    @setup()

    @animStop = true

    # Postprocesssing after setup
    if @agents.useSprites
      @agents.setDefaultSprite() if ABM.Agent::color?
      for a in @agents when not a.hasOwnProperty "sprite"
        if a.hasOwnProperty "color" or a.hasOwnProperty "shape" or a.hasOwnProperty "size"
          a.sprite = ABM.shapes.shapeToCtx a.shape, a.color, a.size*@patches.size
    

#### Optimizations:

  # Modelers "tune" their model by adjusting flags:
  #
  #      @refreshLinks = @refreshAgents = @refreshPatches
  #
  # and by the following methods:

  # Draw patches using scaled image of colors. Note anti-aliasing may occur
  # if browser does not support imageSmoothingEnabled or equivalent.
  setFastPatches: ->
    ctx = @contexts.patches
    ctx.imageSmoothingEnabled = false
    ctx.mozImageSmoothingEnabled = false
    ctx.webkitImageSmoothingEnabled = false
    ctx.save() # revert to native 2D transform
    ctx.setTransform 1, 0, 0, 1, 0, 0
    @patches.drawWithPixels = true

  # Have agents use images (sprites) rather than drawing for agents.
  setAgentsUseSprites: ->
    @agents.setUseSprites(true)
    
  # Have patches cache the agents currently on them.
  # Optimizes Patch p.agentsHere method
  setCacheAgentsHere: ->
    p.agents = [] for p in @patches
    a.p.agents.push a for a in @agents
  
  # Have agents cache the links with them as a node.
  # Optimizes Agent a.myLinks method
  setCacheMyLinks: ->
    @links.cacheAgentLinks = true
    a.links = [] for a in @agents # not needed if called b4 any agents & links made
    (l.end1.links.push l; l.end2.links.push l) for l in @links
  
  # Have patches cache the given patchRect.
  # Optimizes patchRect, inRadius and inCone
  setCachePatchRects: (radius, meToo=false) ->
    for p in @patches
      p.pRect = @patches.patchRect p, radius, radius, meToo
      p.pRect.radius = radius
      p.pRect.meToo = meToo
  
  # Ask agents to cache their color strings.
  # This is a temporary optimization and will likely change.
  setAgentStaticColors: ->
    @agents.setStaticColors(true)

#### Text Utilities:
  # Return string name for agentset.  Note this depends on our
  # using a singleton naming convension: foo = new Foo(...)
  agentSetName: (aset) -> aset.constructor.name.toLowerCase()
  # Set the text parameters for an agentset's context.  See ABM.util
  setTextParams: (agentSetName, domFont, align="center", baseline="middle") ->
    agentSetName = @agentSetName(agentSetName) if typeof agentSetName isnt "string"
    u.ctxTextParams @contexts[agentSetName], domFont, align, baseline
  # Set the label parameters for an agentset's context.  See ABM.util
  setLabelParams: (agentSetName, color, xy) ->
    agentSetName = @agentSetName(agentSetName) if typeof agentSetName isnt "string"
    u.ctxLabelParams @contexts[agentSetName], color, xy
  
#### User Model Creation
# A user's model is made by subclassing Model and over-riding these
# two abstract methods. `super` need not be called.

  # Initialize your model here
  setup: -> # called at the end of model creation
  # Update/step your model here
  step: -> # called each step of the animation

#### Animation. 
# These will be called for you by Model. start/stop animation, increment ticks.

# A (possibly temporary) hook for the first run of the model.
# Similar to setup/step but `super` should be called in case
# AgentScript needs to do something here.
  startup: -> # called on first tick.  Used for optimization late binding.

# Initializes the animation and starts the model by calling `run`, and starts
# the animation by calling `animate`
  start: ->
    if not @animStop then return     # prevent multiple calls to start()
    if @ticks is 1
      @startup()
    @startMS = Date.now()
    @startTick = @ticks
    @animStop = false
    @run()
    @animate()

# Stop the animation at the end of the next call to `animate`
  stop: -> @animStop = true

# Runs the two methods used to increment the model and queues the next call to itself.
  run: =>
    @step()
    @tick() # Note: NL difference, called here not in user's step()
    setTimeout @run, @stepFrequency unless @animStop

# Call the agentset draw methods if either the first draw call or
# their "refresh" flags are set.  The latter are simple optimizations
# to avoid redrawing the same static scene.
  draw: ->
    @patches.draw @contexts.patches  if @refreshPatches or @ticks is 1
    @links.draw   @contexts.links    if @refreshLinks   or @ticks is 1
    @agents.draw  @contexts.agents   if @refreshAgents  or @ticks is 1

# Runs draw() to repaint, and queues the next call to itself.
  animate: => # note fat arrow, animate bound to "this"
    @draw()
    requestAnimFrame @animate unless @animStop

# Updates the `ticks` counter and prints out the fps every 100 steps
# if the `showFPS` flag is set.
  tick: ->
    animTicks = @ticks-@startTick
    if @showFPS and (animTicks % 100) is 0 and animTicks isnt 0
      fps = Math.round (animTicks*1000/(Date.now()-@startMS))
      console.log "fps: #{fps} at #{animTicks} ticks"
    @ticks++

#### Breeds
# Two very primitive versions of NL's `breed` commands.
#
#     @agentBreeds "embers fires"
#     @linkBreeds "spokes rims"
#
# will create 4 dynamic methods: 
#
#     @embers() and @fires()
#
# which return agents with their breeds set to "embers" or "fires", and
#
#     @spokes() and @rims() 
#
# which return links with their breed set to either "spokes" or "rims"
#

  linkBreeds: (s) ->
    for b in s.split(" ")
      @[b] = do(b) =>
       -> @links.breed(b)
    null
  agentBreeds: (s) ->
    for b in s.split(" ")
      @[b] = do(b) =>
       -> @agents.breed(b)
    null

  
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
    ABM.root.ps = @patches
    ABM.root.p0 = @patches[0]
    ABM.root.as = @agents
    ABM.root.a0 = @agents[0]
    ABM.root.ls = @links
    ABM.root.l0 = @links[0]
    ABM.root.dr = @drawing
    ABM.root.u = ABM.util
    ABM.root.app = @
    ABM.root.cx = @contexts
    ABM.root.cl = (o) -> console.log o
    ABM.root.cla = (array) -> console.log a for a in array
    null
  
