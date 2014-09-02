if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

describe "Agent", ->
  describe "toString", ->
    it "gives the string representation of an agent", ->
      model = t.setupModel()
      agent = model.agents[0]
      agent.heading = 2.25
      # TODO make from string
      agent.color = u.colorFromString("red")

      expect(agent.toString()).toEqual(
        "{id: 0, position: {x: -20.00, y: -20.00}, c: 255,0,0, h: 2.25}")

  describe "moveTo", ->
    it "moves to the given location", ->
      model = t.setupModel()
      agent = model.agents[0]

      oldPatch = agent.patch
      oldPatchAgents = oldPatch.agents.length
      agent.moveTo x: 17, y: 15
      patch = model.patches.patch x: 17, y: 15

      expect(agent.position).toEqual x: 17, y: 15
      expect(agent.patch).toBe patch
      expect(patch.agents[0]).toBe agent
      expect(oldPatch.agents.length).toBe oldPatchAgents - 1

      agent.moveTo x: 11, y: 12
      patch = model.patches.patch x: 11, y: 12

      expect(agent.position).toEqual x: 11, y: 12
      expect(patch.agents[0]).toBe agent

      agent.moveTo x: 8.5, y: 7.4
      patch = model.patches.patch x: 9, y: 7

      expect(agent.position).toEqual x: 8.5, y: 7.4
      expect(patch.agents[0]).toBe agent

  describe "moveOff", ->
    it "moves the agent off the grid", ->
      model = t.setupModel()
      agent = model.agents[0]

      agent.moveOff()

      expect(agent.patch).toBe null
      expect(agent.position).toBe null

  describe "forward", ->
    it "moves the agent forward", ->
      model = t.setupModel()
      agents = model.agents

      agents[0].face(agents[1].position)
      agents[0].forward(Math.sqrt(2))

      expect(agents[0].position.x).toBeCloseTo agents[1].position.x
      expect(agents[0].position.y).toBeCloseTo agents[1].position.y
      expect(agents[0].patch).toBe agents[1].patch

  describe "rotate", ->
    it "rotates the agent", ->
      model = t.setupModel()
      agent = model.agents[0]

      agent.heading = old_heading = 1.5
      angle = 2.1
      agent.rotate(angle)

      expect(agent.heading).toBeCloseTo old_heading + angle

  describe "face", ->
    it "makes the agent face the given point", ->
      model = t.setupModel()
      agent = model.agents[0]

      agent.face(x: 0, y: 0)

      expect(agent.heading).toBeCloseTo u.degreesToRadians(45)

  describe "distance", ->
    it "returns the distance to the given point", ->
      model = t.setupModel()
      agents = model.agents

      expect(agents[0].distance(
        agents[1].position)).toBeCloseTo Math.sqrt(2)

  describe "neighbors", ->
    it "returns the neighbors in euclidian space", ->
      agents = t.setupModel().agents

      neighbors = agents[20].neighbors(3)

      expect(neighbors.length).toBe 6

      neighbors = agents[40].neighbors(2)

      expect(neighbors.length).toBe 2

    it "returns no neighbors if there are none", ->
      agent = t.setupModel().agents[20]
      agent.moveTo x: -10, y: 10

      neighbors = agent.neighbors()

      expect(neighbors.length).toBe 0

    it "returns the diamond neighbors", ->
      agents = t.setupModel().agents

      neighbors = agents[20].neighbors(diamond: 2)
      expect(neighbors.length).toBe 2

      neighbors = agents[20].neighbors(diamond: 3)
      expect(neighbors.length).toBe 2

      #    2       3
      #
      #            #
      #    #      ###
      #   X##    #X###
      #  ##O##  ###O###
      #   ##X    ###X#
      #    #      ###
      #            #

      neighbors = agents[20].neighbors(diamond: 4)
      expect(neighbors.length).toBe 4

    it "returns the neighbors requested if the world is a torus", ->
      agents = t.setupModel(torus: true).agents

      neighbors = agents[40].neighbors(2)
      expect(neighbors.length).toBe 4

      expect(neighbors[0]).toBe agents[38]
      expect(neighbors[1]).toBe agents[39]
      expect(neighbors[2]).toBe agents[0]
      expect(neighbors[3]).toBe agents[1]

    it "returns the diamond neighbors if the world is a torus", ->
      model = t.setupModel(torus: true)

      agents = t.setupModel(torus: true).agents

      neighbors = agents[40].neighbors(diamond: 3)
      expect(neighbors.length).toBe 2

      expect(neighbors[0]).toBe agents[39]
      expect(neighbors[1]).toBe agents[0]

    it "returns the radius neighbors", ->
      agents = t.setupModel().agents

      neighbors = agents[20].neighbors(radius: 3)
      expect(neighbors.length).toBe 4

      agents[0].moveTo x: 0, y: 3
      agents[1].moveTo x: 0, y: -3

      neighbors = agents[20].neighbors(radius: 3)
      expect(neighbors.length).toBe 6

      agents[20].moveTo x: 0, y: 0.1

      neighbors = agents[20].neighbors(radius: 3)
      expect(neighbors.length).toBe 5

      agents[3].moveTo x: 0, y: 3.1

      neighbors = agents[20].neighbors(radius: 3)
      expect(neighbors.length).toBe 6

    it "returns the cone neighbors", ->
      agents = t.setupModel().agents

      agents[20].heading = 0

      neighbors = agents[20].neighbors(cone: u.degreesToRadians(180), radius: 3)
      expect(neighbors.length).toBe 2

      neighbors = agents[20].neighbors(cone: u.degreesToRadians(360), radius: 3)
      expect(neighbors.length).toBe 4

      agents[0].moveTo x: 0, y: 2

      neighbors = agents[20].neighbors(cone: u.degreesToRadians(180), radius: 3)
      expect(neighbors.length).toBe 3

      neighbors = agents[20].neighbors(cone: u.degreesToRadians(90), radius: 3)
      expect(neighbors.length).toBe 2

  describe "die", ->
    it "dies, is removed from patch and breed list", ->
      model = t.setupModel()
      agent = model.agents[0]
      id = agent.id

      patch = agent.patch
      agent.die()

      expect(patch.agents.length).toBe 0
      expect(model.agents[0].id).not.toBe id

  describe "hatch", ->
    it "creates num new agents at this location", ->
      model = t.setupModel()
      agent = model.agents[0]
      agent.custo = 1337

      agent.hatch(2)
      agents = agent.patch.agents

      expect(agents.length).toBe 3
      expect(agents[1].custom).toBe agent.custom
      expect(agents[2].custom).toBe agent.custom

  # ### Links

  describe "otherEnd", ->
    it "returns the other end of a link", ->
      model = t.setupModel()
      agents = model.agents

      model.links.create(agents[0], agents[1])

      expect(agents[0].otherEnd(model.links[0])).toBe agents[1]

  describe "inLinks", ->
    it "returns the incoming links", ->
      model = t.setupModel()
      agents = model.agents

      # 0 - 1 & 2 - 1 linked
      links = agents[1].inLinks()

      expect(links.length).toBe 2
      expect(links[0]).toBe model.links[0]
      expect(links[1]).toBe model.links[1]

  describe "outLinks", ->
    it "returns the outgoing links", ->
      model = t.setupModel()
      agents = model.agents

      # 1 - 2 & 1 - 3 linked
      links = agents[1].outLinks()

      expect(links.length).toBe 2
      expect(links[0]).toBe model.links[2]
      expect(links[1]).toBe model.links[3]

  describe "linkNeighbors", ->
    it "returns all agents linked with", ->
      model = t.setupModel()
      agents = model.agents

      # 0 - 1 & 2 - 1 & 1 - 2 & 1 - 3 linked
      # Duplicate removed
      linkedAgents = agents[1].linkNeighbors()

      expect(linkedAgents.length).toBe 3
      expect(linkedAgents[0]).toBe agents[0]
      expect(linkedAgents[1]).toBe agents[2]
      expect(linkedAgents[2]).toBe agents[3]

  describe "inLinkNeighbors", ->
    it "returns all agents that link to this one", ->
      model = t.setupModel()
      agents = model.agents

      # 0 - 1 & 2 - 1 linked
      linkedAgents = agents[1].inLinkNeighbors()

      expect(linkedAgents.length).toBe 2
      expect(linkedAgents[0]).toBe agents[0]
      expect(linkedAgents[1]).toBe agents[2]

  describe "outLinkNeighbors", ->
    it "returns all agents that link to this one", ->
      model = t.setupModel()
      agents = model.agents

      # 1 - 2 & 1 - 3 linked
      linkedAgents = agents[1].outLinkNeighbors()

      expect(linkedAgents.length).toBe 2
      expect(linkedAgents[0]).toBe agents[2]
      expect(linkedAgents[1]).toBe agents[3]

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

