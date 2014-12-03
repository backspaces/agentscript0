# This is a general template for creating models.
#
# To build your own model, extend class ABM.Model supplying the
# two abstract methods `setup` and `step`.  `@foo` signifies
# an instance variable or method.
# See [CoffeeScript docs](http://jashkenas.github.com/coffee-script/#classes)
# for explanation of context of a class and its constructor.
#
# We do not provide a constructor of our own.
# CoffeeScript automatically calls `Model.constructor <args>`
# and `setup` will be called by `Model.constructor`. See:
#
#     model = new MyModel "layers", 13, -16, 16, -16, 16
#
# below, which passes all its arguments to `Model`

 # ABM.Util, ABM.Shapes aliases
u = ABM.Util; Shapes = ABM.Shapes
log = (arg) -> console.log arg
class MyModel extends ABM.Model
  # `startup` initializes resources used by `setup` and `step`.
  # This is called by the constructor which waits for all files
  # processed by `starup`.  Useful for large files, but here just
  # for an example, not needed by simple models.
  startup: -> # called by constructor
    # Add new shapes.
    Shapes.add "bowtie", true, (c) ->
      Shapes.poly c, [[-.5,-.5],[.5,.5],[-.5,.5],[.5,-.5]]
    # The following two example lines don't work when opened locally
    # in Chrome (they work fine from a webserver). Uncomment if you'd
    # like to add custom images.
    if window.location.protocol is "file:"
      console.log "Warning: file:// protocol used!"
      console.log "This prevents two user defined image shapes from loading!"
      console.log "Use http:// protocol to enable image shapes."
    else
      Shapes.add "cc", true, u.importImage("data/coffee.png")
      Shapes.add "redfish", false, u.importImage("data/redfish64t.png")

  # Initialize our model via the `setup` abstract method.
  # This model simply creates `population` agents with
  # arbitrary shapes with `size` size and `speed` velocity.
  # We also periodically change the patch colors to random gray values.
  setup: -> # called by Model.constructor
  # First, we initialize our model instance variables.
  # Most instance variables are parameters we would like
  # an external UI to setup for us.
    @population = 100
    @size = 1.5   # size in patch coords
    @speed = .5   # move forward this amount in patch coords
    @wiggle = u.degToRad(30) # degrees/radians to wiggle
    @startCircle = true  # initialize agents randomly or in circle

    # Set the default agent size (conserves storage)
    @agents.setDefault "size", @size
    # Set the agent to convert shape to bitmap for better performance.
    @agents.setUseSprites()

    # Set animation to 30fps, without multiple steps per draw:
    @anim.setRate 30, false

    # The patch grid will have been setup for us.  Here we initialize
    # patch variables, either built-in ones or any new patch variables
    # our model needs. In this case, we set the built-in color to a
    # random gray value.
    for p in @patches
      p.color = u.randomGray()
      # Set x,y axes different color, use [0,0,0,0] for transparent pixel test
      p.color = [255,0,0] if p.x is 0 or p.y is 0

    # Our empty @agents AgentSet will have been created.  Here we
    # add `population` Agents we use in our model.
    # We set the build-in Agent variables `size` and `shape`
    # and layout the agents randomly or in a circle depending
    # on our modeel's `startCircle` variable.
    for a in @agents.create @population
      a.shape = u.oneOf Shapes.names() # random shapes
      if @startCircle
        a.forward @patches.maxX/2 # start in circle
      else
        a.setXY @patches.randomPt()... # set random location

    # Print number of agents and patches to the console.
    # Note CoffeeScript
    # [string interpolation](http://jashkenas.github.com/coffee-script/#strings)
    log "total agents: #{@agents.length}, total patches: #{@patches.length}"
    # Print number of agents with each shape
    for s in Shapes.names()
      num = @agents.getPropWith("shape", s).length
      log "#{num} #{s}"

  # Update our model via the second abstract method, `step`
  step: ->  # called by Model.animate
    # First, update our agents via `updateAgents` below
    @updateAgents(a) for a in @agents
    # Every 100 steps, update our patches, print stats to
    # the console, and use the Model refresh flag to redraw
    # the patches. Otherwise don't refresh.
    if @anim.ticks % 100 is 0
      @updatePatches(p) for p in @patches
      @reportInfo()
      @refreshPatches = true
      # Add use of our first pull request:
      @setSpotlight @agents.oneOf() if @anim.ticks is 300
      @setSpotlight null if @anim.ticks is 600
    else
      @refreshPatches = false
    if @anim.draws is 2 # Show the sprite sheet if there is one after first draw
      sheet = u.last(Shapes.spriteSheets) if Shapes.spriteSheets.length isnt 0
      if sheet?
        log sheet
        document.getElementById("play").appendChild(sheet.canvas)
    log @anim.toString() if @anim.ticks % 100 is 0
    # Stop the animation at 1000. Restart by `ABM.model.start()` in console.
    if @anim.ticks is 1000
      log "..stopping, restart by app.start()"
      @stop()

  # Three of our own methods to manage agents & patches
  # and report model state.
  updateAgents: (a) -> # a is agent
    # Have our agent "wiggle" by changing
    # our heading by +/- `wiggle/2` radians
    a.rotate u.randomCentered @wiggle
    # Then move forward by our speed.
    a.forward @speed
  updatePatches: (p) -> # p is patch
    # Update patch colors to be a random gray.
    # Note we modify the existing color, GC minimization.
    u.randomGray(p.color) if p.x isnt 0 and p.y isnt 0 # aviod GC, reuse color
  reportInfo: ->
    # Report the average heading, in radians and degrees
    headings = @agents.getProp "heading"
    avgHeading = (headings.reduce (a,b)->a+b) / @agents.length
    # Note: multiline strings. block strings also available.
    log "
average heading of agents:
#{avgHeading.toFixed(2)} radians,
#{u.radToDeg(avgHeading).toFixed(2)} degrees"

# Now that we've build our class, we call it with Model's
# constructor arguments:
#
#     divName, patchSize, minX, maxX, minY, maxY,
#     isTorus = false, hasNeighbors = true
#
# Note: Netlogo defaults 13, -16, 16, -16, 16 <br>
# for patchSize, minX, maxX, minY, maxY
model = new MyModel({
  div: "layers",
  size: 13,
  minX: -16,
  maxX: 16,
  minY: -16,
  maxY: 16,
  isTorus: true,
  hasNeighbors: false
})
.debug() # Debug: Put Model vars in global name space
.start() # Run model immediately after startup initialization
