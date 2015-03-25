# ### Patch

# Class Patch instances represent a rectangle on a grid.  They hold variables
# that are in the patches the agents live on.  The set of all patches (@model.patches)
# is the world on which the agents live and the model runs.
class Patch
  # Constructor & Class Variables:
  # * id:         unique id, promoted by agentset create() factory method
  # * breed:      the agentset this agent belongs to
  # * x,y:        position on the patch grid, in patch coordinates
  # * color:      the color of the patch as an RGBA array, A optional.
  # * hidden:     whether or not to draw this patch
  # * label:      text for the patch
  # * labelColor: the color of my label text
  # * labelOffset:the x,y offset of my label from my x,y location
  # * n,n4:       adjacent neighbors: n: 8 patches, n4: N,E,S,W patches.
  # * pRect:      cached rect for performance
  #
  # Patches may not need their neighbors, thus we use a default
  # of none.  n and n4 are promoted by the Patches agent set
  # if world.neighbors is true, the default.

  id: null            # unique id, promoted by agentset create factory method
  breed: null         # set by the agentSet owning this patch
  x:null; y:null      # The patch position in the patch grid
  n:null; n4:null     # The neighbors, n: 8, n4: 4. null OK if model doesn't need them.
  # color: [0,0,0]      # The patch color
  hidden: false       # draw me?
  label: null         # text for the patch
  # labelColor: [0,0,0] # text color
  labelOffset: [0,0]  # text offset from the patch center
  pRect: null         # Performance: cached rect of neighborhood larger than n.

  # New Patch: Just set x,y. Neighbors set by Patches constructor if needed.
  constructor: (@x, @y) ->

  # Return a string representation of the patch.
  toString: -> "{id:#{@id} xy:#{[@x,@y]} c:#{@color}}"

  # Set patch color to `c` scaled by `s`. Usage:
  #
  #     p.scaleColor p.color, .8 # reduce patch color by .8
  #     p.scaleColor @foodColor, p.foodPheromone # ants model
  #
  # Promotes color if currently using the default.
  scaleColor: (c, s) ->
    # @color = u.clone @color unless @hasOwnProperty("color")
    # u.scaleColor c, s, @color
    u.deprecated "Patch.scaleColor: use ColorMaps ramps or closestColor"
    @color = ColorMaps.scaleColor(c, s)

  scaleOpacity: (c, s) ->
    u.deprecated "Patch.scaleOpacity: use ColorMaps ramps"
    @color = u.scaleOpacity c, s, @color
    # @color = u.clone @color unless @.hasOwnProperty("color")
    # u.scaleOpacity c, s, @color

  # Draw the patch and its text label if there is one.
  draw: (ctx) ->
    ctx.fillStyle = @color.css # u.colorStr @color
    ctx.fillRect @x-.5, @y-.5, 1, 1
    if @label? # REMIND: should be 2nd pass.
      [x,y] = @breed.patchXYtoPixelXY @x, @y
      u.ctxDrawText ctx, @label, x+@labelOffset[0], y+@labelOffset[1], @labelColor

  # Return an array of the agents/breeds on this patch.
  # If patches.cacheAgentsHere has created an @agents instance
  # variable for the patches, agents will add/remove themselves
  # as they move from patch to patch.
  agentsHere: ->
    @agents ? (a for a in @model.agents when a.p is @)
  breedsHere: (breed) ->
    (b for b in @agentsHere() when b is breed)

  # Returns true if this patch is on the edge of the grid.
  isOnEdge: ->
    @x is @breed.minX or @x is @breed.maxX or \
    @y is @breed.minY or @y is @breed.maxY

  # Factory: Create num new agents on this patch. The optional init
  # proc is called on the new agent after inserting in its agentSet.
  sprout: (num = 1, breed = @model.agents, init = ->) ->
    breed.create num, (a) => # fat arrow so that @ = this patch
      a.setXY @x, @y; init(a); a

# use colorMixin to setup colors
colorMixin(Patch,"color","black")
colorMixin(Patch,"labelColor","black")
