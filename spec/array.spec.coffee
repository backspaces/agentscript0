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
