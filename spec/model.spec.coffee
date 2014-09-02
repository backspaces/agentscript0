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
