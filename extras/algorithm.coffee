# algorithm.coffee is a collection of algorithms useful in certain agent-based modeling contexts

# A generalized flood fill, designed to work on any
# agentset type. For a simpler version, take a look at [the gridpath model](../models/gridpath.html).
#
# Floodfill arguments:
#
# * startingSet: initial array of agents, often a single agent: [a]
# * fCandidate(a, nextFront) -> true if a is elegible to be added to the set of flooded agents
# * fJoin(a, prevFront) -> add a to the set of flooded agents (for example by setting a `flooded` flag)
# * fNeighbors(a) -> returns the neighbors of this agent (i.e. the agents to which this flood will attempt to spread)
#
# To flood patches, you might want
#
#     fNeighbors = (patch) -> patch.n
#
# whereas to flood agents connected by links, you might want
#
#     fNeighbors = (agent) -> agent.linkNeighbors()
#

class ABM.FloodFill
  constructor: (startingSet, @fCandidate, @fJoin, @fNeighbors) ->
    @nextFront = startingSet
    @prevFront = []
    @done = false

  nextStep: () ->
    if @done then return

    @fJoin p, @prevFront for p in @nextFront
    asetNext = []
    for p in @nextFront
      for n in @fNeighbors(p) when @fCandidate n, @nextFront
        asetNext.push n if asetNext.indexOf(n) < 0
    
    @prevFront = @nextFront
    @nextFront = asetNext

    if @nextFront.length is 0
      @done = true
  
  go: () ->
    @nextStep() while not @done