class AgentsCreateModel extends t.Model
  setup: ->
    @setupPatches()

    @counter = 0
    @agents.create(2, (agent) =>
      @counter += 1)

describe "Agents", ->
  describe "in", ->
    it "returns all instances of the default breed", ->
      model = t.setupModel()

      inBreed = model.agents.in(model.agents)

      expect(inBreed.length).toBe model.agents.length - model.citizens.length
      expect(inBreed.first).toBe model.agents.first

    it "returns all instances of the given breed", ->
      model = t.setupModel()

      noAgents = model.agents.in(model.citizens)
      expect(noAgents.length).toBe 0

      citizens = model.citizens.in(model.citizens)
      expect(citizens.length).toBe model.citizens.length
      expect(citizens.first).toBe model.citizens.first

      onlyCitizens = model.citizens.in(model.agents)
      expect(onlyCitizens.length).toBe model.citizens.length

  describe "create", ->
    it "creates the agents", ->
      model = t.setupModel(model: AgentsCreateModel)

      expect(model.counter).toBe model.agents.length

    it "creates the agents for breeds", ->
      model = t.setupModel()

      expect(model.agents.length).toBe 51
      expect(model.citizens.length).toBe 10

      expect(model.citizens.last().breed).toBe model.citizens

  describe "clear", ->
    it "clears agents", ->
      model = t.setupModel()

      model.citizens.clear()

      expect(model.citizens.length).toBe 0
      expect(model.agents.length).not.toBe 0

  describe "neighboring", ->
    it "returns agents of same breed that are neighbors", ->
      model = t.setupModel()

      neighbors = model.citizens.neighboring(model.citizens[2], 1)
      expect(neighbors.length).toBe 5

      neighbors = model.citizens.neighboring(model.citizens[0], 8)
      expect(neighbors.length).toBe 9

  describe "formCircle", ->
    it "positions the agents in a circle", ->
      model = t.setupModel()

      model.agents.formCircle(10)

      expect(model.agents[0].position.x).toBeCloseTo 0
      expect(model.agents[0].position.y).toBeCloseTo 10
      expect(model.agents[10].position.x).toBeCloseTo 9.43
      expect(model.agents[10].position.y).toBeCloseTo 3.32
      expect(model.agents[41].position.x).toBeCloseTo -9.43
      expect(model.agents[41].position.y).toBeCloseTo 3.32

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

