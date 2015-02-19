# Experimental: A function performing a dynamic mixin for a new color.
# To add a new color to a class, like "labelColor", the following is created:
#
# * A defineProperty for labelColor which calls a setter/getter pair:
# * .. named: setLableColor/getLabelColor
# * .. which manage a property: labelColorProp
# * .. defaulted to the supplied default color
# * A colormap property is created, labelColorMap, w/ no setter/getter
# * A private colorType is associated with labelColor, within the closure
colorMixin = (obj, colorName, colorDefault, colorMap=null, colorType="typed") ->
  # If obj is a class, use its prototype
  proto = obj.prototype ? obj
  # Capitolize 1st char of colorName for creating property names
  colorTitle = u.upperCamelCase colorName
  # Names we're adding to the prototype.
  # We don't add colorType, its in this closure.
  colorPropName = colorName+"Prop"
  colorMapName = colorName + "Map"
  getterName = "get#{colorTitle}"
  setterName = "set#{colorTitle}"
  # Add names to proto.
  proto[colorPropName] = Color.convertColor colorDefault, colorType
  proto[colorMapName] = colorMap
  unless proto[setterName]
    proto[setterName] = (r,g,b,a=255) ->
      # Setter: If a single argument given, convert to a valid color
      if g is undefined
        color = Color.convertColor r, colorType # type check/conversion
      else if @[colorMapName]
        # If a colormap exists, use the closest map color.
        # Assume map is of correct colorType.
        color = @[colorMapName].findClosestColor r, g, b, a
      else
        # If no colormap, set the color to the r,g,b,a values
        if @hasOwnProperty(colorPropName) and colorType is "typed"
          # If a typed color already created, use it
          color = @[colorPropName]
          color.setColor r,g,b,a
        else
          # .. otherwise create a new one
          color = Color.rgbaToColor r, g, b, a, colorType
      @[colorPropName] = color
    # Getter: return the colorPropName's value
    proto[getterName] = -> @[colorPropName]
  # define the color property
  Object.defineProperty proto, colorName,
    get: -> @[getterName]()
    set: (val) -> @[setterName](val)
  proto