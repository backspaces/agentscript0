# A **BreedSet** is an ABM.Set (which is an ABM.Array), along with a
# class, agentClass, whose instances are the items of the array.
# Instances of the class are created by the `create` factory method of
# a BreedSet.
#
# It is a subclass of `ABM.Set` and is the base class for `Patches`,
# `Agents`, and `Links`. A Set keeps track of all its created
# instances. It also provides, much like the **ABM.util** module, some
# methods shared by all subclasses of Set.
#
# A model contains three BreedSets:
#
# * `patches`: the model's "world" grid
# * `agents`: the model's agents living on the patches
# * `links`: the network links connecting agent pairs
#
# See NetLogo [documentation](http://ccl.northwestern.edu/netlogo/docs/)
# for explanation of the overall semantics of Agent Based Modeling
# used by Sets as well as Patches, Agents, and Links.
#
# Because we are an array subset, @[i] == this[i] == agentset[i]

class ABM.BreedSet extends ABM.Set
  # In the examples below, we'll use an array of primitive agent objects
  # with three fields: id, x, y.
  #
  #     AS = for i in [1..5] # long form comprehension
  #       {id:i, x:u.randomInt(10), y:u.randomInt(10)}
  #     ABM.BreedSet.from AS # Convert AS to Set in place
  #        [{id: 1, x: 0, y: 1}, {id: 2, x: 8, y: 0}, {id: 3, x: 6, y: 4},
  #         {id: 4, x: 1, y: 3}, {id: 5, x: 1, y: 1}]

  # ### Constructor and add/remove agents.
  
  # Create an empty `Set` and initialize the `ID` counter for add().
  # If mainSet is supplied, the new agentset is a sub-array of mainSet.
  # This sub-array feature is how breeds are managed, see class `Model`
  constructor: (agentClass, name, mainSet) ->
    super(0) # doesn't yield empty array if already instances in the mainSet
    @agentClass = agentClass
    @name = name
    @mainSet = mainSet
    unless @mainSet?
      # Do not set breeds & ID if I'm a subset
      @breeds = []
      @ID = 0
    @agentClass::breed = @ # let the breed know I'm it's agentSet

  # Abstract method used by subclasses to create and add their instances.
  create: ->

  # Add an agent to the list. Only used by agentset factory methods. Adds
  # the `id` property to all agents. Increment `ID`.
  # Returns the object for chaining.
  #
  # By "agent" we mean an instance of `Patch`, `Agent` and `Link` and their breeds
  originalPush: @::push
  push: (object...) ->
    if object.length > 1
      for item in object
        @push item
    else
      object = object[0]
      @originalPush object

      if @mainSet?
        @mainSet.push object
      else
        if object.id?
          if object.breed? and object.breed.name is not @name
            object.id = @ID++
        else
          object.id = @ID++

    object

  # TODO remove
  add: (object) ->
    @push object

  # Remove an agent from the agentset, returning the agentset.
  # Note this does not change delete id or change the set's ID, thus
  # an agentset can have gaps in terms of their id's. 
  #
  #     AS.remove(AS[3]) # [{id: 0, x: 0, y: 1}, {id: 1, x: 8, y: 0},
  #                         {id: 2, x: 6, y: 4}, {id: 4, x: 1, y: 1}] 
  remove: (object) ->
    if @mainSet?
      @mainSet.remove object
    u.array.remove @, object
    @

  pop: () ->
    object = @last()
    @remove(object)
    object

  # Move an agent from its BreedSet to be in this BreedSet.
  #
  setBreed: (agent) ->
    agent.breed.remove agent
    @push agent
    proto = agent.__proto__ = @agentClass.prototype
    delete agent[key] for own key, value of agent when proto[key]?
    agent

  # Floodfill arguments:
  #
  # * aset: initial array of agents, often a single agent: [a]
  # * fCandidate(a, asetLast) -> true if a is elegible to be added to the set
  # * fJoin(a, asetLast) -> adds a to the agentset, usually by setting a variable
  # * fCallback(asetLast, asetNext) -> optional function to be called each iteration of floodfill;
  # if fCallback returns true, the flood is aborted
  # * fNeighbors(a) -> returns the neighbors of this agent
  # * asetLast: the array of the last set of agents to join the flood;
  # gets passed into fJoin, fCandidate, and fCallback
  floodFill: (aset, fCandidate, fJoin, fCallback, fNeighbors, asetLast = []) ->
    floodFunc = @floodFillOnce(aset, fCandidate, fJoin, fCallback, fNeighbors, asetLast)
    floodFunc = floodFunc() while floodFunc

  # Move one step forward in a floodfill. floodFillOnce() returns a function that performs the next step of the flood.
  # This is useful if you want to watch your flood progress as an animation.
  floodFillOnce: (aset, fCandidate, fJoin, fCallback, fNeighbors, asetLast = []) ->
    fJoin p, asetLast for p in aset
    asetNext = []
    for p in aset
      for n in fNeighbors(p) when fCandidate n, aset
        asetNext.push n if asetNext.indexOf(n) < 0
    stopEarly = fCallback and fCallback(aset, asetNext)
    if stopEarly or asetNext.length is 0 then return null
    else return () =>
      @floodFillOnce asetNext, fCandidate, fJoin, fCallback, fNeighbors, aset
  
  # Similar to above but sorted via `id`.
  # TODO remove
  asOrderedSet: (a) ->
    @from(a).sort("id")