describe "Array", ->
  describe "from", ->
    it "turns array into an ABM.Array", ->
      array = ABM.Array.from [3, 2, 1]

      expect(array.length).toBe 3
      expect(typeof array.histogram).toBe 'function'
      expect(array.constructor.name).toBe 'Array'
      expect(array).toEqual(new ABM.Array(3, 2, 1))

    it "also works on an ABM.Array", ->
      first = ABM.Array.from [3, 2, 1]
      array = ABM.Array.from first

      expect(array.length).toBe 3
      expect(typeof array.histogram).toBe 'function'
      expect(array.constructor.name).toBe 'Array'
      expect(array).toEqual(new ABM.Array(3, 2, 1))

  describe "constructor", ->
    it "Creates the array", ->
      array = new ABM.Array 1, 2, 3

      expect(array.length).toBe 3
      expect(array.constructor.name).toBe 'Array'

      array = new ABM.Array [1, 4]

      expect(array.length).toBe 1

    it "Creates empty arrays correctly", ->
      array = new ABM.Array

      expect(array.length).toBe 0
      expect(array.constructor.name).toBe 'Array'

      array.push 2
      expect(array.length).toBe 1
      expect(array.constructor.name).toBe 'Array'
      expect(array).toEqual new ABM.Array 2

  describe "toFixed", ->
    it "returns the array rounded, as strings", ->
      expect(new ABM.Array(1.334, 5.445, 11.666).toFixed(1))
        .toEqual new ABM.Array "1.3", "5.4", "11.7"


  describe "any", ->
    it "returns false if empty", ->
      expect(new ABM.Array().any()).toBe false

  describe "empty", ->
    it "returns true if empty", ->
      expect(new ABM.Array().empty()).toBe true
      expect(new ABM.Array(1, 2).empty()).toBe false

  describe "clone", ->
    it "returns a copy of the array", ->
      array = new ABM.Array 1, 2, 3
      array2 = array.clone()
      expect(array).toEqual ABM.Array.from array2
      array2[1] = 7
      expect(array[1]).not.toEqual array2[1]

  describe "last", ->
    it "returns the last element", ->
      expect(new ABM.Array(1, 2, 3).last()).toEqual 3

  describe "sample", ->
    it "returns one object if no number given", ->
      u.randomSeed(2)
      number = new ABM.Array(1, 2, 3, 4).sample()
      expect(number).toEqual 4
  
    it "returns the number of objects if number given", ->
      u.randomSeed(2)
      array = new ABM.Array(1, 2, 3, 4).sample(2)
      expect(array).toEqual new ABM.Array 4, 1

    it "returns sample for which true if condition given", ->
      u.randomSeed(10)
      number = new ABM.Array 1, 2, 3, 4, 5, 6
        .sample((number) -> number % 2 is 0)
      expect(number).toEqual 2

    it "returns sample for which true if condition and number is given", ->
      u.randomSeed(2)
      array = new ABM.Array 1, 2, 3, 4, 5, 6
        .sample(2, (number) -> number % 2 is 0)
      expect(array).toEqual new ABM.Array 6, 2

  describe "contains", ->
    it "returns true if it contains the element", ->
      expect(new ABM.Array(1, 2, 3).contains(2)).toBe true
      expect(new ABM.Array(1, 2, 3).contains(5)).toBe false

  describe "remove", ->
    it "removes the item", ->
      expect(new ABM.Array(1, 2, 3)
        .remove(2)).toEqual new ABM.Array 1, 3

      array = new ABM.Array(1, 'z', 7, 7)
      array.remove(7)
      expect(array).toEqual new ABM.Array 1, 'z'

  describe "removeItems", ->
    it "removes the items", ->
      expect(new ABM.Array(1, 2, 3, 4, 5)
        .removeItems([2, 4])).toEqual new ABM.Array 1, 3, 5

  describe "shuffle", ->
    it "shuffles the array", ->
      u.randomSeed(2)
      expect(new ABM.Array(1, 2, 3)
        .shuffle()).toEqual new ABM.Array 1, 3, 2

  describe "min", ->
    it "returns the smallest element", ->
      expect(new ABM.Array(7, 3, 2, 3).min()).toEqual 2

  describe "max", ->
    it "returns the biggest element", ->
      expect(new ABM.Array(7, 3, 2, 3).max()).toEqual 7

  describe "sum", ->
    it "returns the sum", ->
      expect(new ABM.Array(7, 3, 2, 3).sum()).toEqual 15

  describe "average", ->
    it "returns the average", ->
      expect(new ABM.Array(7, 3, 2, 3).average()).toEqual 3.75

  describe "median", ->
    it "returns the median", ->
      expect(new ABM.Array(7, 3, 2).median()).toEqual 3
      expect(new ABM.Array(7, 3, 2, 4).median()).toEqual 3.5

  describe "histogram", ->
    it "returns the histogram", ->
      expect(new ABM.Array(0, 2, 6, 8, 2)
        .histogram(3)).toEqual new ABM.Array 3, 0, 2

  describe "sort", ->
    it "sorts the array", ->
      array = new ABM.Array 2.4, 8, 2
      array.sort((objectA, objectB) ->
        Math.floor(objectA) > Math.floor(objectB))
      expect(array).toEqual new ABM.Array 2.4, 2, 8

  describe "uniq", ->
    it "returns the array with only unique items", ->
      array = new ABM.Array 0, 2, 1, 0, 8, 2, 1, 1
      array.uniq() # changes array in place
      expect(array).toEqual new ABM.Array 0, 2, 1, 8

  describe "flatten", ->
    it "flattens the matrix to an array", ->
      expect(new ABM.Array([7], [3, 2], [3]).flatten())
        .toEqual new ABM.Array 7, 3, 2, 3

      expect(new ABM.Array([3, 2], [5, 7, 9], [3, 66]).flatten())
        .toEqual new ABM.Array 3, 2, 5, 7, 9, 3, 66

  describe "normalize", ->
    it "returns the array normalized", ->
      expect(new ABM.Array(4, 9, 7).normalize(5, 10))
        .toEqual new ABM.Array 5, 10, 8

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

