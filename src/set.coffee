# An **ABM.AgentArray** is an array, with some agent/patch/link specific
# helper methods.
#
# It is a subclass of `ABM.Array` and is the base class for `ABM.BreedSet`.

class ABM.Set extends ABM.Array
  # `from` is a static wrapper function converting an array into
  # an `@model.Set`
  #
  # It gains access to all the methods below. Ex:
  #
  #     array = [1, 2, 3]
  #     @model.Set.from(array)
  #     randomNr = array.random()
  @from: (array, setType) ->
    if @model?
      setType ||= @model.Set
    else
      setType ||= ABM.Set

    array.__proto__ = setType.prototype ? setType.constructor.prototype
    array
  
  # The static `@model.Set.from` as a method.
  # Used by methods creating new sets.
  from: (array, setType = @) ->
    @model.Set.from array, setType # setType = @model.Set
    # TODO see if can be removed

  # In the examples below, we'll use an array of primitive agent objects
  # with three fields: id, x, y.
  #
  #     AS = for i in [1..5] # long form comprehension
  #       {id:i, x:u.randomInt(10), y:u.randomInt(10)}
  #     @model.Set.from AS # Convert AS to Set in place
  #        [{id: 1, x: 0, y: 1}, {id: 2, x: 8, y: 0}, {id: 3, x: 6, y: 4},
  #         {id: 4, x: 1, y: 3}, {id: 5, x: 1, y: 1}]

  # Set the default value of an agent class, return agentset
  setDefault: (name, value) ->
    @agentClass::[name] = value
    @

  # Return all agents that are not of the given breeds argument.
  # Breeds is a string of space separated names:
  #   @patches.exclude "roads houses"
  exclude: (breeds) ->
    breeds = breeds.split(" ")
    @from (o for o in @ when o.breed.name not in breeds)

  # ### Drawing
  
  # For agentsets whose agents have a `draw` method.
  # Clears the graphics context (transparent), then
  # calls each agent's draw(context) method.
  draw: (context) ->
    u.clearContext(context)
    o.draw(context) for o in @ when not o.hidden
    null
  
  # Show/Hide all of an agentset or breed.
  # To show/hide an individual object, set its prototype: o.hidden = bool
  show: ->
    o.hidden = false for o in @
    @draw(@model.contexts[@name])

  hide: ->
    o.hidden = true for o in @
    @draw(@model.contexts[@name])

  # ### Location/radius
  
  # Return all agents within d distance from given object.
  inRadius: (point, options) -> # for any objects w/ x, y
    inner = new @model.Set
    for entity in @
      if entity.distance(point) <= options.radius
        inner.push entity
    return inner
      
  # As above, but returns agents also limited to the angle `cone`
  # around a `heading` from point.
  inCone: (point, options) ->
    inner = new @model.Set
    for entity in @
      if u.inCone(options.heading, options.cone, options.radius,
          point, entity.position, @model.patches)
        inner.push entity
    return inner
