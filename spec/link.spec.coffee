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
