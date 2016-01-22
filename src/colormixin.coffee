# Experimental: A function performing a dynamic mixin for a new color.
# To add a new color to a class, like "labelColor", the following is created:
#
# * labelColor: A defineProperty which calls a setter/getter method pair:
# * setLableColor/getLabelColor: (will not be overridden if present)
# * labelColorProp: the property used by set/get method, default to colorDefault
# * colorType: the type associated with labelColor, private within the closure
colorMixin = (obj, colorName, colorDefault, colorType="typed") ->
  # If obj is a class, use its prototype
  proto = obj.prototype ? obj
  # Capitolize 1st char of colorName for creating property names
  colorTitle = u.upperCamelCase colorName
  # Names we're adding to the prototype.
  # We don't add colorType, its in this closure.
  colorPropName = colorName + "Prop"
  getterName = "get#{colorTitle}"
  setterName = "set#{colorTitle}"
  # Add names to proto.
  proto[colorPropName] =
    if colorDefault then Color.convertColor colorDefault, colorType else null
  # Add setter if not already there:
  unless proto[setterName]?
    proto[setterName] = (r,g,b,a=255) ->
      # Setter: If a single argument given, convert to a valid color
      if g is undefined
        color = Color.convertColor r, colorType # type check/conversion
      # If own, non colormap color, use setter
      else if @hasOwnProperty(colorPropName) and
        colorType is "typed" and
        not (color = @[colorPropName]).map?
          color.setColor r,g,b,a
      # .. otherwise create a new color
      else
        console.log "new color"
        color = Color.rgbaToColor r, g, b, a, colorType
      @[colorPropName] = color
  unless proto[getterName]?
    # Getter: return the colorPropName's value
    proto[getterName] = -> @[colorPropName]
  # define the color property
  Object.defineProperty proto, colorName,
    get: -> @[getterName]()
    set: (val) -> @[setterName](val)
  proto
