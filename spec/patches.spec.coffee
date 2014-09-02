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