describe "Set", ->
  describe "constructor", ->
    it "Creates the set", ->
      set = new ABM.BreedSet(ABM.Agent, "agents")

      expect(set.length).toBe 0
      expect(set.name).toBe "agents"
      expect(set.agentClass).toBe ABM.Agent
      expect(set.mainSet).toBe undefined
      expect(set.breeds).toEqual []
      expect(set.ID).toBe 0

    it "Creates a subset", ->
      model = t.setupModel()

      set = new ABM.BreedSet(model.Agent, "ducks", model.Agent::breed)

      expect(set.length).toBe 0
      expect(set.mainSet.name).toBe "agents"
      expect(set.mainSet.length).toEqual model.agents.length
      expect(set.breeds).toBe undefined
      expect(set.ID).toBe undefined

      # TODO breeds not added on creation, change
      expect(model.agents.breeds.length).toBe 1
      expect(model.agents.breeds[0].name).toBe "citizens"

  describe "push", ->
    it "Adds to main set", ->
      model = t.setupModel()

      nr = model.agents.ID
      object = {}

      model.agents.push(object)

      expect(object.id).toBe nr
      expect(model.agents.last()).toBe object
      expect(model.citizens.last()).not.toBe object

    it "Adds to sub- (& main) set", ->
      model = t.setupModel()

      nr = model.agents.ID
      object = {}

      model.citizens.push(object)

      expect(object.id).toBe nr
      expect(model.citizens.last()).toBe object
      expect(model.agents.last()).toBe object

  describe "remove", ->
    it "Removes from both sets", ->
      model = t.setupModel()
      agent = model.citizens.first()

      model.citizens.remove(agent)

      expect(model.agents.contains(agent)).not.toBe true
      expect(model.citizens.contains(agent)).not.toBe true

  describe "pop", ->
    it "Removes last object", ->
      model = t.setupModel()
      agent = model.agents.last()

      returned = model.citizens.pop()

      expect(returned).toBe agent
      expect(model.agents.contains(agent)).not.toBe true

  describe "setBreed", ->
    it "Sets the breed", ->
      model = t.setupModel()

      agent = model.agents.first()
      citizen = model.citizens.first()
      agentsOldId = agent.id
      citizensOldId = citizen.id

      model.citizens.setBreed(agent)

      expect(agent.breed.name).toBe "citizens"
      expect(agent.id).toBe agentsOldId

      model.agents.setBreed(citizen)

      expect(citizen.breed.name).toBe "agents"
      expect(citizen.id).toBe citizensOldId

    it "Sets the breed, copying the prototype if classes differ", ->
#      model = t.setupModel(model: BreedsModel)

#      rat = model.rats[0]

#      model.swans.setBreed rat
 
#      expect(ABM.Agent::size).toBe 17

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

describe "Link", ->
  describe "die", ->
    it "removes the link", ->
      model = t.setupModel()
      length = model.links.length
      link = model.links[0]
      from = link.from
      to = link.to

      link.die()

      #expect(link).toEqual null
      expect(model.links.length).toEqual length - 1
      expect(from.links.length).toEqual 0
      expect(to.links.length).toEqual 3

  describe "bothEnds", ->
    it "returns both ends", ->
      model = t.setupModel()
      link = model.links[0]

      both = link.bothEnds()

      expect(both.length).toEqual 2
      expect(both[0].id).toBe link.from.id
      expect(both[1].id).toBe link.to.id

  describe "length", ->
    it "returns the length between both ends", ->
      model = t.setupModel()
      link = model.links[0]

      expect(link.length()).toBeCloseTo 1.41

      long = model.links[4]

      expect(long.length()).toBeCloseTo 8.49

  describe "otherEnd", ->
    it "returns the other end", ->
      model = t.setupModel()
      link = model.links[1]

      expect(link.otherEnd(link.from)).toBe link.to
      expect(link.otherEnd(link.to)).toBe link.from

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

