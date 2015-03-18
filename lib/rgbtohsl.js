(function() {
  ABM.Color.rgbToHsl = function(r, g, b) {
    var diff, h, l, max, min, s, sum;
    r = r / 255;
    g = g / 255;
    b = b / 255;
    max = Math.max(r, g, b);
    min = Math.min(r, g, b);
    sum = max + min;
    diff = max - min;
    l = sum / 2;
    if (max === min) {
      h = s = 0;
    } else {
      s = l > 0.5 ? diff / (2 - sum) : diff / sum;
      switch (max) {
        case r:
          h = ((g - b) / diff) + (g < b ? 6 : 0);
          break;
        case g:
          h = ((b - r) / diff) + 2;
          break;
        case b:
          h = ((r - g) / diff) + 4;
      }
    }
    return [Math.round(360 * h / 6), Math.round(s * 100), Math.round(l * 100)];
  };

}).call(this);
