# An **ABM.Array** is an array, with some helper methods.
#
# It is a subclass of `Array` and is the base class for `ABM.Set`.
#
# Note: subclassing `Array` can be dangerous and we may have to convert
# to a different style. See Trevor Burnham's [comments](http://goo.gl/Lca8g)
# but thus far we've resolved all related problems.

# Shim for `Array.indexOf` if not implemented.
# Use [es5-shim](https://github.com/kriskowal/es5-shim) if additional shims needed.
# TODO look into
Array::indexOf or= (given) ->
  for object, i in @
    return i if object is given
  -1

Array::_sort = Array::sort

# Extended with ABM.util.array

class ABM.Array extends Array
  # ### Static members
  
  # `from` is a static wrapper function converting an array into
  # an `ABM.Array` ..
  #
  # It gains access to all the methods below. Ex:
  #
  #     array = [1, 2, 3]
  #     ABM.Array.from(array)
  #     randomNr = array.random()
  @from: (array, arrayType = ABM.Array) ->
    array.__proto__ = arrayType.prototype ? arrayType.constructor.prototype
    array
 
  # WARNING: Needs constructor or subclassing Array won't work
  constructor: (options...) ->
    return @constructor.from(options)
 
# ### Extending

# Adds most methods
#
ABM.util.array.extender.extendArray('ABM.Array')