class LinksCreateModel extends t.Model
  setup: ->
    @setupPatches()
    @setupAgents()

    @counter = 0
    for [i, j] in [[0, 1], [1, 2]]
      @links.create(@agents[i], @agents[j], (link) =>
        @counter += 1)

describe "Links", ->
  describe "create", ->
    it "creates the link", ->
      model = t.setupModel(model: LinksCreateModel)
      link = model.links[0]

      expect(link.from).toBe model.agents[0]
      expect(link.to).toBe model.agents[1]
      expect(model.counter).toBe 2

  describe "clear", ->
    it "clears the list", ->
      model = t.setupModel()
      link = model.links[2]
      to = link.to

      model.links.clear()

      expect(model.links.length).toBe 0
      expect(to.links.length).toBe 0

  describe "nodesWithDups", ->
    it "all nodes, including duplicates", ->
      model = t.setupModel()
      agents = model.agents

      nodes = model.links.nodesWithDups()

      expect(nodes.length).toBe 10
      expect(nodes[5]).toBe agents[2]

  describe "nodes", ->
    it "all nodes, without duplicates", ->
      model = t.setupModel()
      agents = model.agents

      nodes = model.links.nodes()

      expect(nodes.length).toBe 6
      expect(nodes[5]).toBe agents[10]

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

describe "Model", ->
  describe "asSomet", ->
    # TODO make new class so it is clear
    it "Turns the array into a set", ->
      expect(2).toBe 2
      #expect(set.length).toBe 0
      # has method

# TODO finish

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

describe "Patch", ->
  describe "patch", ->
    it "gets the patch", ->
      model = t.setupModel()
      patch = model.patches.patch x: -20, y: 20

      expect(patch).toBe model.patches[0]

  describe "neighbors", ->
    testMiddlePatch = (model) ->
      patch = model.patches.patch(x: 10, y: 10)

      neighbors = patch.neighbors()

      expect(neighbors.length).toBe 8
      expect(neighbors[0].position).toEqual x: 9, y: 9
      expect(neighbors[7].position).toEqual x: 11, y: 11

      neighbors = patch.neighbors(1)

      expect(neighbors.length).toBe 8

      neighbors = patch.neighbors(2)

      expect(neighbors.length).toBe 24
      expect(neighbors[0].position).toEqual x: 8, y: 8
      expect(neighbors[23].position).toEqual x: 12, y: 12

      middlePatch = model.patches.patch(x: 1, y: 1)

      neighbors = middlePatch.neighbors()

      expect(neighbors.length).toBe 8
      expect(neighbors[0].position).toEqual x: 0, y: 0
      expect(neighbors[1].position).toEqual x: 1, y: 0
      expect(neighbors[2].position).toEqual x: 2, y: 0

    testMiddlePatchDiamond = (model) ->
      patch = model.patches.patch(x: 10, y: 10)

      neighbors = patch.neighbors(diamond: 1)

      expect(neighbors.length).toBe 4
      expect(neighbors[0].position).toEqual x: 10, y: 9
      expect(neighbors[3].position).toEqual x: 10, y: 11

      neighbors = patch.neighbors(diamond: 4)

      expect(neighbors.length).toBe 40
      expect(neighbors[0].position).toEqual x: 10, y: 6
      expect(neighbors[1].position).toEqual x: 9, y: 7
      expect(neighbors[39].position).toEqual x: 10, y: 14

      neighbors = patch.neighbors(diamond: 4)

      expect(neighbors.length).toBe 40

    it "returns the neighbors requested if the world is euclidian", ->
      model = t.setupModel()

      testMiddlePatch(model)

    it "returns the diamond neighbors if the world is euclidian", ->
      model = t.setupModel()

      testMiddlePatchDiamond(model)

      bottomRightPatch = model.patches.patch(x: 17, y: 17)
      neighbors = bottomRightPatch.neighbors(diamond: 7)

      expect(neighbors.length).toBe 80
      expect(neighbors[0].position).toEqual x: 17, y: 10
      expect(neighbors[79].position).toEqual x: 20, y: 20

      topLeftPatch = model.patches.patch(x: -18, y: -18)
      neighbors = topLeftPatch.neighbors(diamond: 7)

      expect(neighbors.length).toBe 65
      expect(neighbors[0].position).toEqual x: -20, y: -20
      expect(neighbors[1].position).toEqual x: -19, y: -20
      expect(neighbors[64].position).toEqual x: -18, y: -11

    it "returns the neighbors requested if the world is a torus", ->
      model = t.setupModel(torus: true)

      testMiddlePatch(model)

    it "returns the diamond neighbors if the world is a torus", ->
      model = t.setupModel(torus: true)

      testMiddlePatchDiamond(model)

      bottomRightPatch = model.patches.patch(x: 17, y: 17)
      neighbors = bottomRightPatch.neighbors(diamond: 7)

      expect(neighbors.length).toBe 112
      expect(neighbors[0].position).toEqual x: 17, y: 10
      expect(neighbors[111].position).toEqual x: 17, y: -17

      topLeftPatch = model.patches.patch(x: -18, y: -18)
      neighbors = topLeftPatch.neighbors(diamond: 7)

      expect(neighbors.length).toBe 112
      expect(neighbors[0].position).toEqual x: -18, y: 16
      expect(neighbors[1].position).toEqual x: -19, y: 17
      expect(neighbors[54].position).toEqual x: -20, y: -18

    it "caches correcly", ->
      model = t.setupModel()
      patch = model.patches.patch(x: 10, y: 10)

      neighbors = patch.neighbors(range: 1, cache: false)
      expect(patch.neighborsCache).toEqual {}

      neighbors = patch.neighbors(range: 1)
      expect(patch.neighborsCache['{"range":1}'].length).toBe 8

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

