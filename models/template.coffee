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

# ABM.Util, ABM.Shapes, ABM.ColorMaps aliases
u = ABM.Util; Shapes = ABM.Shapes; Maps = ABM.ColorMaps
log = (arg) -> console.log arg
class TemplateModel extends ABM.Model
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
      Shapes.add "cup", true, u.importImage("data/coffee.png")
      Shapes.add "redfish", false, u.importImage("data/redfish64t.png")
      Shapes.add "twitter", false, u.importImage("data/twitter.png")

  # Initialize our model via the `setup` abstract method.
  # This model simply creates `population` turtles with
  # arbitrary shapes with `size` size and `speed` velocity.
  # We also periodically change the patch colors to random gray values.
  setup: -> # called by Model.constructor
  # First, we initialize our model instance variables.
  # Most instance variables are parameters we would like
  # an external UI to setup for us.
    @population = 100
    @size = 2.0   # size in patch coords
    @speed = .5   # move forward this amount in patch coords
    @wiggle = u.degToRad(30) # degrees/radians to wiggle
    @startCircle = true  # initialize turtles randomly or in circle

    # Set the default turtle size; save storage over setting size for each turtle
    @turtles.setDefault "size", @size
    # Set the turtle to convert shape to bitmap for better performance.
    @turtles.setUseSprites()

    # Set animation to 30fps, without multiple steps per draw:
    @anim.setRate 30, false

    # The patch grid will have been setup for us.  Here we initialize
    # patch variables, either built-in ones or any new patch variables
    # our model needs. In this case, we set the built-in color to a
    # random gray value.
    for p in @patches
      p.color = Maps.randomGray(0,100)
      # Set x,y axes different color
      p.color = "blue" if p.x is 0 or p.y is 0

    # Our empty @turtles AgentSet will have been created.  Here we
    # add `population` Turtles we use in our model.
    # We set the build-in Turtle variables `size` and `shape`
    # and layout the turtles randomly or in a circle depending
    # on our modeel's `startCircle` variable.
    for a in @turtles.create @population
      a.shape = u.oneOf Shapes.names() # random shapes
      if @startCircle
        a.forward @patches.maxX/2 # start in circle
      else
        a.setXY @patches.randomPt()... # set random location

    # Print number of turtles and patches to the console.
    # Note CoffeeScript
    # [string interpolation](http://jashkenas.github.com/coffee-script/#strings)
    log "total turtles: #{@turtles.length}, total patches: #{@patches.length}"
    # Print number of turtles with each shape
    for s in Shapes.names()
      num = @turtles.getPropWith("shape", s).length
      log "#{num} #{s}"
    console.log "Patch(0,0): ", @patches.patchXY 0,0

  # Update our model via the second abstract method, `step`
  step: ->  # called by Model.animate
    # First, update our turtles via `updateTurtles` below
    @updateTurtles(a) for a in @turtles
    # Every 100 steps, update our patches, print stats to
    # the console, and use the Model refresh flag to redraw
    # the patches. Otherwise don't refresh.
    if @anim.ticks % 100 is 0
      @updatePatches(p) for p in @patches
      @reportInfo()
      @refreshPatches = true
      # Add use of our first pull request:
      @setSpotlight @turtles.oneOf() if @anim.ticks is 300
      @setSpotlight null if @anim.ticks is 600
    else
      @refreshPatches = false
    # Stop the animation at 1000. Restart by `ABM.model.start()` in console.
    if @anim.ticks is 1000
      log "..stopping, restart by app.start()"
      @stop()

  # Three of our own methods to manage turtles & patches
  # and report model state.
  updateTurtles: (a) -> # a is turtle
    # Have our turtle "wiggle" by changing
    # our heading by +/- `wiggle/2` radians
    a.rotate u.randomCentered @wiggle
    # Then move forward by our speed.
    a.forward @speed
  updatePatches: (p) -> # p is patch
    # Update patch colors to be a random gray.
    # u.randomGray(p.color) if p.x isnt 0 and p.y isnt 0 # aviod GC, reuse color
    # Avoid Garbage collection by using a colormap
    p.color = Maps.randomColor() if p.x isnt 0 and p.y isnt 0
  reportInfo: ->
    # Report the average heading, in radians and degrees
    headings = @turtles.getProp "heading"
    avgHeading = (headings.reduce (a,b)->a+b) / @turtles.length
    # Note: multiline strings. block strings also available.
    log "
average heading of turtles:
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
templateModel = new TemplateModel({
  div: "layers",
  size: 13,
  minX: -16,
  maxX: 16,
  minY: -16,
  maxY: 16,
  isTorus: true,
  hasNeighbors: false
}).debug() # print stats, show sprites, put model name in window
  .start() # Run model immediately after startup initialization
