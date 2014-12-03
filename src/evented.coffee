# ### Evented

# Modified from https://gist.github.com/contra/2759355.

# Instances of Model emit `'step'` and `'draw'` events so that an arbitrary
# function can be triggered every time the model is stepped or drawn (e.g. the patch inspector).

class Evented
  constructor: () ->
    @events = {}

  emit: (name, args...) ->
    if @events[name]
      cb args... for cb in @events[name]

  on: (name, cb) ->
    (@events[name]?=[]).push cb

  off: (name, cb) ->
    if @events[name]
      if cb then @events[name] = (l for l in @events[name] when l isnt cb)
      else delete @events[name]