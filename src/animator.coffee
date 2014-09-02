# Class Model is the control center for our Sets: Patches, Agents and Links.
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
  constructor: (@model, @rate = 30, @multiStep = model.world.isHeadless) ->
    @isHeadless = model.world.isHeadless
    @reset()

  # Adjust animator.  Call before model.start()
  # in setup() to change default settings
  setRate: (@rate, @multiStep = @isHeadless) -> @resetTimes() # Change rate while running?

  # start/stop model, often used for debugging and resetting model
  start: ->
    return unless @stopped # avoid multiple animates
    @resetTimes()
    @stopped = false
    @animate()

  stop: ->
    @stopped = true
    if @animatorHandle?
      cancelAnimFrame @animatorHandle
    if @timeoutHandle?
      clearTimeout @timeoutHandle
    if @intervalHandle?
      clearInterval @intervalHandle
    @animatorHandle = @timerHandle = @intervalHandle = null

  # Internal util: reset time instance variables
  resetTimes: ->
    @startMS = @now()
    @startTick = @ticks
    @startDraw = @draws

  # Reset used by model.reset when resetting model.
  reset: ->
    @stop()
    @ticks = @draws = 0

  # Two handlers used by animation loop
  step: ->
    @ticks++
    @model.step()

  draw: ->
    @draws++
    @model.draw()

  # step and draw the model once, mainly debugging
  once: ->
    @step()
    @draw()

  # Get current time, with high resolution timer if available
  now: -> (performance ? Date).now()

  # Time in ms since starting animator
  ms: -> @now() - @startMS

  # Get ticks/draws per second. They will differ if multiStep.
  # The "if" is to avoid from ms=0
  ticksPerSec: ->
    elapsed = @ticks - @startTick
    if elapsed is 0
      0
    else
      Math.round elapsed * 1000 / @ms()

  drawsPerSec: ->
    elapsed = @draws - @startDraw
    if elapsed is 0
      0
    else
      Math.round elapsed * 1000 / @ms()

  # Return a status string for debugging and logging performance
  toString: -> 
    "ticks: #{@ticks}, draws: #{@draws}, rate: #{@rate} " +
      "tps/dps: #{@ticksPerSec()}/#{@drawsPerSec()}"

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
    @animatorHandle = requestAnimFrame @animateDraws unless @stopped

  animate: ->
    @animateSteps() if @multiStep
    @animateDraws() unless @isHeadless and @multiStep
