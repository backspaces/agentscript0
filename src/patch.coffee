# ### Patch
  
# Class Patch instances represent a rectangle on a grid.  They hold variables
# that are in the patches the agents live on. The set of all patches (@model.patches)
# is the world on which the agents live and the model runs.
class ABM.Patch
  # Constructor & Class Variables:
  # * id:          unique identifier, promoted by agentset create() factory method
  # * breed:       the agentset this agent belongs to
  # * position:    position on the patch grid, .x and .y in patch coordinates
  # * color:       the color of the patch as an RGBA array, A optional.
  # * hidden:      whether or not to draw this patch
  # * label:       text for the patch
  # * labelColor:  the color of my label text
  # * labelOffset: the x, y offset of my label from my x, y location

  id: null              # unique id, promoted by agentset create factory method
  breed: null           # set by the agentSet owning this patch
  position: null        # The patch position in the patch grid, in .x and .y
  color: [0, 0, 0]      # The patch color
  hidden: false         # draw me?
  label: null           # text for the patch
  labelColor: [0, 0, 0] # text color
  labelOffset: [0, 0]   # text offset from the patch center
  agents: null          # agents on this patch
  
  # New Patch: Just set x, y.
  #constructor: (@x, @y) ->
  constructor: (@position) ->
    @neighborsCache = {}
    @agents = new ABM.Array

  # Return a string representation of the patch.
  toString: ->
    "{id:#{@id} position: {x: #{@position.x}, y: #{@position.y}}," +
    "c: #{@color}}"

  # Draw the patch and its text label if there is one.
  draw: (context) ->
    context.fillStyle = u.colorString @color
    context.fillRect @position.x - .5, @position.y - .5, 1, 1
    if @label? # REMIND: should be 2nd pass.
      position = @breed.patchXYtoPixelXY @position
      u.contextDrawText context, @label, position.x + @labelOffset[0],
        position.y + @labelOffset[1], @labelColor
  
  empty: ->
    @agents.empty()

  # Returns true if this patch is on the edge of the grid.
  isOnEdge: ->
    @position.x is @breed.min.x or @position.x is @breed.max.x or \
    @position.y is @breed.min.y or @position.y is @breed.max.y
  
  # Factory: Create num new agents on this patch. The optional init
  # proc is called on the new agent after inserting in its agentSet.
  sprout: (number = 1, breed = @model.agents, init = ->) ->
    breed.create number, (agent) => # fat arrow so that @ = this patch
      agent.moveTo @position
      init(agent)
      agent

  # Return distance in patch coordinates from me to given agent/patch
  # using patch topology (isTorus)
  distance: (point) -> # o any object w/ x, y, patch or agent
    u.distance @position, point, @model.patches

  # Get neighbors for patch
  neighbors: (options) ->
    options ?= 1

    if u.isNumber(options)
      options = {range: options}

    if not options.cache? or options.cache
      cacheKey = JSON.stringify(options)
      neighbors = @neighborsCache[cacheKey]

    if not neighbors?
      if options.radius
        square = @neighbors(range: options.radius, meToo: options.meToo,
          cache: options.cache)
        if options.cone
          neighbors = square.inCone(@position, options)
          unless options.cache
            cacheKey = null
            # cone has variable heading, better not cache by default
        else
          neighbors = square.inRadius(@position, options)
      else if options.diamond
        neighbors = @diamondNeighbors(options.diamond, options.meToo)
      else
        neighbors = @breed.patchRectangle(@, options.range, options.range, options.meToo)
  
      if cacheKey?
        @neighborsCache[cacheKey] = neighbors

    return neighbors

  # Not to be used directly, will not cache.
  diamondNeighbors: (range, meToo) ->
    neighbors = @breed.patchRectangleNullPadded @, range, range, true
    diamond = new @model.Set
    counter = 0
    row = 0
    column = -1
    span = range * 2 + 1

    for neighbor in neighbors
      row = counter % span
      if row == 0
        column += 1
      distanceColumn = Math.abs(column - range)
      distanceRow = Math.abs(row - range)
      if distanceRow + distanceColumn <= range and
          (meToo or distanceRow + distanceColumn != 0)
        diamond.push neighbor
      counter += 1

    diamond.remove(null)

    return diamond
