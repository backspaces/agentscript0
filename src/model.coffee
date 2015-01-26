# Class Model is the control center for our AgentSets: Patches, Agents and Links.
# Creating new models is done by subclassing class Model and overriding two
# virtual/abstract methods: `setup()` and `step()`

# ### Class Model

class Model
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
    if typeof divOrOpts is 'string' # using deprecated constructor
      opts = { divOrOpts, size, minX, maxX, minY, maxY, isTorus, hasNeighbors, isHeadless }
    else
      opts = divOrOpts

    isHeadless = opts.isHeadless = opts.isHeadless or not opts.div?
    
    @setWorld opts

    @contexts = {}
    unless isHeadless
      @view = new CanvasTileView(@, opts)
      @contexts = @view.contexts # copy contexts over from view
      @drawing = @contexts.drawing
      @div = @view.div

    @anim = new Animator @

    # Create model-local versions of AgentSets and their
    # agent class.  Clone the agent classes so that they
    # can use "defaults" in isolation when multiple
    # models run on a page.
    @Patches = Patches; @Patch = u.cloneClass(Patch)
    @Agents = Agents; @Agent = u.cloneClass(Agent)
    @Links = Links; @Link = u.cloneClass(Link)

    # Initialize agentsets.
    @patches = new @Patches @, @Patch, "patches"
    @agents = new @Agents @, @Agent, "agents"
    @links = new @Links @, @Link, "links"

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
    console.log "reset: view"
    @view.reset() # clear/resize canvas transforms before agentsets
    console.log "reset: patches"
    @patches = new @Patches @, @Patch, "patches"
    console.log "reset: agents"
    @agents = new @Agents @, @Agent, "agents"
    console.log "reset: links"
    @links = new @Links @, @Link, "links"
    Shapes.spriteSheets.length = 0 # possibly null out entries?
    console.log "reset: setup"
    @setupAndEmit()
    @setRootVars() if @debugging
    @start() if restart

#### Animation

# Called by animator.
  draw: (force=@anim.stopped) ->
    @view.draw(force)
    @emit('draw')

#### Wrappers around user-implemented methods

  setupAndEmit: ->
    @setup()
    @emit('setup')
  stepAndEmit: ->
    @step()
    @emit('step')

#### Misc Rendering

  # Creates a spotlight effect on an agent, so we can follow it throughout the model.
  # Use:
  #
  #     @setSpotliight breed.oneOf()
  #
  # to draw one of a random breed. Remove spotlight by passing `null`
  setSpotlight: (@spotlightAgent) ->
    @view.setSpotlight @spotlightAgent

  # Draws, or "imports" an image URL into the drawing layer.
  # The image is scaled to fit the drawing layer.
  #
  # This is an async load, see this
  # [new Image()](http://javascript.mfields.org/2011/creating-an-image-in-javascript/)
  # tutorial.  We draw the image into the drawing layer as
  # soon as the onload callback executes.
  importDrawing: (imageSrc, f) ->
    u.importImage imageSrc, (img) => # fat arrow, this context
      @installDrawing img
      f() if f?

  # Direct install image into the given context, not async.
  # Alias for the view's particular implementation.
  installDrawing: (img, ctx) ->
    @view.installDrawing(img, ctx)

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
      className = breedName.charAt(0).toUpperCase() + breedName.substr(1)
      breedClass = u.cloneClass baseClass, className # breedClass = class Breed extends baseClass
      breed = @[breedName] = # add @<breed> to local scope
        new baseSet @, breedClass, breedName, baseClass::breed # create subset agentSet
      breeds.push breed
      breeds.sets[breedName] = breed
      breeds.classes["#{breedName}Class"] = breedClass
    breeds
  patchBreeds: (breedNames) -> @patches.breeds = @createBreeds breedNames, @Patch, @Patches
  agentBreeds: (breedNames) -> @agents.breeds  = @createBreeds breedNames, @Agent, @Agents
  linkBreeds:  (breedNames) -> @links.breeds   = @createBreeds breedNames, @Link,  @Links

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
    window.psc = @Patches
    window.pc  = @Patch
    window.ps  = @patches
    window.p0  = @patches[0]
    window.asc = @Agents
    window.ac  = @Agent
    window.as  = @agents
    window.a0  = @agents[0]
    window.lsc = @Links
    window.lc  = @Link
    window.ls  = @links
    window.l0  = @links[0]
    window.dr  = @drawing
    window.u   = Util
    window.cx  = @contexts
    window.an  = @anim
    window.gl  = @globals()
    window.dv  = @div
    window.app = @

# Create the namespace **ABM** for our project.
# Note here `this` or `@` == window due to coffeescript wrapper call.
# Thus @ABM is placed in the global scope.
# @ABM={}


@ABM = {
  util    # deprecated
  shapes  # deprecated
  Util
  Color
  ColorMaps
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
