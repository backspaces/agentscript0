# Array utility functions. Are added to ABM.Array and to util for
# legacy reasons.

ABM.util.array =
  # The static `ABM.Array.from` as a method.
  # Used by methods creating new arrays.
  from: (array, arrayType) ->
    ABM.Array.from array, arrayType
  # TODO replace in code

  # Return string representative of agentset.
  toString: (array) ->
    "[" + (object.toString() for object in array).join(", ") + "]"

  # Return an array of floating pt numbers as strings at given precision;
  # useful for printing
  toFixed: (array, precision = 2) ->
    newArray = []
    for number in array
      newArray.push number.toFixed precision
    newArray

  # Does the array have any elements? Is the array empty?
  any: (array) ->
    not @empty(array)

  empty: (array) ->
    array.length is 0

  # Make a copy of the array. Needed when you don't want to modify the given
  # array with mutator methods like sort, splice or your own functions.
  # By giving begin/arguments, retrieve a subset of the array.
  # Works with TypedArrays too.
  clone: (array, begin = null, end = null) ->
    if array.slice?
      method = "slice"
    else
      method = "subarray"

    if begin?
      array[method] begin, end
    else
      array[method] 0

  # Return first element of array.
  first: (array) ->
    array[0]

  # Return last element of array.
  last: (array) ->
    if @empty array
      undefined
    else
      array[array.length - 1]

  # Return random element of array or number random elements of array.
  # Note: array elements presumed unique, i.e. objects or distinct primitives
  # Note: clone, shuffle then first number has poor performance
  sample: (array, numberOrCondition = null, condition = null) ->
    if u.isFunction numberOrCondition
      condition = numberOrCondition
    else if numberOrCondition?
      number = Math.floor(numberOrCondition)

    if number?
      newArray = new ABM.Array
      object = true
      while newArray.length < number and object?
        object = @sample(array, condition)
        if object and object not in newArray
          newArray.push object
      return newArray
    else if condition?
      checked = new ABM.Array
      while checked.length < array.length
        object = @sample(array)
        if object and object not in checked
          checked.push object
          if condition(object)
            return object
    else
      if @empty array
        return null
      return array[u.randomInt array.length]

  # True if object is in array.
  contains: (array, object) ->
    array.indexOf(object) >= 0

  # Remove an object from an array.
  # Error if object not in array.
  remove: (array, object) ->
    while true
      index = array.indexOf object
      break if index is -1
      array.splice index, 1
    array

  # Remove elements in objects from an array. Binary search if f isnt null.
  # Error if an object not in array.
  removeItems: (array, objects) ->
    for object in objects
      @remove array, object
    array

  # Randomize the elements of this array.
  shuffle: (array) ->
    array.sort -> 0.5 - Math.random()

  # TODO add array functions to Array extension, then allow it to be
  # added to array in user models through an ABM.setup() function
  #
  # Return object when lambda(object) min/max in array. Error if array empty.
  # If f is a string, return element with max value of that property.
  # If "valueToo" then return a 2-array of the element and the value;
  # used for cases where f is costly function.
  # 
  #     array = [{x: 1, y: 2}, {x: 3, y: 4}]
  #     array.min()
  #     # returns {x: 1, y: 2} 5
  #     [min, dist2] = array.min(((o) -> o.x * o.x + o.y * o.y), true)
  #     # returns {x: 3, y: 4}
  min: (array, lambda = u.identityFunction, valueToo = false) ->
    u.error "min: empty array" if @empty array
    if u.isString lambda
      lambda = u.propertyFunction lambda
    minValue = Infinity
    minObject = null

    for object in array
      value = lambda(object)
      if value < minValue
        minValue = value
        minObject = object

    if valueToo
      [minObject, minValue]
    else
      minObject

  max: (array, lambda = u.identityFunction, valueToo = false) ->
    u.error "max: empty array" if @empty array
    if u.isString lambda
      lambda = u.propertyFunction lambda
    maxValue = -Infinity
    maxObject = null

    for object in array
      value = lambda(object)
      if value > maxValue
        maxValue = value
        maxObject = object

    if valueToo
      [maxObject, maxValue]
    else
      maxObject

  sum: (array, lambda = u.identityFunction) ->
    if u.isString lambda
      lambda = u.propertyFunction lambda

    value = 0
    for object in array
      value += lambda(object)

    value

  average: (array, lambda = u.identityFunction) ->
    @sum(array, lambda) / array.length

  median: (array) ->
    if array.sort?
      array = @clone array
    else
      array = u.typedToJS array

    middle = (array.length - 1) / 2

    @sort array

    (array[Math.floor(middle)] + array[Math.ceil(middle)]) / 2

  # Return histogram of o when f(o) is a numeric value in array.
  # Histogram interval is bin. Error if array empty.
  # If f is a string, return histogram of that property.
  #
  # In examples below, histogram returns [3, 1, 1, 0, 0, 1]
  #
  #     a = [1, 3, 4, 1, 1, 10]
  #     h = histogram a, 2, (i) -> i
  #     
  #     b = ({id:i} for i in a)
  #     h = histogram b, 2, (o) -> o.id
  #     h = histogram b, 2, "id"
  histogram: (array, binSize = 1, lambda = u.identityFunction) ->
    if u.isString lambda
      lambda = u.propertyFunction lambda
    histogram = []

    for object in array
      integer = Math.floor lambda(object) / binSize
      histogram[integer] or= 0
      histogram[integer] += 1

    for value, integer in histogram when not value?
      histogram[integer] = 0

    histogram

  # Mutator. Sort array of objects in place by the function f.
  # If f is string, f returns property of object.
  # Returns array.
  # Clone first if you want to preserve the original array.
  #
  #     array = [{i: 1}, {i: 5}, {i: -1}, {i: 2}, {i: 2}]
  #     sortBy array, "i"
  #     # array now is [{i: -1}, {i: 1}, {i: 2}, {i: 2}, {i:5}]
  sort: (array, lambda = null) ->
    if u.isString lambda # use item[f] if f is string
      lambda = u.propertySortFunction lambda

    array._sort lambda

  # Mutator. Removes dups, by reference, in place from array.
  # Note "by reference" means litteraly same object, not copy. Returns array.
  # Clone first if you want to preserve the original array.
  #
  #     ids = ({id: i} for i in [0..10])
  #     a = (ids[i] for i in [1, 3, 4, 1, 1, 10])
  #     # a is [{id: 1}, {id: 3}, {id: 4}, {id: 1}, {id: 1}, {id: 10}]
  #     b = clone a
  #     sortBy b, "id"
  #     # b is [{id:1}, {id: 1}, {id: 1}, {id: 3}, {id: 4}, {id: 10}]
  #     uniq b
  #     # b now is [{id:1}, {id: 3}, {id: 4}, {id: 10}]
  uniq: (array) ->
    hash = {}

    i = 0
    while i < array.length
      if hash[array[i]] is true
        array.splice i, 1
        i -= 1
      else
        hash[array[i]] = true
      i += 1

    array
  
  # Return a new array composed of the rows of a matrix. I.e. convert
  #
  #     [[1, 2, 3], [4, 5, 6]] to [1, 2, 3, 4, 5, 6]
  flatten: (array) ->
    array.reduce((arrayA, arrayB) ->
      if not u.isArray arrayA
        arrayA = new ABM.Array arrayA
      arrayA.concat arrayB)

  # Returns a new array that has addArray appended
  #
  # Concat checks [[ClassName]], and this does not work for things
  # inheriting from Array.
  concat: (array, addArray) ->
    newArray = array.clone()
    if u.isArray addArray
      for element in addArray
        newArray.push element
    else
      newArray.push addArray

    newArray
  
  # Return an array with values in [low, high], defaults to [0, 1].
  # Note: to have a half-open interval, [low, high), try high = high - .00009
  normalize: (array, low = 0, high = 1) ->
    min = @min array
    max = @max array
    scale = 1 / (max - min)
    newArray = []
    for number in array
      newArray.push u.linearInterpolate(low, high, scale * (number - min))
    newArray

  normalizeInt: (array, low, high) ->
    (Math.round i for i in @normalize array, low, high)

  # Return a Uint8ClampedArray, normalized to [.5, 255.5] then round/clamp to [0, 255]
  # TODO maybe data-specific?
  normalize8: (array) ->
    new Uint8ClampedArray @normalize(array, -.5, 255.5)

  # ### Debugging
  
  # Useful in console.
  # Also see [CoffeeConsole](http://goo.gl/1i7bd) Chrome extension.
  
  # Similar to NetLogo ask & with operators.
  # Allows functions as strings. Use:
  #
  #     AS.getProperty("x") # [1, 8, 6, 2, 2]
  #     AS.with("o.x < 5").ask("o.x = o.x + 1")
  #     AS.getProperty("x") # [2, 8, 6, 3, 3]
  #
  #     myModel.agents.with("o.id < 100").ask("o.color = [255, 0, 0]")
  ask: (array, functionString) ->
    if u.isString functionString
      eval("functionString=function(o){return " + functionString + ";}")
    functionString(object) for object in array
    array

  with: (array, functionString) ->
    if u.isString functionString
      eval("f=function(o){return " + functionString + ";}")
    @from (object for object in array when functionString(object))
 
  # ### Property Utilities

  # Property access, also useful for debugging<br>
  
  # Return an array of a property of the agentset
  #
  #      AS.getProperty "x" # [0, 8, 6, 1, 1]
  # TODO Prop -> Property
  getProperty: (array, property) ->
    object[property] for object in array

  # Return an array of agents with the property equal to the given value
  #
  #     AS.getPropertyWith "x", 1
  #     [{id: 4, x: 1, y: 3},{id: 5, x: 1, y: 1}]
  getPropertyWith: (array, property, value) ->
    @from (object for object in array when object[property] is value)

  # Set the property of the agents to a given value.  If value
  # is an array, its values will be used, indexed by agentSet's index.
  # This is generally used via: getProperty, modify results, setProperty
  #
  #     # increment x for agents with x=1
  #     AS1 = ABM.Set.from AS.getPropertyWith("x", 1)
  #     AS1.setProperty "x", 2 # {id: 4, x: 2, y: 3}, {id: 5, x: 2, y: 1}
  #
  # Note this changes the last two objects in the original AS above
  setProperty: (array, property, value) ->
    if u.isArray value
      object[property] = value[i] for object, i in array
    else
      object[property] = value for object in array
    array
 
  # Return an array without given object
  #
  #     as = AS.clone().other(AS[0])
  #     as.getProperty "id"  # [1, 2, 3, 4] 
  other: (array, given) ->
    @from (object for object in array when object isnt given) # could clone & remove


# Extends ABM.Array and util
  
ABM.util.array.extender =
  methods: ->
    (key for key, value of ABM.util.array when typeof value is 'function')

  extendArray: (className) ->
    methods = @methods()
    for method in methods
      eval("""
        #{className}.prototype.#{method} = function() {
          var options, _ref, _ret;
          options = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _ret = (_ref = u.array).#{method}.apply(_ref, [this].concat(__slice.call(options)));
          if (ABM.util.isArray(_ret)) {
            return this.constructor.from(_ret);
          } else {
            return _ret;
          }
        };""")
