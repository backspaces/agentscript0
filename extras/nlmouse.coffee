# A NetLogo-like mouse handler. See Mouse for a sophisticated delegation mouse
#
# Event locations, clientX/Y, screenX/Y, offsetX/Y, pageX/Y can be confusing.
# See: [this gist](https://gist.github.com/branneman/fc66785c082099298955)
# and [this post](http://www.jacklmoore.com/notes/mouse-position/) and others.
class ABM.NLMouse
  # Create and start mouse obj, args: a model, and a callback method.
  constructor: (@model, @callback) ->
    @div = @model.div
    @start()

  # Start/stop the mouseListeners.  Note that NetLogo's model is to have
  # mouse move events always on, rather than starting/stopping them
  # on mouse down/up.  We may want do make that optional, using the
  # more standard down/up enabling move events.
  resetParams: -> @x = @y = NaN; @moved = @down = false
  start: -> # Note: multiple calls safe
    @div.addEventListener("mousedown", @handleMouseDown, false)
    document.body.addEventListener("mouseup", @handleMouseUp, false)
    @div.addEventListener("mousemove", @handleMouseMove, false)
    @resetParams()
  stop: ->  # Note: multiple calls safe
    @div.removeEventListener("mousedown", @handleMouseDown, false)
    document.body.removeEventListener("mouseup", @handleMouseUp, false)
    @div.removeEventListener("mousemove", @handleMouseMove, false)
    @resetParams()

  # Handlers for eventListeners
  generalHandler: (e, @down, @moved) ->
    @setXY e
    @callback(e) if @callback?
  handleMouseDown: (e) => @generalHandler e, true, false
  handleMouseUp: (e) => @generalHandler e, false, false
  handleMouseMove: (e) => @generalHandler e, @down, true

  # set x, y to be event location in patch coordinates.
  setXY: (e) ->
    rect = @div.getBoundingClientRect()
    pixX = e.clientX - rect.left
    pixY = e.clientY - rect.top
    [@x, @y] = @model.patches.pixelXYtoPatchXY(pixX, pixY)
