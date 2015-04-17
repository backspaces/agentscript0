# ### Links

# Class Links is a subclass of AgentSet which stores instances of Link
# or subclasses of Link
class Links extends AgentSet
  # Constructor: super creates the empty AgentSet instance and installs
  # the agentClass (breed) variable shared by all the Links in this set.
  constructor: -> # model, agentClass, name, mainSet
    super # call super with all the args I was called with

  # Factory: Add 1 or more links from the from agent to the to agent(s) which
  # can be a single agent or an array of agents. The optional init
  # proc is called on the new link after inserting in the agentSet.
  create: (from, to, init = ->) -> # returns array of new links too
    to = [to] unless to.length?
    ((o) -> init(o); o) @add new @agentClass from, a for a in to # too tricky?

  # Remove all links from set via link.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list

  # Return all the nodes in this agentset, with duplicates
  # included.  If 4 links have the same endpoint, it will
  # appear 4 times.
  allEnds: -> # all link ends, w/ dups
    n = @asSet []
    n.push l.end1, l.end2 for l in @
    n

  # Returns all the nodes in this agentset sorted by ID and with
  # duplicates removed.
  nodes: -> # allEnds without dups
    @allEnds().sortById().uniq()

  # Circle Layout: position the turtles in the list in an equally
  # spaced circle of the given radius, with the initial turtle
  # at the given start angle (default to pi/2 or "up") and in the
  # +1 or -1 direction (counter clockwise or clockwise)
  # defaulting to -1 (clockwise).
  layoutCircle: (list, radius, startAngle = Math.PI/2, direction = -1) ->
    dTheta = 2*Math.PI/list.length
    for a, i in list
      a.setXY 0, 0
      a.heading = startAngle + direction*dTheta*i
      a.forward radius
    null

  setDraggable: () ->
    @on 'dragstart', (mouseEvent) =>
      mouseEvent.target.dragging = true

    @on 'dragend', (mouseEvent) =>
      mouseEvent.target.dragging = false

    @on 'drag', (mouseEvent) =>
      end1 = mouseEvent.target.end1
      end2 = mouseEvent.target.end2
      end1.setXY(end1.x - mouseEvent.dx, end1.y - mouseEvent.dy)
      end2.setXY(end2.x - mouseEvent.dx, end2.y - mouseEvent.dy)