describe "Patches", ->
  describe "patchIndex", ->
    it "returns the index for the patch", ->
      model = t.setupModel()
      index = model.patches.patchIndex x: 0, y: 0

      expect(index).toBe 840

  describe "patch", ->
    it "returns the patch at the coordinate", ->
      model = t.setupModel()
      patch = model.patches.patch x: 0, y: 0.1

      expect(patch.position).toEqual x: 0, y: 0

  describe "coordinate", ->
    it "returns the position as a coordinate", ->
      model = t.setupModel()

      coordinate = model.patches.coordinate x: 17, y: 15
      expect(coordinate).toEqual x: 17, y: 15

      coordinate = model.patches.coordinate x: 37, y: 15
      expect(coordinate).toEqual x: 20.5, y: 15

    it "returns the position as a coordinate also for torus", ->
      model = t.setupModel(torus: true)

      coordinate = model.patches.coordinate x: 50, y: 25
      expect(coordinate).toEqual x: 9, y: -16

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

describe "Set", ->
  describe "constructor", ->
    it "Creates a new ABM.Set", ->
      set = new ABM.Set 1, 2

      expect(set.length).toBe 2
      expect(typeof set.setDefault).toBe 'function'
      expect(set.constructor.name).toBe 'Set'

  describe "from", ->
    it "Turns the array into an ABM.Set", ->
      set = ABM.Set.from [1, 2]

      expect(set.length).toBe 2
      expect(typeof set.setDefault).toBe 'function'
      expect(set.constructor.name).toBe 'Set'

  describe "setDefault", ->
    it "Sets the default", ->
      model = t.setupModel()

      model.agents.setDefault('size', 17)
 
      expect(model.Agent::size).toBe 17

    it "The default gets propagated", ->
      t.Model.prototype.preSetup = ->
        @agents.setDefault "shape", "square"

      model = t.setupModel()

      expect(model.Agent::shape).toBe "square"
      expect(model.agents[0].shape).toBe "square"
      expect(model.citizens[0].shape).toBe "square"
  
  # All other Array methods are tested in superclass Array
  describe "flatten", ->
    it "Flattens the set, also with subsets", ->
      set = new ABM.Set 1, 3, 9

      set2 = set.flatten()
      expect(set2.constructor.name).toBe 'Set'
      expect(set2).toEqual new ABM.Set 1, 3, 9

      set = new ABM.Set 1, [3, 5, 7], 9

      expect(set.flatten()).toEqual new ABM.Set 1, 3, 5, 7, 9

      set = new ABM.Set [1, 2, 13], [3, 5, 7], [9, 10, 11]

      expect(set.flatten()).toEqual new ABM.Set 1, 2, 13, 3, 5, 7, 9, 10, 11

      set = new ABM.Set(new ABM.Set(1, 2, 13), new ABM.Set(3, 5, 7))

      expect(set.flatten()).toEqual new ABM.Set 1, 2, 13, 3, 5, 7

    it "Also works with agents/patches in the set", ->
      model = t.setupModel()
      patches = model.patches

      set = new ABM.Set(new ABM.Set(patches[3], patches[1], patches[4]),
        new ABM.Set(patches[2], patches[8], patches[9]))

      expect(set.flatten()).toEqual new ABM.Set patches[3], patches[1], patches[4],
        patches[2], patches[8], patches[9]

if typeof window == 'undefined'
  t = require "./shared.coffee"
  eval 'var ABM = t.ABM' # because CoffeeScript sets var to null

t = ABM.test
u = ABM.util

