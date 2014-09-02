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
