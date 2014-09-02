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
