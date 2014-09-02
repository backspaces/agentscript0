# Class Model is the control center for our Sets: Patches, Agents and Links.
# Creating new models is done by subclassing class Model and overriding two 
# virtual/abstract methods: `setup()` and `step()`

# ### Class Model

ABM.models = {} # user space, put your models here

class ABM.Model
  # Class variable for layers parameters. 
  # Can be added to by programmer to modify/create layers, **before** starting your own model.
  # Example:
  # 
  #     v.z++ for k, v of ABM.Model::contextsInit # increase each z value by one
  contextsInit: { # Experimental: image:   {z: 15, context: "img"} 
    patches:   {z: 10, context: "2d"}
    drawing:   {z: 20, context: "2d"}
    links:     {z: 30, context: "2d"}
    agents:    {z: 40, context: "2d"}
    spotlight: {z: 50, context: "2d"}
  }
  # Constructor: 
  #
  # * create agentsets, install them and ourselves in ABM global namespace
  # * create layers/contexts, install drawing layer in ABM global namespace
  # * setup patch coordinate transforms for each layer context
  # * intialize various instance variables
  # * call `setup` abstract method
  constructor: (options) ->
    div = options.div
    isHeadless = options.isHeadless = options.isHeadless or not div?
    @setWorld options

    @contexts = {}

    unless isHeadless
      (@div = document.getElementById(div)).setAttribute 'style',
        "position:relative; width:#{@world.pxWidth}px; height:#{@world.pxHeight}px"

      # * Create 2D canvas contexts layered on top of each other.
      # * Initialize a patch coordinate transform for each layer.
      # 
      # Note: this transform is permanent .. there isn't the usual context.restore().
      # To use the original canvas 2D transform temporarily:
      #
      #     u.setIdentity context
      #       <draw in native coordinate system>
      #     context.restore() # restore patch coordinate system
      for own key, value of @contextsInit
        @contexts[key] = context = u.createLayer @div, @world.pxWidth,
          @world.pxHeight, value.z, value.context
        if context.canvas?
          @setContextTransform context
        if context.canvas?
          context.canvas.style.pointerEvents = 'none'
        u.elementTextParams context, "10px sans-serif", "center", "middle"

      # One of the layers is used for drawing only, not an agentset:
      @drawing = @contexts.drawing
      @drawing.clear = => u.clearContext @drawing
      # Setup spotlight layer, also not an agentset:
      @contexts.spotlight.globalCompositeOperation = "xor"

    # if isHeadless
    # # Initialize animator to headless default: 30fps, async  
    # then @animator = new ABM.Animator @, null, true
    # # Initialize animator to default: 30fps, not async
    # else 
    @animator = new ABM.Animator @
    # Set drawing controls.  Default to drawing each agentset.
    # Optimization: If any of these is set to false, the associated
    # agentset is drawn only once, remaining static after that.
    @refreshLinks = @refreshAgents = @refreshPatches = true

    # Give class prototypes a 'model' attribute that references this model.
    @Patches = @extendWithModel(ABM.Patches)
    @Patch = @extendWithModel(ABM.Patch)
    @Agents = @extendWithModel(ABM.Agents)
    @Agent = @extendWithModel(ABM.Agent)
    @Links = @extendWithModel(ABM.Links)
    @Link = @extendWithModel(ABM.Link)
    @Set = @extendWithModel(ABM.Set)

    # Initialize agentsets.
    @patchBreeds 'patches'
    @agentBreeds 'agents'
    @linkBreeds 'links'

    # Initialize model global resources
    @debugging = false
    @modelReady = false
    @globalNames = null
    @globalNames = u.ownKeys @
    @globalNames.set = false
    @startup()

    u.waitOnFiles =>
      @modelReady = true
      @setup()
      @globals() unless @globalNames.set

  # Initialize/reset world parameters.
  setWorld: (options) ->
    defaults = {
      patchSize: 13, mapSize: 32, isTorus: false, hasNeighbors: true,
      isHeadless: false}

    for own key, value of defaults
      options[key] ?= value

    options.min ?= {x: -1 * options.mapSize / 2, y: -1 * options.mapSize / 2}
    options.max ?= {x: options.mapSize / 2, y: options.mapSize / 2}
    options.mapSize = null # not passed on, because optional

    @world = {}

    for own key, value of options
      @world[key] = value

    @world.width = @world.max.x - @world.min.x + 1
    @world.height = @world.max.y - @world.min.y + 1
    @world.pxWidth = @world.width * @world.patchSize
    @world.pxHeight = @world.height * @world.patchSize
    @world.minCoordinate = {x: @world.min.x - .5, y: @world.min.y - .5}
    @world.maxCoordinate = {x: @world.max.x + .5, y: @world.max.y + .5}

  setContextTransform: (context) ->
    context.canvas.width = @world.pxWidth
    context.canvas.height = @world.pxHeight
    context.save()
    context.scale @world.patchSize, -@world.patchSize
    context.translate -(@world.minCoordinate.x), -(@world.maxCoordinate.y)

  globals: (globalNames) ->
    if globalNames?
      @globalNames = globalNames
      @globalNames.set = true
    else
      @globalNames = u.ownKeys(@).removeItems @globalNames

  # Add this model to a class's prototype. This is used in
  # the model constructor to create Patch/Patches, Agent/Agents,
  # and Link/Links classes with a built-in reference to their model.
  extendWithModel: (original) ->
    model = @
    class extendedClass extends original
      @model: model
      model: model
      constructor: ->
        super
    return extendedClass

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
  start: ->
    u.waitOn (=> @modelReady), (=> @animator.start())
    @isRunning = true
    @

  stop: ->
    @animator.stop()
    @isRunning = false
    @

  toggle: ->
    if @isRunning
      @stop()
    else
      @start()

  # Animate once by `step(); draw()`. For UI and debugging from console.
  # Will advance the ticks/draws counters.
  once: ->
    unless @animator.stopped
      @stop()
    @animator.once()
    @

  # Stop and reset the model, restarting if restart is true
  reset: (restart = false) ->
    console.log "reset: animator"
    
    @animator.reset() # stop & reset ticks/steps counters
    
    console.log "reset: contexts"
    
    # clear/resize before agentsets
    for key, value in @contexts
      if value.canvas?
        value.restore()
        @setContextTransform value
    
    console.log "reset: patches, agents, links"
    
    @patchBreeds 'patches'
    @agentBreeds 'agents'
    @linkBreeds 'links'

    u.s.spriteSheets.length = 0 # possibly null out entries?
    console.log "reset: setup"
    
    @setup()
    @setRootVars() if @debugging
    @start() if restart

