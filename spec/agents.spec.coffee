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
