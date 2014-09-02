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
