# A NetLogo-like mouse handler.
# See: [addEventListener](http://goo.gl/dq0nN)
class ABM.Mouse
  # Create and start mouse obj, args: name of div, and a callback method.
  constructor: (@model, @callback) ->
    @lastX = Infinity
    @lastY = Infinity
    @div = @model.div
    @start()

  # Start/stop the mouseListeners.  Note that NetLogo's model is to have
  # mouse move events always on, rather than starting/stopping them
  # on mouse down/up.  We may want do make that optional, using the
  # more standard down/up enabling move events.
  start: -> # Note: multiple calls safe
    @div.addEventListener("mousedown", @handleMouseDown, false)
    document.body.addEventListener("mouseup", @handleMouseUp, false)
    @div.addEventListener("mousemove", @handleMouseMove, false)
    @lastX = @lastY = @x = @y= @pixX = @pixY = NaN
    @moved = @down = false

  stop: -> # Note: multiple calls safe
    @div.removeEventListener("mousedown", @handleMouseDown, false)
    document.body.removeEventListener("mouseup", @handleMouseUp, false)
    @div.removeEventListener("mousemove", @handleMouseMove, false)
    @lastX = @lastY = @x = @y = @pixX = @pixY = NaN
    @moved = @down = false

  # Handlers for eventListeners
  handleMouseDown: (e) =>
    @down = true
    @setXY e

  handleMouseUp: =>
    @down = false

  handleMouseMove: (e) =>
    @setXY e

  setXY: (e) ->
    @lastX = @x
    @lastY = @y
    @pixX = e.offsetX
    @pixY = e.offsetY
    [@x, @y] = @model.patches.pixelXYtoPatchXY(@pixX, @pixY)
    @moved = (@x isnt @lastX) or (@y isnt @lastY)
    @callback(e) if @callback?
