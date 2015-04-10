# ### Animator

# Because not all models have the same amimator requirements, we build a class
# for customization by the programmer.  See these URLs for more info:
#
# * [JavaScript timers doc](https://developer.mozilla.org/en-US/docs/JavaScript/Timers)
# * [Using timers & requestAnimationFrame together](http://goo.gl/ymEEX)
# * [John Resig on timers](http://goo.gl/9Q3q)
# * [jsFiddle setTimeout vs rAF](http://jsfiddle.net/calpo/H7EEE/)
# * [Timeout tutorial](http://javascript.info/tutorial/settimeout-setinterval)
# * [Events and timing in depth](http://javascript.info/tutorial/events-and-timing-depth)

class Animator
  # Create initial animator for the model, specifying default rate (fps) and multiStep.
  # If multiStep, run the draw() and step() methods separately by draw() using
  # requestAnimationFrame and step() using setTimeout.
  # Mainly debug: noRAF (no requestAnimationFrame) use setTimeout for drawing.
  # May remove after next performance review. Chrome: http://goo.gl/4yKnhR
  constructor: (@model, @rate=30, @multiStep=false, @noRAF=false) -> @reset()
  # Adjust animator.  Call before model.start()
  # in setup() to change default settings
  setRate: (@rate, @multiStep=false, @noRAF=false) -> @resetTimes() # Change rate while running?
  # start/stop model, often used for debugging and resetting model
  start: ->
    return unless @stopped # avoid multiple animates
    @resetTimes()
    @stopped = false
    @animate()
  stop: ->
    @stopped = true
    # May return to: if @animHandle? then cancelAnimationFrame @animHandle
    if @animHandle? and not @noRAF then cancelAnimationFrame @animHandle
    if @animHandle? and @noRAF then clearTimeout @animHandle
    if @timeoutHandle? then clearTimeout @timeoutHandle
    if @intervalHandle? then clearInterval @intervalHandle
    @animHandle = @timerHandle = @intervalHandle = null
  # Internal utility: reset time instance variables
  resetTimes: ->
    @startMS = @now()
    @startTick = @ticks
    @startDraw = @draws
  # Reset used by model.reset when resetting model.
  reset: -> @stop(); @ticks = @draws = 0
  # Two handlers used by animation loop
  step: -> @ticks++; @model.stepAndEmit()
  draw: -> @draws++; @model.draw()
  # step and draw the model once, mainly debugging
  once: -> @step(); @draw()
  # Get current time, with high resolution timer if available
  now: -> (performance ? Date).now()
  # Time in ms since starting animator
  ms: -> @now()-@startMS
  # Get ticks/draws per second. They will differ if multiStep.
  # The "if" is to avoid from ms=0
  ticksPerSec: ->
    if (dt = @ticks-@startTick) is 0 then 0 else Math.round dt*1000/@ms()
  drawsPerSec: ->
    if (dt = @draws-@startDraw) is 0 then 0 else Math.round dt*1000/@ms()
  # Return a status string for debugging and logging performance
  toString: ->
    "ticks: #{@ticks}, draws: #{@draws}, rate: #{@rate}
     tps/dps: #{@ticksPerSec()}/#{@drawsPerSec()}"
  # Animation via setTimeout and requestAnimationFrame
  animateSteps: =>
    @step()
    @timeoutHandle = setTimeout @animateSteps, 2 unless @stopped
  animateDraws: =>
    if @drawsPerSec() < @rate # throttle drawing to @rate
      @step() unless @multiStep
      @draw()
    if @noRAF
      @animHandle = setTimeout @animateDraws, 2 unless @stopped
      u.deprecated "avoiding rAF"
    else
      @animHandle = requestAnimationFrame @animateDraws unless @stopped
  animate: ->
    @animateSteps() if @multiStep
    @animateDraws() # unless @isHeadless and @multiStep