describe "Util", ->
  if typeof window != 'undefined'
    eval 'global = window'
    # if tested in the browser Node global does not exist

  # ### Language extensions

  describe "error", ->
    it "throws an error", ->
      expect(u.error, "Something").toThrow()

  describe "isArray", ->
    it "detects arrays, and subclasses of array as arrays", ->
      arrays = [
        []
        ABM.Agents.from []
        [1, 2, 3]
        ["some", 4]
        new ABM.Array(1, 2)
        new ABM.Set(5, 2, 99)
        new ABM.Set()
        ABM.Set.from [5, 2, 99]
        new ABM.BreedSet(ABM.Agent, "agents")
      ]

      for array in arrays
        expect(u.isArray(array)).toBe true

    it "excluded non-arrays", ->
      objects = [
        1
        {a: 2}
        -> 1
      ]

      for object in objects
        expect(u.isArray(object)).toBe false

  describe "isFunction", ->
    it "detects functions", ->
      expect(u.isFunction(=> 1 + 1)).toBe true

    it "rejects non-functions", ->
      expect(u.isFunction(1 + 1)).toBe false

  describe "isString", ->
    it "detects strings", ->
      expect(u.isString("Big dog " + 2)).toBe true

    it "rejects non-strings", ->
      expect(u.isString(-> 3)).toBe false

  describe "isNumber", ->
    it "detects numbers", ->
      expect(u.isNumber(2)).toBe true

    it "rejects non-numbers", ->
      expect(u.isString(-> 3)).toBe false

  # ### Numeric operations

  describe "randomSeed", ->
    it "replaces random", ->
      u.randomSeed(2)
      expect(Math.random()).toBeCloseTo 0.97
      expect(Math.random()).toBeCloseTo 0.20
      u.randomSeed(3)
      expect(Math.random()).toBeCloseTo 0.20

  describe "randomInt", ->
    it "returns a random int", ->
      u.randomSeed(2)
      for outcome in [1, 0, 1]
        expect(u.randomInt()).toEqual outcome

    it "returns a random int with max value", ->
      u.randomSeed(2)
      expect(u.randomInt(10)).toEqual 9

    it "returns a random int between values", ->
      expect(u.randomInt(15, 30)).toEqual 18

  describe "randomFloat", ->
    it "returns a random float", ->
      u.randomSeed(2)
      for outcome in [0.97, 0.20, 0.98]
        expect(u.randomFloat()).toBeCloseTo outcome

  describe "randomNormal", ->
    it "returns numbers out of a normal distribution", ->
      u.randomSeed(2)
      for outcome in [20.87, 3.09, 32.15, 13.15, 36.01, -9.53]
        expect(u.randomNormal(0, 25)).toBeCloseTo outcome

  describe "randomCentered", ->
    it "returns numbers centered ahead in rads", ->
      u.randomSeed(2)
      for outcome in [0.95, -0.60]
        expect(u.randomCentered(2)).toBeCloseTo outcome

  describe "onceEvery", ->
    it "returns true once every number", ->
      u.randomSeed(2)
      for outcome in [true, false]
        expect(u.onceEvery(2)).toBe outcome

  describe "log10", ->
    it "returns log base 10", ->
      expect(u.log10(30)).toBeCloseTo 1.48

  describe "log2", ->
    it "returns log base 2", ->
      expect(u.log2(8)).toEqual 3

  describe "logN", ->
    it "returns log base X", ->
      expect(u.logN(256, 4)).toEqual 4

  describe "mod", ->
    it "returns the correct modulo", ->
      expect(u.mod(-5, 4)).toEqual 3

  describe "wrap", ->
    it "returns number wrapped between min and max", ->
      expect(u.wrap(7, 10, 20)).toEqual 17

  describe "clamp", ->
    it "returns number clamped between min and max", ->
      expect(u.clamp(7, 10, 20)).toEqual 10
      expect(u.clamp(13, 10, 20)).toEqual 13

  describe "sign", ->
    it "returns the sign of the number", ->
      expect(u.sign(-30)).toEqual -1

  # ### Color and angle operations

  describe "colorFromString", ->
    it "returns the color as an array", ->
      expect(u.colorFromString("green")).toEqual [0, 128, 0]

    it "throws an error if not supported", ->
      expect(u.colorFromString, "ultrasonicviolet").toThrow()

  describe "fractionOfColor", ->
    it "reduces the color towards white with fraction", ->
      expect(u.fractionOfColor([128, 0, 32], 0.5)).toEqual [64, 0, 16]

  describe "brightenColor", ->
    it "brightens the color by fraction", ->
      expect(u.brightenColor([0, 255, 128], 0.1)).toEqual [26, 255, 154]

  describe "colorString", ->
    it "returns the color as a string", ->
      expect(u.colorString([0, 255, 128])).toEqual "rgb(0,255,128)"
      expect(u.colorString([11, 25, 12, 0.4])).toEqual "rgba(11,25,12,0.4)"

  describe "colorsEqual", ->
    it "returns true if the colors are equal", ->
      expect(u.colorsEqual([0, 255, 128], [0, 255, 128])).toBe true
      expect(u.colorsEqual([0, 255, 128], [1, 255, 128])).toBe false

  describe "isLittleEndian", ->
    it "returns true on littleEndian systems", ->
      expect(u.isLittleEndian()).toBe true

  describe "degreesToRadians", ->
    it "returns the radians", ->
      expect(u.degreesToRadians(90)).toBeCloseTo 1.57

  describe "radiansToDegrees", ->
    it "returns the degrees", ->
      expect(u.radiansToDegrees(1)).toBeCloseTo 57.30

  describe "substractRadians", ->
    it "returns the angle, between PI and minus PI", ->
      expect(u.substractRadians(1, 8)).toBeCloseTo -0.72

  # ### Object operations

  describe "ownKeys", ->
    it "returns the attributes", ->
      object = new Object # an object
      object.bull = "pen"
      object.fly = -> 1 + 1
      expect(u.ownKeys(object)).toEqual new ABM.Array "bull", "fly"

  describe "ownVariableKeys", ->
    it "returns the attributes that are not functions", ->
      object = new Object # an object
      object.bull = "pen"
      object.fly = -> 1 + 1
      expect(u.ownVariableKeys(object)).toEqual new ABM.Array "bull"

  describe "ownValues", ->
    it "returns the values", ->
      object = new Object # an object
      object.bull = "pen"
      object.fly = -> 1 + 1
      expect(u.ownValues(object)).toEqual new ABM.Array "pen", object.fly

  # ### Topology operations

  describe "angle", ->
    it "returns the radians toward the second point", ->
      expect(u.angle({x: 1, y: 1}, {x: 3, y: 3},
        {isTorus: false})).toBeCloseTo 0.79

    it "returns the radians toward the second point on a torus", ->
      expect(u.angle({x: 1, y: 1}, {x: 3, y: 3},
        {isTorus: true, width: 10, height: 10})).toBeCloseTo 0.79
      expect(u.angle({x: 1, y: 1}, {x: 3, y: 3},
        {isTorus: true, width: 3, height: 3})).toBeCloseTo -2.36

  describe "inCone", ->
    it "returns true if in cone", ->
      expect(u.inCone(3, 6, 3, {x: 1, y: 1}, {x: 2, y: 2},
        {isTorus: false})).toBe true
      expect(u.inCone(3, 3, 1, {x: 1, y: 1}, {x: 2, y: 2},
        {isTorus: false})).toBe false

    it "returns true if in cone for toruses too", ->
      expect(u.inCone(3, 6, 3, {x: 1, y: 1}, {x: 2, y: 2},
        {isTorus: true, width: 10, height: 10})).toBe true
      expect(u.inCone(3, 3, 3, {x: 1, y: 1}, {x: 2, y: 2},
        {isTorus: true, width: 10, height: 10})).toBe false
      expect(u.inCone(3, 3, 3, {x: 1, y: 1}, {x: 2, y: 2},
        {isTorus: true, width: 3, height: 3})).toBe true

  describe "distance", ->
    it "returns distance between the points", ->
      expect(u.distance({x: 1, y: 1}, {x: 3, y: 1},
        {isTorus: false})).toBe 2
      expect(u.distance({x: 1, y: 1}, {x: 4, y: 9},
        {isTorus: false})).toBeCloseTo 8.54

    it "returns distance between the closest points on the torus", ->
      expect(u.distance({x: 1, y: 1}, {x: 4, y: 9},
        {isTorus: true, width: 20, height: 20})).toBeCloseTo 8.54
      expect(u.distance({x: 1, y: 1}, {x: 4, y: 9},
        {isTorus: true, width: 10, height: 10})).toBeCloseTo 3.61

  describe "torus4Points", ->
    it "returns the 4 reflected points", ->
      expect(u.torus4Points({x: 1, y: 1}, {x: 4, y: 9}, 10, 10))
        .toEqual [{x: 4, y: 9}, {x: -6, y: 9}, {x: 4, y: -1}, {x: -6, y: -1}]

  describe "closestTorusPoint", ->
    it "returns the closest of the 4 reflected points", ->
      expect(u.closestTorusPoint({x: 1, y: 1}, {x: 4, y: 9},
        10, 10)).toEqual {x: 4, y: -1}

  # ### File I/O

  describe "importImage", ->
    it "returns an image object", ->
      global.Image = class
      source = "http://www.duck.com/wing.jpg"
      call = (object) -> object * 23
      image = u.importImage(source, call)
      expect(image.src).toEqual source
      expect(image.isDone).toBe false
      expect(image.onload.toString()).toContain "isDone"

  describe "xhrLoadFile", ->
    it "returns an image object", ->
      global.XMLHttpRequest = class
        open: (a, b) ->
        send: ->
      source = "http://www.duck.com/quack.yml"
      type = "unicorns"
      call = (object) -> object * 23
      request = u.xhrLoadFile(source, null, type, call)
      expect(request.responseType).toEqual type
      expect(request.isDone).toBe false
      expect(request.onload.toString()).toContain "isDone"

  describe "filesLoaded", ->
    it "returns true if all files were loaded", ->
      global.Image = class
      u.fileIndex = {}
      source = "http://www.duck.com/beek.jpg"
      expect(u.filesLoaded()).toBe true
      image = u.importImage(source)
      expect(u.filesLoaded()).toBe false
      u.fileIndex[source].isDone = true
      expect(u.filesLoaded()).toBe true

  describe "waitOnFiles", ->
    it "waits on files that weren't loaded yet", ->
      global.Image = class
      global.setTimeout = (call, timeout) ->
        u.fileIndex["tail.jpg"].isDone = true # cheating
        call()
      u.fileIndex = {}
      call = -> 1 + 1
      call = jasmine.createSpy()
      image = u.importImage("tail.jpg")
      expect(u.filesLoaded()).toBe false
      u.waitOnFiles(call)
      expect(u.filesLoaded()).toBe true
      expect(call).toHaveBeenCalled()

  # ### Image data operations

  describe "cloneImage", ->
    it "creates a new image object with the same source", ->
      global.Image = class
      source = "pond.jpg"
      image = new Image
      image.src = source
      clone = u.cloneImage(image)
      expect(clone).not.toBe image
      expect(clone.src).toEqual source

  describe "imageToData", ->
    it "creates a new image object with the same source", ->
      global.Image = class
      source = "pond.jpg"
      image = new Image
      image.src = source
      data = u.imageToData(image)
      expect(data.length).toEqual 0 # Needs a real test

  describe "pixelByte", ->
    it "returns a pixel byte function", ->
      expect(u.pixelByte(1)([1, 2, 3], 1)).toEqual 3

  # ### Canvas/context operations

  # TODO find a way to test these

  # ### Misc / helpers

  describe "linearInterpolate", ->
    it "returns a linear interpolation", ->
      expect(u.linearInterpolate(1, 5, 0.5)).toEqual 3

  describe "typedToJS", ->
    it "returns a JS array", ->
      array = new Uint8Array([1,2])
      array = u.typedToJS(array)
      expect(array.sort?).toBe true
