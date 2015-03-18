# RGB <> HSL (Hue, Saturation, Lightness) conversions.
#
# r,g,b are ints in [0-255], i.e. 3 unsigned bytes of a pixel.
# h int in [0-360] degrees; s,l ints [0-100] percents; (h=0 same as h=360)
# See [Wikipedia](http://en.wikipedia.org/wiki/HSV_color_space)
# and [Blog Post](
# http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c)
#
# This is a [good table of hues](
# http://dev.w3.org/csswg/css-color/#named-hue-examples)
# and this is the [W3C HSL standard](
# http://www.w3.org/TR/css3-color/#hsl-color)
#
# Note that HSL is [not the same as HSB/HSV](
# http://en.wikipedia.org/wiki/HSL_and_HSV)

# Convert r,g,b to [h,s,l] Array. Note opaque, no "a" value
ABM.Color.rgbToHsl = (r, g, b) ->
  r = r/255; g = g/255; b = b/255
  max = Math.max(r,g,b); min = Math.min(r,g,b)
  sum = max + min; diff = max - min
  l = sum/2 # lightness = average of the largest and smallest rgb's
  if max is min
    h = s = 0 # achromatic, a shade of gray
  else
    s = if l > 0.5 then diff/(2-sum) else diff/sum
    switch max
      when r then h = ((g - b) / diff) + (if g < b then 6 else 0)
      when g then h = ((b - r) / diff) + 2
      when b then h = ((r - g) / diff) + 4
  [Math.round(360*h/6), Math.round(s*100), Math.round(l*100)]
