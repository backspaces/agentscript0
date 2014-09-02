# ### Links
  
# Class Links is a subclass of Set which stores instances of Link
# or subclasses of Link

class ABM.Links extends ABM.BreedSet
  # Constructor: super creates the empty Set instance and installs
  # the agentClass (breed) variable shared by all the Links in this set.
  constructor: -> # agentClass, name, mainSet
    super # call super with all the args I was called with

  # Factory: Add 1 or more links from the from agent to the to agent(s) which
  # can be a single agent or an array of agents. The optional init
  # proc is called on the new link after inserting in the agentSet.
  create: (from, to, init = ->) -> # returns array of new links too
    to = [to] unless to.length?
    ((o) -> init(o); o) @add new @agentClass from, a for a in to # too tricky?
  
  # Remove all links from set via link.die()
  # Note call in reverse order to optimize list restructuring.
  clear: ->
    while @any()
      @last().die()

    null # tricky, each die modifies list

  # Return all the nodes in this agentset, with duplicates
  # included.  If 4 links have the same endpoint, it will
  # appear 4 times.
  nodesWithDups: -> # all link ends, w / dups
    set = new @model.Set

    for link in @
      set.push link.from, link.to

    set

  # Returns all the nodes in this agentset with duplicates removed.
  nodes: ->
    @nodesWithDups().uniq()
