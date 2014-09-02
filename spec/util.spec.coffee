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