#### Animation.
  
# Call the agentset draw methods if either the first draw call or
# their "refresh" flags are set.  The latter are simple optimizations
# to avoid redrawing the same static scene. Called by animator.
  draw: (force = @animator.stopped) ->
    if force or @refreshPatches or @animator.draws is 1
      @patches.draw @contexts.patches
    if force or @refreshLinks or @animator.draws is 1
      @links.draw @contexts.links
    if force or @refreshAgents  or @animator.draws is 1
      @agents.draw @contexts.agents
    if @spotlightAgent?
      @drawSpotlight @spotlightAgent, @contexts.spotlight

# Creates a spotlight effect on an agent, so we can follow it
# throughout the model.
# Use:
#
#     @setSpotliight breed.sample()
#
# to draw one of a random breed. Remove spotlight by passing `null`
  setSpotlight: (@spotlightAgent) ->
    u.clearContext @contexts.spotlight unless @spotlightAgent?

  drawSpotlight: (agent, context) ->
    u.clearContext context
    u.fillContext context, [0, 0, 0, 0.6]
    context.beginPath()
    context.arc agent.x, agent.y, 3, 0, 2 * Math.PI, false
    context.fill()

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
# These agentsets' `create` method create subclasses of Agent/Link.
# Use of <breed>.setDefault methods work as for agents/links, creating default
# values for the breed set:
#
#     @embers.setDefault "color", [255, 0, 0]
#
# ..will set the default color for just the embers. Note: patch breeds are currently
# not usable due to the patches being prebuilt.  Stay tuned.
  
  createBreeds: (list, type, agentClass, breedSet) ->
    if u.isString list
      list = list.split(" ")

    breeds = []
    breeds.classes = {}
    breeds.sets = {}

    resetType = false

    for string in list
      if string is type
        @[type] = new breedSet agentClass, string
      else
        breedClass = class Breed extends agentClass
        breed = @[string] = # add @<breed> to local scope
          new breedSet breedClass, string, agentClass::breed # create subset agentSet

        breeds.push breed
        breeds.sets[string] = breed
        breeds.classes["#{string}Class"] = breedClass

    @[type].breeds = breeds

  patchBreeds: (list, agentClass = @Patch, breedSet = @Patches) ->
    @createBreeds list, 'patches', agentClass, breedSet

  agentBreeds: (list, agentClass = @Agent, breedSet = @Agents) ->
    @createBreeds list, 'agents', agentClass, breedSet

  linkBreeds: (list, agentClass = @Link, breedSet = @Links) ->
    @createBreeds list, 'links', agentClass, breedSet
  
  # A simple debug aid which places short names in the global name space.
  # Note we avoid using the actual name, such as "patches" because this
  # can cause our modules to mistakenly depend on a global name.
  # See [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension too.
  debug: (@debugging = true) ->
    u.waitOn (=> @modelReady), (=> @setRootVars())
    @

  # TODO get rid of
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
    root.an  = @animator
    root.gl  = @globals
    root.dv  = @div
    root.root= root
    root.app = @
