(function() {
  var AgentSet, Animator, Color, ColorMaps, Evented, Link, Links, Model, Patch, Patches, Shapes, Turtle, Turtles, Util, colorMixin, u, util,
    hasProp = {}.hasOwnProperty,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    slice = [].slice,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Util = util = u = {
    error: function(s) {
      throw new Error(s);
    },
    loggedMsgs: [],
    logOnce: function(s) {
      if (this.loggedMsgs.indexOf(s) < 0) {
        console.log(s);
        return this.loggedMsgs.push(s);
      }
    },
    deprecatedAlert: false,
    deprecated: function(s) {
      if (this.deprecatedAlert) {
        alert("Deprecated functions, see console.log");
        this.deprecatedAlert = false;
      }
      return this.logOnce("DEPRECATED - " + s);
    },
    MaxINT: Math.pow(2, 53),
    MinINT: -Math.pow(2, 53),
    MaxINT32: 0 | 0x7fffffff,
    MinINT32: 0 | 0x80000000,
    isArray: Array.isArray || function(obj) {
      return toString.call(obj) === '[object Array]';
    },
    isFunction: function(obj) {
      return typeof obj === "function";
    },
    isString: function(obj) {
      return typeof obj === 'string' || obj instanceof String;
    },
    isInteger: Number.isInteger || function(num) {
      return Math.floor(num) === num;
    },
    isObject: function(obj) {
      return toString.call(obj) === '[object Object]';
    },
    randomSeed: function(seed) {
      if (seed == null) {
        seed = 123456;
      }
      return Math.random = function() {
        var x;
        x = Math.sin(seed++) * 10000;
        return x - Math.floor(x);
      };
    },
    randomInt: function(max) {
      return Math.floor(Math.random() * max);
    },
    randomInt2: function(min, max) {
      return min + Math.floor(Math.random() * (max - min));
    },
    randomNormal: function(mean, sigma) {
      var norm, u1, u2;
      if (mean == null) {
        mean = 0.0;
      }
      if (sigma == null) {
        sigma = 1.0;
      }
      u1 = 1.0 - Math.random();
      u2 = Math.random();
      norm = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2);
      return norm * sigma + mean;
    },
    randomFloat: function(max) {
      return Math.random() * max;
    },
    randomFloat2: function(min, max) {
      return min + Math.random() * (max - min);
    },
    randomCentered: function(r) {
      return this.randomFloat2(-r / 2, r / 2);
    },
    log10: function(n) {
      return Math.log(n) / Math.LN10;
    },
    log2: function(n) {
      return this.logN(n, 2);
    },
    logN: function(n, base) {
      return Math.log(n) / Math.log(base);
    },
    mod: function(v, n) {
      return ((v % n) + n) % n;
    },
    wrap: function(v, min, max) {
      return min + this.mod(v - min, max - min);
    },
    clamp: function(v, min, max) {
      if (v < min) {
        return min;
      }
      if (v > max) {
        return max;
      }
      return v;
    },
    sign: function(v) {
      if (v < 0) {
        return -1;
      } else {
        return 1;
      }
    },
    fixed: function(n, p) {
      if (p == null) {
        p = 2;
      }
      p = Math.pow(10, p);
      return Math.round(n * p) / p;
    },
    aToFixed: function(a, p) {
      var i, len, m, results;
      if (p == null) {
        p = 2;
      }
      results = [];
      for (m = 0, len = a.length; m < len; m++) {
        i = a[m];
        results.push(i.toFixed(p));
      }
      return results;
    },
    tls: function(n) {
      return n.toLocaleString();
    },
    titleCase: function(str) {
      return str.charAt(0).toUpperCase() + str.substr(1);
    },
    camelCase: function(str) {
      return str.charAt(0).toLowerCase() + str.substr(1);
    },
    randomColor: function(c) {
      if (c == null) {
        c = [];
      }
      this.deprecated("Util.randomColor: use ColorMaps.randomColor");
      if (c.length !== 0) {
        this.error("Util.randomColor: c cannot be exiting color");
      }
      return ColorMaps.randomColor();
    },
    randomGray: function(c, min, max) {
      if (c == null) {
        c = [];
      }
      if (min == null) {
        min = 64;
      }
      if (max == null) {
        max = 192;
      }
      if (arguments.length === 2) {
        return this.randomGray(null, c, min);
      }
      this.deprecated("Util.randomGray: use ColorMaps.randomGray");
      if (c.length !== 0) {
        this.error("Util.randomGray: c cannot be exiting color");
      }
      return ColorMaps.randomGray(min, max);
    },
    randomMapColor: function(c, set) {
      if (c == null) {
        c = [];
      }
      if (set == null) {
        set = [0, 63, 127, 191, 255];
      }
      this.deprecated("Util.randomMapColor: use ColorMaps.randomColor() or similar");
      if (c.length !== 0) {
        this.error("Util.randomMapColor: c cannot be exiting color");
      }
      return ColorMaps.randomColor();
    },
    setColor: function(c, r, g, b, a) {
      this.deprecated("Util.setColor: use the Color/ColorMaps modules");
      if (c.setColor != null) {
        if (c.map) {
          this.error("Util.setColor: cannot modify colormap colors");
        } else {
          c.setColor(r, g, b, a);
        }
      } else {
        c[0] = r;
        c[1] = g;
        c[2] = b;
        if (a != null) {
          c[3] = a;
        }
      }
      return c;
    },
    setGray: function(c, g, a) {
      this.deprecated("Util.setGray: use the Color/ColorMaps modules");
      return this.setColor(c, g, g, g, a);
    },
    scaleColor: function(max, s, c) {
      if (c == null) {
        c = [];
      }
      this.deprecated("Util.scaleColor: use the Color/ColorMaps modules");
      this.error("Util.scaleColor: cannot modify colormap colors");
      return ColorMaps.Rgb.findClosestColor(Color.rgbLerp(max, s));
    },
    scaleOpacity: function(rgba, scale, c) {
      if (c == null) {
        c = this.clone(rgba);
      }
      this.deprecated("Util.scaleOpacity: use the Color/ColorMaps modules");
      if (this.isArray(rgba)) {
        if (c[3] == null) {
          c[3] = 1;
        }
        c[3] = this.lerp(0, c[3], scale);
      } else {
        c[3] = this.lerp(0, c[3], scale);
        if (c.map) {
          c = Color.typedColor.apply(Color, c);
        } else {
          c.setColor.apply(c, c);
        }
      }
      return c;
    },
    colorStr: function(c) {
      var ref;
      this.deprecated("Util.colorStr: use Color module or typedColor");
      return (ref = c.css) != null ? ref : Color.arrayToColor(c, "css");
    },
    colorsEqual: function(c1, c2) {
      this.deprecated("Util.colorsEqual: use Color/ColorMaps or typedColor.pixel");
      return Color.colorsEqual(c1, c2);
    },
    rgbToGray: function(c) {
      this.deprecated("Util.rgbToGray: use Color.rgbIntensity");
      return Color.rgbIntensity.apply(Color, c);
    },
    rgbToHsb: function(c) {
      var b, d, g, h, max, min, r, s, v;
      this.deprecated("Util.rgbToHsb: use extras/rgbToHsl");
      r = c[0] / 255;
      g = c[1] / 255;
      b = c[2] / 255;
      max = Math.max(r, g, b);
      min = Math.min(r, g, b);
      v = max;
      h = 0;
      d = max - min;
      s = max === 0 ? 0 : d / max;
      if (max !== min) {
        switch (max) {
          case r:
            h = (g - b) / d + (g < b ? 6 : 0);
            break;
          case g:
            h = (b - r) / d + 2;
            break;
          case b:
            h = (r - g) / d + 4;
        }
      }
      return [Math.round(255 * h / 6), Math.round(255 * s), Math.round(255 * v)];
    },
    hsbToRgb: function(c) {
      var b, f, g, h, i, p, q, r, s, t, v;
      this.deprecated("Util.hsbToRgb: use Color/ColorMaps HSL functions");
      h = c[0] / 255;
      s = c[1] / 255;
      v = c[2] / 255;
      i = Math.floor(h * 6);
      f = h * 6 - i;
      p = v * (1 - s);
      q = v * (1 - f * s);
      t = v * (1 - (1 - f) * s);
      switch (i % 6) {
        case 0:
          r = v;
          g = t;
          b = p;
          break;
        case 1:
          r = q;
          g = v;
          b = p;
          break;
        case 2:
          r = p;
          g = v;
          b = t;
          break;
        case 3:
          r = p;
          g = q;
          b = v;
          break;
        case 4:
          r = t;
          g = p;
          b = v;
          break;
        case 5:
          r = v;
          g = p;
          b = q;
      }
      return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
    },
    rgbMap: function(R, G, B) {
      if (G == null) {
        G = R;
      }
      if (B == null) {
        B = R;
      }
      this.deprecated("Util.rgbMap: use ColorMaps.rgbColorMap or Rgb/Rgb256");
      return ColorMaps.rgbColorMap(R, G, B);
    },
    grayMap: function() {
      this.deprecated("Util.grayMap: use ColorMaps.grayColorMap or Gray");
      return ColorMaps.Gray;
    },
    hsbMap: function(n, s, b) {
      if (n == null) {
        n = 256;
      }
      if (s == null) {
        s = 255;
      }
      if (b == null) {
        b = 255;
      }
      this.deprecated("Util.hsbMap: use ColorMaps.hslColorMap");
      return ColorMaps.hslColorMap(n, 1, 1);
    },
    isLittleEndian: function() {
      var d32;
      d32 = new Uint32Array([0x01020304]);
      return (new Uint8ClampedArray(d32.buffer))[0] === 4;
    },
    degToRad: function(degrees) {
      return degrees * Math.PI / 180;
    },
    radToDeg: function(radians) {
      return radians * 180 / Math.PI;
    },
    subtractRads: function(rad1, rad2) {
      var PI, dr;
      dr = rad1 - rad2;
      PI = Math.PI;
      if (dr <= -PI) {
        dr += 2 * PI;
      }
      if (dr > PI) {
        dr -= 2 * PI;
      }
      return dr;
    },
    ownKeys: function(obj) {
      var key, results, value;
      results = [];
      for (key in obj) {
        if (!hasProp.call(obj, key)) continue;
        value = obj[key];
        results.push(key);
      }
      return results;
    },
    ownVarKeys: function(obj) {
      var key, results, value;
      results = [];
      for (key in obj) {
        if (!hasProp.call(obj, key)) continue;
        value = obj[key];
        if (!this.isFunction(value)) {
          results.push(key);
        }
      }
      return results;
    },
    ownValues: function(obj) {
      var key, results, value;
      results = [];
      for (key in obj) {
        if (!hasProp.call(obj, key)) continue;
        value = obj[key];
        results.push(value);
      }
      return results;
    },
    mixinObject: function(destObj, srcObject) {
      var key, keys, len, m, prop;
      keys = Object.getOwnPropertyNames(srcObject);
      for (m = 0, len = keys.length; m < len; m++) {
        key = keys[m];
        prop = Object.getOwnPropertyDescriptor(srcObject, key);
        Object.defineProperty(destObj, key, prop);
      }
      return destObj;
    },
    cloneObject: function(obj) {
      var newObj;
      newObj = Object.create(Object.getPrototypeOf(obj));
      return this.mixinObject(newObj, obj);
    },
    cloneClass: function(oldClass, newName) {
      var ctorStr;
      ctorStr = oldClass.toString().replace(/^/, "var ctor = ");
      if (newName) {
        ctorStr = ctorStr.replace(/function.*(?=\()/, "function " + newName);
      }
      eval(ctorStr);
      ctor.prototype = this.cloneObject(oldClass.prototype);
      return ctor;
    },
    mixin: function(destObj, srcObject) {
      var destProto, key, results, srcProto;
      for (key in srcObject) {
        if (!hasProp.call(srcObject, key)) continue;
        destObj[key] = srcObject[key];
      }
      destProto = Object.getPrototypeOf(destObj);
      srcProto = Object.getPrototypeOf(srcObject);
      results = [];
      for (key in srcProto) {
        if (!hasProp.call(srcProto, key)) continue;
        results.push(destProto[key] = srcProto[key]);
      }
      return results;
    },
    parseToPrimitive: function(s) {
      var e, error1;
      try {
        return JSON.parse(s);
      } catch (error1) {
        e = error1;
        return decodeURIComponent(s);
      }
    },
    parseQueryString: function(query) {
      var len, m, ref, res, s, t;
      if (query == null) {
        query = window.location.search.substring(1);
      }
      res = {};
      ref = query.split("&");
      for (m = 0, len = ref.length; m < len; m++) {
        s = ref[m];
        if (!(query.length !== 0)) {
          continue;
        }
        t = s.split("=");
        res[t[0]] = t.length === 1 ? true : this.parseToPrimitive(t[1]);
      }
      return res;
    },
    any: function(array) {
      return array.length !== 0;
    },
    empty: function(array) {
      return array.length === 0;
    },
    clone: function(array, begin, end) {
      var op;
      op = array.slice != null ? "slice" : "subarray";
      if (begin != null) {
        return array[op](begin, end);
      } else {
        return array[op](0);
      }
    },
    last: function(array) {
      if (this.empty(array)) {
        this.error("last: empty array");
      }
      return array[array.length - 1];
    },
    oneOf: function(array) {
      if (this.empty(array)) {
        this.error("oneOf: empty array");
      }
      return array[this.randomInt(array.length)];
    },
    nOf: function(array, n) {
      var o, r;
      n = Math.min(array.length, Math.floor(n));
      r = [];
      while (r.length < n) {
        o = this.oneOf(array);
        if (indexOf.call(r, o) < 0) {
          r.push(o);
        }
      }
      return r;
    },
    contains: function(array, item, f) {
      return this.indexOf(array, item, f) >= 0;
    },
    removeItem: function(array, item, f) {
      var i;
      if (!((i = this.indexOf(array, item, f)) < 0)) {
        array.splice(i, 1);
      }
      return array;
    },
    removeItems: function(array, items, f) {
      var i, len, m;
      for (m = 0, len = items.length; m < len; m++) {
        i = items[m];
        this.removeItem(array, i, f);
      }
      return array;
    },
    insertItem: function(array, item, f) {
      var i;
      i = this.sortedIndex(array, item, f);
      if (array[i] === item) {
        error("insertItem: item already in array");
      }
      return array.splice(i, 0, item);
    },
    shuffle: function(array) {
      return array.sort(function() {
        return 0.5 - Math.random();
      });
    },
    minOneOf: function(array, f, valueToo) {
      var a, len, m, o, r, r1;
      if (f == null) {
        f = this.identity;
      }
      if (valueToo == null) {
        valueToo = false;
      }
      if (this.empty(array)) {
        this.error("minOneOf: empty array");
      }
      r = Infinity;
      o = null;
      if (this.isString(f)) {
        f = this.propFcn(f);
      }
      for (m = 0, len = array.length; m < len; m++) {
        a = array[m];
        if ((r1 = f(a)) < r) {
          r = r1;
          o = a;
        }
      }
      if (valueToo) {
        return [o, r];
      } else {
        return o;
      }
    },
    maxOneOf: function(array, f, valueToo) {
      var a, len, m, o, r, r1;
      if (f == null) {
        f = this.identity;
      }
      if (valueToo == null) {
        valueToo = false;
      }
      if (this.empty(array)) {
        this.error("maxOneOf: empty array");
      }
      r = -Infinity;
      o = null;
      if (this.isString(f)) {
        f = this.propFcn(f);
      }
      for (m = 0, len = array.length; m < len; m++) {
        a = array[m];
        if ((r1 = f(a)) > r) {
          r = r1;
          o = a;
        }
      }
      if (valueToo) {
        return [o, r];
      } else {
        return o;
      }
    },
    firstOneOf: function(array, f) {
      var a, i, len, m;
      for (i = m = 0, len = array.length; m < len; i = ++m) {
        a = array[i];
        if (f(a)) {
          return i;
        }
      }
      return -1;
    },
    histOf: function(array, bin, f) {
      var a, aa, i, len, len1, m, r, ri, val;
      if (bin == null) {
        bin = 1;
      }
      if (f == null) {
        f = function(i) {
          return i;
        };
      }
      r = [];
      if (this.isString(f)) {
        f = this.propFcn(f);
      }
      for (m = 0, len = array.length; m < len; m++) {
        a = array[m];
        i = Math.floor(f(a) / bin);
        r[i] = (ri = r[i]) != null ? ri + 1 : 1;
      }
      for (i = aa = 0, len1 = r.length; aa < len1; i = ++aa) {
        val = r[i];
        if (val == null) {
          r[i] = 0;
        }
      }
      return r;
    },
    sortBy: function(array, f) {
      if (this.isString(f)) {
        return array.sort(function(a, b) {
          return a[f] - b[f];
        });
      } else {
        return array.sort(function(a, b) {
          return f(a) - f(b);
        });
      }
    },
    sortNums: function(array, ascending) {
      var f;
      if (ascending == null) {
        ascending = true;
      }
      f = ascending ? function(a, b) {
        return a - b;
      } : function(a, b) {
        return b - a;
      };
      if (array.sort != null) {
        return array.sort(f);
      } else {
        return Array.prototype.sort.call(array, f);
      }
    },
    uniq: function(array) {
      var i, m, ref;
      if (array.length < 2) {
        return array;
      }
      for (i = m = ref = array.length - 1; m >= 1; i = m += -1) {
        if (array[i - 1] === array[i]) {
          array.splice(i, 1);
        }
      }
      return array;
    },
    flatten: function(matrix) {
      return matrix.reduce(function(a, b) {
        return a.concat(b);
      });
    },
    aProp: function(array, propOrFn) {
      var a, aa, len, len1, m, results, results1;
      if (typeof propOrFn === 'function') {
        results = [];
        for (m = 0, len = array.length; m < len; m++) {
          a = array[m];
          results.push(propOrFn(a));
        }
        return results;
      } else {
        results1 = [];
        for (aa = 0, len1 = array.length; aa < len1; aa++) {
          a = array[aa];
          results1.push(a[propOrFn]);
        }
        return results1;
      }
    },
    aToObj: function(array, names) {
      var i, len, m, n;
      for (i = m = 0, len = names.length; m < len; i = ++m) {
        n = names[i];
        array[n] = array[i];
      }
      return array;
    },
    aMax: function(array) {
      var a, len, m, v;
      v = array[0];
      for (m = 0, len = array.length; m < len; m++) {
        a = array[m];
        v = Math.max(v, a);
      }
      return v;
    },
    aMin: function(array) {
      var a, len, m, v;
      v = array[0];
      for (m = 0, len = array.length; m < len; m++) {
        a = array[m];
        v = Math.min(v, a);
      }
      return v;
    },
    aSum: function(array) {
      var a, len, m, v;
      v = 0;
      for (m = 0, len = array.length; m < len; m++) {
        a = array[m];
        v += a;
      }
      return v;
    },
    aAvg: function(array) {
      return this.aSum(array) / array.length;
    },
    aMid: function(array) {
      array = array.sort != null ? this.clone(array) : this.typedToJS(array);
      this.sortNums(array);
      return array[Math.floor(array.length / 2)];
    },
    aStats: function(array) {
      var avg, max, mid, min;
      min = this.aMin(array);
      max = this.aMax(array);
      avg = this.aAvg(array);
      mid = this.aMid(array);
      return {
        min: min,
        max: max,
        avg: avg,
        mid: mid
      };
    },
    aNaNs: function(array) {
      var i, len, m, results, v;
      results = [];
      for (i = m = 0, len = array.length; m < len; i = ++m) {
        v = array[i];
        if (isNaN(v)) {
          results.push(i);
        }
      }
      return results;
    },
    aRange: function(start, stop, step) {
      var m, ref, ref1, ref2, results, x;
      if (step == null) {
        step = 1;
      }
      results = [];
      for (x = m = ref = start, ref1 = stop, ref2 = step; ref2 > 0 ? m <= ref1 : m >= ref1; x = m += ref2) {
        results.push(x);
      }
      return results;
    },
    aRamp: function(start, stop, numItems) {
      var i, m, ref, results;
      results = [];
      for (i = m = 0, ref = numItems; 0 <= ref ? m < ref : m > ref; i = 0 <= ref ? ++m : --m) {
        results.push(start + (stop - start) * (i / (numItems - 1)));
      }
      return results;
    },
    aIntRamp: function(start, stop, numItems) {
      var len, m, num, ref, results;
      ref = this.aRamp(start, stop, numItems);
      results = [];
      for (m = 0, len = ref.length; m < len; m++) {
        num = ref[m];
        results.push(Math.round(num));
      }
      return results;
    },
    aPairwise: function(a1, a2, f) {
      var i, len, m, results, v;
      v = 0;
      results = [];
      for (i = m = 0, len = a1.length; m < len; i = ++m) {
        v = a1[i];
        results.push(f(v, a2[i]));
      }
      return results;
    },
    aPairSum: function(a1, a2) {
      return this.aPairwise(a1, a2, function(a, b) {
        return a + b;
      });
    },
    aPairDif: function(a1, a2) {
      return this.aPairwise(a1, a2, function(a, b) {
        return a - b;
      });
    },
    aPairMul: function(a1, a2) {
      return this.aPairwise(a1, a2, function(a, b) {
        return a * b;
      });
    },
    typedToJS: function(typedArray) {
      var i, len, m, results;
      results = [];
      for (m = 0, len = typedArray.length; m < len; m++) {
        i = typedArray[m];
        results.push(i);
      }
      return results;
    },
    lerp: function(lo, hi, scale) {
      scale = this.clamp(scale, 0, 1);
      if (lo <= hi) {
        return lo + (hi - lo) * scale;
      } else {
        return lo - (lo - hi) * scale;
      }
    },
    lerpScale: function(number, lo, hi) {
      return (number - lo) / (hi - lo);
    },
    lerp2: function(x0, y0, x1, y1, scale) {
      return [this.lerp(x0, x1, scale), this.lerp(y0, y1, scale)];
    },
    normalize: function(array, lo, hi) {
      var len, m, max, min, num, results, scale;
      if (lo == null) {
        lo = 0;
      }
      if (hi == null) {
        hi = 1;
      }
      min = this.aMin(array);
      max = this.aMax(array);
      scale = 1 / (max - min);
      results = [];
      for (m = 0, len = array.length; m < len; m++) {
        num = array[m];
        results.push(this.lerp(lo, hi, scale * (num - min)));
      }
      return results;
    },
    normalize8: function(array) {
      return new Uint8ClampedArray(this.normalize(array, -.5, 255.5));
    },
    normalizeInt: function(array, lo, hi) {
      var i, len, m, ref, results;
      ref = this.normalize(array, lo, hi);
      results = [];
      for (m = 0, len = ref.length; m < len; m++) {
        i = ref[m];
        results.push(Math.round(i));
      }
      return results;
    },
    sortedIndex: function(array, item, f) {
      var high, low, mid, value;
      if (f == null) {
        f = function(o) {
          return o;
        };
      }
      if (this.isString(f)) {
        f = this.propFcn(f);
      }
      value = f(item);
      low = 0;
      high = array.length;
      while (low < high) {
        mid = (low + high) >>> 1;
        if (f(array[mid]) < value) {
          low = mid + 1;
        } else {
          high = mid;
        }
      }
      return low;
    },
    identity: function(o) {
      return o;
    },
    propFcn: function(prop) {
      return function(o) {
        return o[prop];
      };
    },
    indexOf: function(array, item, property) {
      var i;
      if (property != null) {
        i = this.sortedIndex(array, item, property === "" ? null : property);
        if (array[i] === item) {
          return i;
        } else {
          return -1;
        }
      } else {
        return array.indexOf(item);
      }
    },
    radsToward: function(x1, y1, x2, y2) {
      return Math.atan2(y2 - y1, x2 - x1);
    },
    inRect: function(x, y, minX, minY, maxX, maxY) {
      return ((minX <= x && x <= maxX)) && ((minY <= y && y <= maxY));
    },
    inCenteredRect: function(x, y, x0, y0, dx, dy) {
      return (x0 - dx <= x && x <= x0 + dx) && (y0 - dy <= y && y <= y0 + dy);
    },
    inCone: function(radius, angle, heading, x1, y1, x2, y2) {
      var angle12;
      if (radius < this.distance(x1, y1, x2, y2)) {
        return false;
      }
      angle12 = this.radsToward(x1, y1, x2, y2);
      return angle / 2 >= Math.abs(this.subtractRads(heading, angle12));
    },
    distance: function(x1, y1, x2, y2) {
      var dx, dy;
      dx = x1 - x2;
      dy = y1 - y2;
      return Math.sqrt(dx * dx + dy * dy);
    },
    sqDistance: function(x1, y1, x2, y2) {
      var dx, dy;
      dx = x1 - x2;
      dy = y1 - y2;
      return dx * dx + dy * dy;
    },
    polarToXY: function(r, theta, x, y) {
      if (x == null) {
        x = 0;
      }
      if (y == null) {
        y = 0;
      }
      return [x + r * Math.cos(theta), y + r * Math.sin(theta)];
    },
    torusDistance: function(x1, y1, x2, y2, w, h) {
      return Math.sqrt(this.torusSqDistance(x1, y1, x2, y2, w, h));
    },
    torusSqDistance: function(x1, y1, x2, y2, w, h) {
      var dx, dxMin, dy, dyMin;
      dx = Math.abs(x2 - x1);
      dy = Math.abs(y2 - y1);
      dxMin = Math.min(dx, w - dx);
      dyMin = Math.min(dy, h - dy);
      return dxMin * dxMin + dyMin * dyMin;
    },
    torusWraps: function(x1, y1, x2, y2, w, h) {
      var dx, dy;
      dx = Math.abs(x2 - x1);
      dy = Math.abs(y2 - y1);
      return dx > w - dx || dy > h - dy;
    },
    torus4Pts: function(x1, y1, x2, y2, w, h) {
      var x2r, y2r;
      x2r = x2 < x1 ? x2 + w : x2 - w;
      y2r = y2 < y1 ? y2 + h : y2 - h;
      return [[x2, y2], [x2r, y2], [x2, y2r], [x2r, y2r]];
    },
    torusPt: function(x1, y1, x2, y2, w, h) {
      var x, x2r, y, y2r;
      x2r = x2 < x1 ? x2 + w : x2 - w;
      y2r = y2 < y1 ? y2 + h : y2 - h;
      x = Math.abs(x2r - x1) < Math.abs(x2 - x1) ? x2r : x2;
      y = Math.abs(y2r - y1) < Math.abs(y2 - y1) ? y2r : y2;
      return [x, y];
    },
    torusRadsToward: function(x1, y1, x2, y2, w, h) {
      var ref;
      ref = this.torusPt(x1, y1, x2, y2, w, h), x2 = ref[0], y2 = ref[1];
      return this.radsToward(x1, y1, x2, y2);
    },
    inTorusCone: function(radius, angle, heading, x1, y1, x2, y2, w, h) {
      var len, m, p, ref;
      ref = this.torus4Pts(x1, y1, x2, y2, w, h);
      for (m = 0, len = ref.length; m < len; m++) {
        p = ref[m];
        if (this.inCone(radius, angle, heading, x1, y1, p[0], p[1])) {
          return true;
        }
      }
      return false;
    },
    inTorusRect: function(x, y, minX, minY, maxX, maxY, w, h) {
      if (x < minX) {
        x += w;
      } else if (x > maxX) {
        x -= w;
      }
      if (y < minY) {
        y += h;
      } else if (y > maxY) {
        y -= h;
      }
      return ((minX <= x && x <= maxX)) && ((minY <= y && y <= maxY));
    },
    fileIndex: {},
    importImage: function(name, f) {
      var img;
      if (f == null) {
        f = function() {};
      }
      if ((img = this.fileIndex[name]) != null) {
        f(img);
      } else {
        this.fileIndex[name] = img = new Image();
        img.isDone = false;
        img.crossOrigin = "Anonymous";
        img.onload = function() {
          f(img);
          return img.isDone = true;
        };
        img.src = name;
      }
      return img;
    },
    xhrLoadFile: function(name, method, type, f) {
      var xhr;
      if (method == null) {
        method = "GET";
      }
      if (type == null) {
        type = "text";
      }
      if (f == null) {
        f = function() {};
      }
      if ((xhr = this.fileIndex[name]) != null) {
        f(xhr.response);
      } else {
        this.fileIndex[name] = xhr = new XMLHttpRequest();
        xhr.isDone = false;
        xhr.open(method, name);
        xhr.responseType = type;
        xhr.onload = function() {
          f(xhr.response);
          return xhr.isDone = true;
        };
        xhr.send();
      }
      return xhr;
    },
    filesLoaded: function(files) {
      var array, v;
      if (files == null) {
        files = this.fileIndex;
      }
      array = (function() {
        var len, m, ref, results;
        ref = this.ownValues(files);
        results = [];
        for (m = 0, len = ref.length; m < len; m++) {
          v = ref[m];
          results.push(v.isDone);
        }
        return results;
      }).call(this);
      return array.reduce((function(a, b) {
        return a && b;
      }), true);
    },
    waitOnFiles: function(f, files) {
      if (files == null) {
        files = this.fileIndex;
      }
      return this.waitOn(((function(_this) {
        return function() {
          return _this.filesLoaded(files);
        };
      })(this)), f);
    },
    waitOn: function(done, f) {
      if (done()) {
        return f();
      } else {
        return setTimeout(((function(_this) {
          return function() {
            return _this.waitOn(done, f);
          };
        })(this)), 1000);
      }
    },
    cloneImage: function(img) {
      var i;
      (i = new Image()).src = img.src;
      return i;
    },
    imageToData: function(img, f, arrayType) {
      if (f == null) {
        f = this.pixelByte(0);
      }
      if (arrayType == null) {
        arrayType = Uint8ClampedArray;
      }
      return this.imageRowsToData(img, img.height, f, arrayType);
    },
    imageRowsToData: function(img, rowsPerSlice, f, arrayType) {
      var ctx, data, dataStart, i, idata, m, ref, rows, rowsDone;
      if (f == null) {
        f = this.pixelByte(0);
      }
      if (arrayType == null) {
        arrayType = Uint8ClampedArray;
      }
      rowsDone = 0;
      data = new arrayType(img.width * img.height);
      while (rowsDone < img.height) {
        rows = Math.min(img.height - rowsDone, rowsPerSlice);
        ctx = this.imageSliceToCtx(img, 0, rowsDone, img.width, rows);
        idata = this.ctxToImageData(ctx).data;
        dataStart = rowsDone * img.width;
        for (i = m = 0, ref = idata.length / 4; m < ref; i = m += 1) {
          data[dataStart + i] = f(idata, 4 * i);
        }
        rowsDone += rows;
      }
      return data;
    },
    pixelBytesToInt: function(a) {
      var ImageByteFmts;
      ImageByteFmts = [[2], [1, 2], [0, 1, 2], [3, 0, 1, 2]];
      if (typeof a === "number") {
        a = ImageByteFmts[a - 1];
      }
      return function(id, i) {
        var j, len, m, val;
        val = 0;
        for (m = 0, len = a.length; m < len; m++) {
          j = a[m];
          val = val * 256 + id[i + j];
        }
        return val;
      };
    },
    pixelByte: function(n) {
      return function(id, i) {
        return id[i + n];
      };
    },
    createCanvas: function(width, height) {
      var can;
      can = document.createElement('canvas');
      can.width = width;
      can.height = height;
      return can;
    },
    createCtx: function(width, height, ctxType) {
      var can, ref;
      if (ctxType == null) {
        ctxType = "2d";
      }
      can = this.createCanvas(width, height);
      if (ctxType === "2d") {
        return can.getContext("2d");
      } else {
        return (ref = can.getContext("webgl")) != null ? ref : can.getContext("experimental-webgl");
      }
    },
    createLayer: function(div, width, height, z, ctx) {
      var element;
      if (ctx == null) {
        ctx = "2d";
      }
      if (ctx === "img") {
        element = ctx = new Image();
        ctx.width = width;
        ctx.height = height;
      } else {
        element = (ctx = this.createCtx(width, height, ctx)).canvas;
      }
      this.insertLayer(div, element, width, height, z);
      return ctx;
    },
    insertLayer: function(div, element, w, h, z) {
      var s;
      s = element.style;
      s.position = "absolute";
      s.top = 0;
      s.left = 0;
      s.width = w;
      s.height = h;
      s.zIndex = z;
      return div.appendChild(element);
    },
    setCtxSmoothing: function(ctx, smoothing) {
      var aliases, len, m, name;
      aliases = ["imageSmoothingEnabled", "mozImageSmoothingEnabled", "oImageSmoothingEnabled", "webkitImageSmoothingEnabled", "msImageSmoothingEnabled"];
      for (m = 0, len = aliases.length; m < len; m++) {
        name = aliases[m];
        if (ctx[name] != null) {
          return ctx[name] = smoothing;
        }
      }
    },
    setIdentity: function(ctx) {
      ctx.save();
      return ctx.setTransform(1, 0, 0, 1, 0, 0);
    },
    clearCtx: function(ctx) {
      if (ctx.save != null) {
        this.setIdentity(ctx);
        ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
        return ctx.restore();
      } else {
        ctx.clearColor(0, 0, 0, 0);
        return ctx.clear(ctx.COLOR_BUFFER_BIT | ctx.DEPTH_BUFFER_BIT);
      }
    },
    fillCtx: function(ctx, color) {
      var ref;
      if (ctx.fillStyle != null) {
        this.setIdentity(ctx);
        ctx.fillStyle = (ref = color.css) != null ? ref : Color.convertColor(color, "css");
        ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
        return ctx.restore();
      } else {
        ctx.clearColor.apply(ctx, slice.call(color).concat([1]));
        return ctx.clear(ctx.COLOR_BUFFER_BIT | ctx.DEPTH_BUFFER_BIT);
      }
    },
    ctxDrawText: function(ctx, string, x, y, color, setIdentity) {
      if (setIdentity == null) {
        setIdentity = true;
      }
      if (setIdentity) {
        this.setIdentity(ctx);
      }
      ctx.fillStyle = color.css;
      ctx.fillText(string, x, y);
      if (setIdentity) {
        return ctx.restore();
      }
    },
    ctxTextParams: function(ctx, font, align, baseline) {
      if (align == null) {
        align = "center";
      }
      if (baseline == null) {
        baseline = "middle";
      }
      ctx.font = font;
      ctx.textAlign = align;
      return ctx.textBaseline = baseline;
    },
    elementTextParams: function(e, font, align, baseline) {
      if (align == null) {
        align = "center";
      }
      if (baseline == null) {
        baseline = "middle";
      }
      if (e.canvas != null) {
        e = e.canvas;
      }
      e.style.font = font;
      e.style.textAlign = align;
      return e.style.textBaseline = baseline;
    },
    imageToCtx: function(img, w, h) {
      var ctx;
      if ((w != null) && (h != null)) {
        ctx = this.createCtx(w, h);
        ctx.drawImage(img, 0, 0, w, h);
      } else {
        ctx = this.createCtx(img.width, img.height);
        ctx.drawImage(img, 0, 0);
      }
      return ctx;
    },
    imageSliceToCtx: function(img, sx, sy, sw, sh, ctx) {
      if (ctx != null) {
        ctx.canvas.width = sw;
        ctx.canvas.height = sh;
      } else {
        ctx = this.createCtx(sw, sh);
      }
      ctx.drawImage(img, sx, sy, sw, sh, 0, 0, sw, sh);
      return ctx;
    },
    imageToCtxDownStepped: function(img, tw, th) {
      var can, ctx, ctx1, h, ihalf, m, ref, step, steps, w;
      ctx1 = this.createCtx(tw, th);
      w = img.width;
      h = img.height;
      ihalf = function(n) {
        return Math.ceil(n / 2);
      };
      steps = Math.ceil(this.log2((w / tw) > (h / th) ? w / tw : h / th));
      console.log("steps", steps);
      if (steps <= 1) {
        ctx1.drawImage(img, 0, 0, tw, th);
      } else {
        console.log("img w/h", w, h, "->", ihalf(w), ihalf(h));
        ctx = this.createCtx(w = ihalf(w), h = ihalf(h));
        can = ctx.canvas;
        ctx.drawImage(img, 0, 0, w, h);
        for (step = m = ref = steps; ref <= 2 ? m < 2 : m > 2; step = ref <= 2 ? ++m : --m) {
          console.log("can w/h", w, h, "->", ihalf(w), ihalf(h));
          ctx.drawImage(can, 0, 0, w, h, 0, 0, w = ihalf(w), h = ihalf(h));
        }
        console.log("target w/h", w, h, "->", tw, th);
        ctx1.drawImage(can, 0, 0, w, h, 0, 0, tw, th);
      }
      return ctx1;
    },
    ctxToDataUrl: function(ctx) {
      return ctx.canvas.toDataURL("image/png");
    },
    ctxToDataUrlImage: function(ctx, f) {
      var img;
      img = new Image();
      if (f != null) {
        img.onload = function() {
          return f(img);
        };
      }
      img.src = ctx.canvas.toDataURL("image/png");
      return img;
    },
    ctxToImageData: function(ctx) {
      return ctx.getImageData(0, 0, ctx.canvas.width, ctx.canvas.height);
    },
    drawCenteredImage: function(ctx, img, rad, x, y, dx, dy) {
      ctx.translate(x, y);
      ctx.rotate(rad);
      return ctx.drawImage(img, -dx / 2, -dy / 2);
    },
    copyCtx: function(ctx0) {
      var ctx;
      ctx = this.createCtx(ctx0.canvas.width, ctx0.canvas.height);
      ctx.drawImage(ctx0.canvas, 0, 0);
      return ctx;
    },
    resizeCtx: function(ctx, width, height, scale) {
      var copy;
      if (scale == null) {
        scale = false;
      }
      copy = this.copyCtx(ctx);
      ctx.canvas.width = width;
      ctx.canvas.height = height;
      return ctx.drawImage(copy.canvas, 0, 0);
    }
  };

  Evented = (function() {
    function Evented() {
      this.events = {};
    }

    Evented.prototype.emit = function() {
      var args, cb, len, m, name, ref, results;
      name = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (this.events[name]) {
        ref = this.events[name];
        results = [];
        for (m = 0, len = ref.length; m < len; m++) {
          cb = ref[m];
          results.push(cb.apply(null, args));
        }
        return results;
      }
    };

    Evented.prototype.on = function(name, cb) {
      var base1;
      return ((base1 = this.events)[name] != null ? base1[name] : base1[name] = []).push(cb);
    };

    Evented.prototype.off = function(name, cb) {
      var l;
      if (this.events[name]) {
        if (cb) {
          return this.events[name] = (function() {
            var len, m, ref, results;
            ref = this.events[name];
            results = [];
            for (m = 0, len = ref.length; m < len; m++) {
              l = ref[m];
              if (l !== cb) {
                results.push(l);
              }
            }
            return results;
          }).call(this);
        } else {
          return delete this.events[name];
        }
      }
    };

    return Evented;

  })();

  Color = {
    rgbaString: function(r, g, b, a) {
      var a4;
      if (a == null) {
        a = 255;
      }
      a = a / 255;
      a4 = a.toPrecision(4);
      if (a === 1) {
        return "rgb(" + r + "," + g + "," + b + ")";
      } else {
        return "rgba(" + r + "," + g + "," + b + "," + a4 + ")";
      }
    },
    hslString: function(h, s, l, a) {
      var a4;
      if (a == null) {
        a = 255;
      }
      a = a / 255;
      a4 = a.toPrecision(4);
      if (a === 1) {
        return "hsl(" + h + "," + s + "%," + l + "%)";
      } else {
        return "hsla(" + h + "," + s + "%," + l + "%," + a4 + ")";
      }
    },
    hexString: function(r, g, b, shortOK) {
      var b0, g0, r0;
      if (shortOK == null) {
        shortOK = true;
      }
      if (shortOK) {
        if (u.isInteger(r0 = r / 17) && u.isInteger(g0 = g / 17) && u.isInteger(b0 = b / 17)) {
          return this.hexShortString(r0, g0, b0);
        }
      }
      return "#" + (0x1000000 | (b | g << 8 | r << 16)).toString(16).slice(-6);
    },
    hexShortString: function(r, g, b) {
      if ((r > 15) || (g > 15) || (b > 15)) {
        u.error("hexShortString: one of " + [r, g, b] + " > 15");
      }
      return "#" + r.toString(16) + g.toString(16) + b.toString(16);
    },
    triString: function(r, g, b, a) {
      if (a == null) {
        a = 255;
      }
      if (a === 255) {
        return this.hexString(r, g, b, true);
      } else {
        return this.rgbaString(r, g, b, a);
      }
    },
    sharedCtx1x1: u.createCtx(1, 1),
    stringToUint8s: function(string) {
      this.sharedCtx1x1.fillStyle = string;
      this.sharedCtx1x1.fillRect(0, 0, 1, 1);
      return this.sharedCtx1x1.getImageData(0, 0, 1, 1).data;
    },
    sharedPixel: null,
    sharedUint8s: null,
    initSharedPixel: function() {
      this.sharedPixel = new Uint32Array(1);
      return this.sharedUint8s = new Uint8ClampedArray(this.sharedPixel.buffer);
    },
    rgbaToPixel: function(r, g, b, a) {
      if (a == null) {
        a = 255;
      }
      this.sharedUint8s.set([r, g, b, a]);
      return this.sharedPixel[0];
    },
    pixelToUint8s: function(pixel, sharedOK) {
      if (sharedOK == null) {
        sharedOK = false;
      }
      this.sharedPixel[0] = pixel;
      if (sharedOK) {
        return this.sharedUint8s;
      } else {
        return new Uint8ClampedArray(this.sharedUint8s);
      }
    },
    randomRgb: function() {
      var i, m, results;
      results = [];
      for (i = m = 0; m <= 2; i = ++m) {
        results.push(u.randomInt(256));
      }
      return results;
    },
    randomGrayRgb: function(min, max) {
      var i;
      if (min == null) {
        min = 0;
      }
      if (max == null) {
        max = 256;
      }
      i = u.randomInt2(min, max);
      return [i, i, i];
    },
    uint8sToRgba: function(uint8s) {
      return Array.apply(null, uint8s);
    },
    rgbIntensity: function(r, g, b) {
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    },
    hslToRgb: function(h, s, l) {
      var str;
      str = this.hslString(h, s, l);
      return this.stringToUint8s(str).subarray(0, 3);
    },
    rgbDistance: function(r1, g1, b1, r2, g2, b2) {
      var db, dg, dr, rMean, ref;
      rMean = Math.round((r1 + r2) / 2);
      ref = [r1 - r2, g1 - g2, b1 - b2], dr = ref[0], dg = ref[1], db = ref[2];
      return Math.sqrt((((512 + rMean) * dr * dr) >> 8) + (4 * dg * dg) + (((767 - rMean) * db * db) >> 8));
    },
    rgbLerp: function(rgb1, value, min, max, rgb0) {
      var i, m, results, scale;
      if (min == null) {
        min = 0;
      }
      if (max == null) {
        max = 1;
      }
      if (rgb0 == null) {
        rgb0 = [0, 0, 0];
      }
      scale = u.lerpScale(value, min, max);
      results = [];
      for (i = m = 0; m <= 2; i = ++m) {
        results.push(Math.round(u.lerp(rgb0[i], rgb1[i], scale)));
      }
      return results;
    },
    typedColor: (function() {
      var TypedColorProto, typedColor;
      typedColor = function(r, g, b, a) {
        var ua;
        if (a == null) {
          a = 255;
        }
        ua = r.buffer ? r : new Uint8ClampedArray([r, g, b, a]);
        ua.pixelArray = new Uint32Array(ua.buffer, ua.byteOffset, 1);
        ua.__proto__ = TypedColorProto;
        return ua;
      };
      TypedColorProto = {
        __proto__: Uint8ClampedArray.prototype,
        setColor: function(r, g, b, a) {
          if (a == null) {
            a = 255;
          }
          this.checkColorChange();
          this[0] = r;
          this[1] = g;
          this[2] = b;
          this[3] = a;
          return this;
        },
        setPixel: function(pixel) {
          this.checkColorChange();
          return this.pixelArray[0] = pixel;
        },
        getPixel: function() {
          return this.pixelArray[0];
        },
        setString: function(string) {
          return this.setColor.apply(this, Color.stringToUint8s(string));
        },
        getString: function() {
          if (this.string == null) {
            this.string = Color.triString.apply(Color, this);
          }
          return this.string;
        },
        checkColorChange: function() {
          if (this.map) {
            u.error("ColorMap.typedColor: cannot modify ColorMap color.");
          }
          if (this.string) {
            return this.string = null;
          }
        },
        clone: function() {
          return typeColor.apply(null, this);
        }
      };
      Object.defineProperties(TypedColorProto, {
        pixel: {
          get: function() {
            return this.pixelArray[0];
          },
          set: function(val) {
            return this.setPixel(val);
          },
          enumerable: true
        },
        rgba: {
          get: function() {
            return this;
          },
          set: function(val) {
            return this.setColor.apply(this, val);
          },
          enumerable: true
        },
        css: {
          get: function() {
            return this.getString();
          },
          set: function(val) {
            return this.setString(val);
          },
          enumerable: true
        },
        str: {
          get: function() {
            return this.getString();
          },
          enumerable: true
        }
      });
      return typedColor;
    })(),
    colorType: function(color) {
      if (color.pixelArray) {
        return "typed";
      }
      if (u.isString(color)) {
        return "css";
      }
      if (u.isInteger(color)) {
        return "pixel";
      }
      return null;
    },
    arrayToColor: function(array, type) {
      if (type == null) {
        type = "typed";
      }
      switch (type) {
        case "css":
          return this.triString.apply(this, array);
        case "pixel":
          return this.rgbaToPixel.apply(this, array);
        case "typed":
          if (array.buffer) {
            return this.typedColor(array);
          } else {
            return this.typedColor.apply(this, array);
          }
      }
      return u.error("arrayToColor: incorrect type: " + type);
    },
    colorToArray: function(color) {
      switch (this.colorType(color)) {
        case "css":
          return this.stringToUint8s(color);
        case "pixel":
          return this.pixelToUint8s(color);
        case "typed":
          return color;
      }
      if (u.isArray(color) || color.buffer) {
        return color;
      }
      return u.error("colorToArray: bad color: " + color);
    },
    convertColor: function(color, type) {
      var type0;
      type0 = this.colorType(color);
      if (type0 === type && type !== "css") {
        return color;
      }
      if (type0 === "typed") {
        return color[type];
      }
      return this.arrayToColor(this.colorToArray(color), type);
    },
    rgbaToColor: function(r, g, b, a, type) {
      if (a == null) {
        a = 255;
      }
      if (type == null) {
        type = "typed";
      }
      switch (type) {
        case "css":
          return this.triString(r, g, b, a);
        case "pixel":
          return this.rgbaToPixel(r, g, b, a);
        case "typed":
          return this.typedColor(r, g, b, a);
      }
      return u.error("rgbaToColor: incorrect type: " + type);
    },
    colorsEqual: function(color1, color2) {
      return this.convertColor(color1, "pixel") === this.convertColor(color2, "pixel");
    }
  };

  Color.initSharedPixel();

  ColorMaps = {
    gradientImageData: function(nColors, stops, locs) {
      var c, ctx, grad, i, m, ref;
      stops = (function() {
        var len, m, results;
        results = [];
        for (m = 0, len = stops.length; m < len; m++) {
          c = stops[m];
          results.push(Color.convertColor(c, "css"));
        }
        return results;
      })();
      if (locs == null) {
        locs = u.aRamp(0, 1, stops.length);
      }
      ctx = u.createCtx(nColors, 1);
      grad = ctx.createLinearGradient(0, 0, nColors, 0);
      for (i = m = 0, ref = stops.length; 0 <= ref ? m < ref : m > ref; i = 0 <= ref ? ++m : --m) {
        grad.addColorStop(locs[i], stops[i]);
      }
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, nColors, 1);
      return u.ctxToImageData(ctx).data;
    },
    uint8ArrayToUint8s: function(a) {
      var i, m, ref, results;
      results = [];
      for (i = m = 0, ref = a.length; m < ref; i = m += 4) {
        results.push(a.subarray(i, i + 4));
      }
      return results;
    },
    uint8ArrayToRgbas: function(a) {
      var i, m, ref, results;
      results = [];
      for (i = m = 0, ref = a.length; m < ref; i = m += 4) {
        results.push([a[i], a[i + 1], a[i + 2], a[i + 3]]);
      }
      return results;
    },
    uint8ArrayToColors: function(array, type) {
      if (type === "pixel") {
        return new Uint32Array(array.buffer);
      }
      return this.arrayToColors(this.uint8ArrayToUint8s(array), type);
    },
    arrayToColors: function(array, type) {
      var a, i, len, m;
      if (Color.colorType(array[0]) === type) {
        return array;
      }
      for (i = m = 0, len = array.length; m < len; i = ++m) {
        a = array[i];
        array[i] = Color.convertColor(a, type);
      }
      return array;
    },
    permuteColors: function(A1, A2, A3, max) {
      var A, i, ref;
      if (A2 == null) {
        A2 = A1;
      }
      if (A3 == null) {
        A3 = A2;
      }
      if (max == null) {
        max = [255, 255, 255];
      }
      ref = (function() {
        var len, m, ref, results;
        ref = [A1, A2, A3];
        results = [];
        for (i = m = 0, len = ref.length; m < len; i = ++m) {
          A = ref[i];
          if (typeof A === "number") {
            if (A === 1) {
              results.push([max[i]]);
            } else {
              results.push(u.aIntRamp(0, max[i], A));
            }
          } else {
            results.push(A);
          }
        }
        return results;
      })(), A1 = ref[0], A2 = ref[1], A3 = ref[2];
      return this.permuteArrays(A1, A2, A3);
    },
    permuteArrays: function(A1, A2, A3) {
      var a1, a2, a3, aa, ab, array, len, len1, len2, m;
      if (A2 == null) {
        A2 = A1;
      }
      if (A3 == null) {
        A3 = A2;
      }
      array = [];
      for (m = 0, len = A3.length; m < len; m++) {
        a3 = A3[m];
        for (aa = 0, len1 = A2.length; aa < len1; aa++) {
          a2 = A2[aa];
          for (ab = 0, len2 = A1.length; ab < len2; ab++) {
            a1 = A1[ab];
            array.push([a1, a2, a3]);
          }
        }
      }
      return array;
    },
    colorMap: function(array, indexToo) {
      if (indexToo == null) {
        indexToo = false;
      }
      array.__proto__ = this.ColorMapProto;
      return array.init(indexToo);
    },
    ColorMapProto: {
      __proto__: Array.prototype,
      init: function(indexToo) {
        var aa, color, i, len, len1, m;
        if (indexToo == null) {
          indexToo = false;
        }
        this.type = Color.colorType(this[0]);
        if (indexToo) {
          this.index = {};
        }
        if (this.type == null) {
          u.error("ColorMap type error");
        }
        if (this.type === "typed") {
          for (i = m = 0, len = this.length; m < len; i = ++m) {
            color = this[i];
            color.ix = i;
            color.map = this;
          }
        }
        if (this.index) {
          for (i = aa = 0, len1 = this.length; aa < len1; i = ++aa) {
            color = this[i];
            this.index[this.indexKey(color)] = i;
          }
        }
        return this;
      },
      indexKey: function(color) {
        if (this.type === "typed") {
          return color.pixel;
        } else {
          return color;
        }
      },
      colorsEqual: function(color1, color2) {
        return this.indexKey(color1) === this.indexKey(color2);
      },
      randomIndex: function(start, stop) {
        if (start == null) {
          start = 0;
        }
        if (stop == null) {
          stop = this.length;
        }
        return u.randomInt2(start, stop);
      },
      randomColor: function(start, stop) {
        if (start == null) {
          start = 0;
        }
        if (stop == null) {
          stop = this.length;
        }
        return this[this.randomIndex(start, stop)];
      },
      sort: function(compareFcn) {
        var aa, color, i, len, len1, m;
        Array.prototype.sort.call(this, compareFcn);
        if (this.index) {
          for (i = m = 0, len = this.length; m < len; i = ++m) {
            color = this[i];
            this.index[this.indexKey(color)] = i;
          }
        }
        if (this.type === "typed") {
          for (i = aa = 0, len1 = this.length; aa < len1; i = ++aa) {
            color = this[i];
            color.ix = i;
          }
        }
        return this;
      },
      lookup: function(color) {
        var c, i, len, m;
        color = Color.convertColor(color, this.type);
        if (this.index) {
          return this.index[this.indexKey(color)];
        }
        for (i = m = 0, len = this.length; m < len; i = ++m) {
          c = this[i];
          if (this.colorsEqual(color, c)) {
            return i;
          }
        }
        return void 0;
      },
      scaleColor: function(number, min, max) {
        var scale;
        if (number < min) {
          number = min;
        }
        if (number > max) {
          number = max;
        }
        scale = (this.length - 1) * ((number - min) / (max - min));
        return this[Math.round(scale)];
      },
      findClosestIndex: function(r, g, b, a) {
        var b0, bLoc, c, color, d, g0, gLoc, i, ix, ixMin, len, m, minDist, r0, rLoc, ref, ref1, ref2, step;
        if (a == null) {
          a = 255;
        }
        if (g == null) {
          ref = Color.colorToArray(r), r = ref[0], g = ref[1], b = ref[2], a = ref[3];
        }
        if (this.cube) {
          step = 255 / (this.cube - 1);
          ref1 = (function() {
            var len, m, ref1, results;
            ref1 = [r, g, b];
            results = [];
            for (m = 0, len = ref1.length; m < len; m++) {
              c = ref1[m];
              results.push(Math.round(c / step));
            }
            return results;
          })(), rLoc = ref1[0], gLoc = ref1[1], bLoc = ref1[2];
          return rLoc + gLoc * this.cube + bLoc * this.cube * this.cube;
        }
        if (ix = this.lookup([r, g, b, a])) {
          return ix;
        }
        minDist = Infinity;
        ixMin = 0;
        for (i = m = 0, len = this.length; m < len; i = ++m) {
          color = this[i];
          ref2 = Color.colorToArray(color), r0 = ref2[0], g0 = ref2[1], b0 = ref2[2];
          d = Color.rgbDistance(r0, g0, b0, r, g, b);
          if (d < minDist) {
            minDist = d;
            ixMin = i;
          }
        }
        return ixMin;
      },
      findClosestColor: function(r, g, b, a) {
        if (a == null) {
          a = 255;
        }
        return this[this.findClosestIndex(r, g, b, a)];
      }
    },
    basicColorMap: function(array, type, indexToo) {
      if (type == null) {
        type = "typed";
      }
      if (indexToo == null) {
        indexToo = false;
      }
      array = this.arrayToColors(array, type);
      return this.colorMap(array, indexToo);
    },
    grayColorMap: function(size, type, indexToo) {
      var array, i;
      if (size == null) {
        size = 256;
      }
      if (type == null) {
        type = "typed";
      }
      if (indexToo == null) {
        indexToo = false;
      }
      array = (function() {
        var len, m, ref, results;
        ref = u.aIntRamp(0, 255, size);
        results = [];
        for (m = 0, len = ref.length; m < len; m++) {
          i = ref[m];
          results.push([i, i, i]);
        }
        return results;
      })();
      return this.basicColorMap(array, type, indexToo);
    },
    rgbColorMap: function(R, G, B, type, indexToo) {
      var array;
      if (G == null) {
        G = R;
      }
      if (B == null) {
        B = R;
      }
      if (type == null) {
        type = "typed";
      }
      if (indexToo == null) {
        indexToo = true;
      }
      array = this.permuteColors(R, G, B);
      if ((typeof R === "number") && ((R === G && G === B))) {
        array.cube = R;
      }
      return this.colorMap(this.arrayToColors(array, type), indexToo);
    },
    rgbColorCube: function(cubeSide, type, indexToo) {
      if (type == null) {
        type = "typed";
      }
      if (indexToo == null) {
        indexToo = false;
      }
      return this.rgbColorMap(cubeSide, cubeSide, cubeSide, type, indexToo);
    },
    hslColorMap: function(H, S, L, type, indexToo) {
      var a, array, hslArray;
      if (S == null) {
        S = 1;
      }
      if (L == null) {
        L = 1;
      }
      if (type == null) {
        type = "typed";
      }
      if (indexToo == null) {
        indexToo = false;
      }
      hslArray = this.permuteColors(H, S, L, [359, 100, 50]);
      array = (function() {
        var len, m, results;
        results = [];
        for (m = 0, len = hslArray.length; m < len; m++) {
          a = hslArray[m];
          results.push(Color.hslString.apply(Color, a));
        }
        return results;
      })();
      return this.colorMap(this.arrayToColors(array, type), indexToo);
    },
    gradientColorMap: function(nColors, stops, locs, type, indexToo) {
      var id;
      if (type == null) {
        type = "typed";
      }
      if (indexToo == null) {
        indexToo = false;
      }
      id = this.gradientImageData(nColors, stops, locs);
      return this.colorMap(this.uint8ArrayToColors(id, type), indexToo);
    },
    jetColors: [[0, 0, 127], [0, 0, 255], [0, 127, 255], [0, 255, 255], [127, 255, 127], [255, 255, 0], [255, 127, 0], [255, 0, 0], [127, 0, 0]],
    rampColorMap: function(color, width, whiteToo) {
      var stops;
      if (whiteToo == null) {
        whiteToo = false;
      }
      stops = whiteToo ? ["black", color, "white"] : ["black", color];
      return this.gradientColorMap(width, stops);
    },
    netLogoColorMap: function(width, whiteToo) {
      if (width == null) {
        width = 10;
      }
      if (whiteToo == null) {
        whiteToo = true;
      }
      return this.namedColorMap(this.netLogoColors, width, whiteToo);
    },
    cssBasicColorMap: function(width, whiteToo) {
      if (width == null) {
        width = 18;
      }
      if (whiteToo == null) {
        whiteToo = false;
      }
      return this.namedColorMap(this.basicCssColors, width, whiteToo);
    },
    namedColorMap: function(names, width, whiteToo) {
      var color, k, len, m, map, n, name, o, ramps, v;
      map = [];
      ramps = {};
      if (u.isArray(names)) {
        o = {};
        for (m = 0, len = names.length; m < len; m++) {
          n = names[m];
          o[n] = n;
        }
        names = o;
      }
      for (name in names) {
        color = names[name];
        ramps[name] = this.rampColorMap(color, width, whiteToo);
        map = map.concat(ramps[name]);
      }
      map = this.basicColorMap(map);
      for (k in ramps) {
        v = ramps[k];
        map[k] = v;
      }
      for (k in ramps) {
        v = ramps[k];
        map[Color.convertColor(k, "css")] = v;
      }
      return map;
    },
    basicCssColors: ["gray", "red", "orange", "brown", "yellow", "green", "lime", "turquoise", "cyan", "skyblue", "blue", "violet", "magenta", "pink"],
    netLogoColors: {
      gray: [141, 141, 141],
      red: [215, 50, 41],
      orange: [241, 106, 21],
      brown: [157, 110, 72],
      yellow: [237, 237, 49],
      green: [89, 176, 60],
      lime: [44, 209, 59],
      turquoise: [29, 159, 120],
      cyan: [84, 196, 196],
      skyblue: [45, 141, 190],
      blue: [52, 93, 169],
      violet: [124, 80, 164],
      magenta: [167, 27, 106],
      pink: [224, 127, 150]
    },
    opacityColorMap: function(rgb, nOpacities, type, indexToo) {
      var a, array, b, g, r;
      if (nOpacities == null) {
        nOpacities = 256;
      }
      if (type == null) {
        type = "typed";
      }
      if (indexToo == null) {
        indexToo = false;
      }
      r = rgb[0], g = rgb[1], b = rgb[2];
      array = (function() {
        var len, m, ref, results;
        ref = u.aIntRamp(0, 255, nOpacities);
        results = [];
        for (m = 0, len = ref.length; m < len; m++) {
          a = ref[m];
          results.push([r, g, b, a]);
        }
        return results;
      })();
      return this.colorMap(this.arrayToColors(array, type), indexToo);
    },
    createSharedMaps: function() {
      this.Gray = this.grayColorMap();
      this.Rgb256 = this.rgbColorMap(8, 8, 4);
      this.Rgb = this.rgbColorCube(16);
      this.Safe = this.rgbColorCube(6);
      this.Jet = this.gradientColorMap(256, this.jetColors);
      this.NetLogo = this.netLogoColorMap(10);
      this.NetLogoRamps = this.netLogoColorMap(18, false);
      return this.CssRamps = this.cssBasicColorMap(18, false);
    },
    randomGray: function(min, max) {
      return this.Gray.randomColor(min, max);
    },
    randomColor: function() {
      return this.Rgb256.randomColor();
    },
    scaleColor: function(color, number, min, max) {
      var ramp;
      if (min == null) {
        min = 0;
      }
      if (max == null) {
        max = 1;
      }
      if (color.scaleColor != null) {
        return color.scaleColor(number, min, max);
      } else if (ramp = this.CssRamps[Color.convertColor(color, "css")]) {
        return ramp.scaleColor(number, min, max);
      } else {
        return this.Rgb.findClosestColor(Color.rgbLerp(color, number, min, max));
      }
    }
  };

  ColorMaps.createSharedMaps();

  colorMixin = function(obj, colorName, colorDefault, colorType) {
    var colorPropName, colorTitle, getterName, proto, ref, setterName;
    if (colorType == null) {
      colorType = "typed";
    }
    proto = (ref = obj.prototype) != null ? ref : obj;
    colorTitle = u.titleCase(colorName);
    colorPropName = colorName + "Prop";
    getterName = "get" + colorTitle;
    setterName = "set" + colorTitle;
    proto[colorPropName] = colorDefault ? Color.convertColor(colorDefault, colorType) : null;
    if (proto[setterName] == null) {
      proto[setterName] = function(r, g, b, a) {
        var color;
        if (a == null) {
          a = 255;
        }
        if (g === void 0) {
          color = Color.convertColor(r, colorType);
        } else if (this.hasOwnProperty(colorPropName) && colorType === "typed" && ((color = this[colorPropName]).map == null)) {
          color.setColor(r, g, b, a);
        } else {
          console.log("new color");
          color = Color.rgbaToColor(r, g, b, a, colorType);
        }
        return this[colorPropName] = color;
      };
    }
    if (proto[getterName] == null) {
      proto[getterName] = function() {
        return this[colorPropName];
      };
    }
    Object.defineProperty(proto, colorName, {
      get: function() {
        return this[getterName]();
      },
      set: function(val) {
        return this[setterName](val);
      }
    });
    return proto;
  };

  Shapes = (function() {
    var ccirc, cimg, circ, csq, fillSlot, poly, spriteSheets;
    poly = function(c, a) {
      var i, len, m, p;
      for (i = m = 0, len = a.length; m < len; i = ++m) {
        p = a[i];
        if (i === 0) {
          c.moveTo(p[0], p[1]);
        } else {
          c.lineTo(p[0], p[1]);
        }
      }
      return null;
    };
    circ = function(c, x, y, s) {
      return c.arc(x, y, s / 2, 0, 2 * Math.PI);
    };
    ccirc = function(c, x, y, s) {
      return c.arc(x, y, s / 2, 0, 2 * Math.PI, true);
    };
    cimg = function(c, x, y, s, img) {
      c.scale(1, -1);
      c.drawImage(img, x - s / 2, y - s / 2, s, s);
      return c.scale(1, -1);
    };
    csq = function(c, x, y, s) {
      return c.fillRect(x - s / 2, y - s / 2, s, s);
    };
    fillSlot = function(slot, img) {
      slot.ctx.save();
      slot.ctx.scale(1, -1);
      slot.ctx.drawImage(img, slot.x, -(slot.y + slot.spriteSize), slot.spriteSize, slot.spriteSize);
      return slot.ctx.restore();
    };
    spriteSheets = [];
    return {
      "default": {
        rotate: true,
        draw: function(c) {
          return poly(c, [[.5, 0], [-.5, -.5], [-.25, 0], [-.5, .5]]);
        }
      },
      triangle: {
        rotate: true,
        draw: function(c) {
          return poly(c, [[.5, 0], [-.5, -.4], [-.5, .4]]);
        }
      },
      arrow: {
        rotate: true,
        draw: function(c) {
          return poly(c, [[.5, 0], [0, .5], [0, .2], [-.5, .2], [-.5, -.2], [0, -.2], [0, -.5]]);
        }
      },
      bug: {
        rotate: true,
        draw: function(c) {
          if (c.strokeStyle === "#000000") {
            c.strokeStyle = c.fillStyle;
          }
          c.lineWidth = .05;
          poly(c, [[.4, .225], [.2, 0], [.4, -.225]]);
          c.stroke();
          c.beginPath();
          circ(c, .12, 0, .26);
          circ(c, -.05, 0, .26);
          return circ(c, -.27, 0, .4);
        }
      },
      pyramid: {
        rotate: false,
        draw: function(c) {
          return poly(c, [[0, .5], [-.433, -.25], [.433, -.25]]);
        }
      },
      circle: {
        shortcut: function(c, x, y, s) {
          c.beginPath();
          circ(c, x, y, s);
          c.closePath();
          return c.fill();
        },
        rotate: false,
        draw: function(c) {
          return circ(c, 0, 0, 1);
        }
      },
      square: {
        shortcut: function(c, x, y, s) {
          return csq(c, x, y, s);
        },
        rotate: false,
        draw: function(c) {
          return csq(c, 0, 0, 1);
        }
      },
      pentagon: {
        rotate: false,
        draw: function(c) {
          return poly(c, [[0, .45], [-.45, .1], [-.3, -.45], [.3, -.45], [.45, .1]]);
        }
      },
      ring: {
        rotate: false,
        draw: function(c) {
          circ(c, 0, 0, 1);
          c.closePath();
          return ccirc(c, 0, 0, .6);
        }
      },
      filledRing: {
        rotate: false,
        draw: function(c) {
          var tempStyle;
          circ(c, 0, 0, 1);
          tempStyle = c.fillStyle;
          c.fillStyle = c.strokeStyle;
          c.fill();
          c.fillStyle = tempStyle;
          c.beginPath();
          return circ(c, 0, 0, .8);
        }
      },
      person: {
        rotate: false,
        draw: function(c) {
          poly(c, [[.15, .2], [.3, 0], [.125, -.1], [.125, .05], [.1, -.15], [.25, -.5], [.05, -.5], [0, -.25], [-.05, -.5], [-.25, -.5], [-.1, -.15], [-.125, .05], [-.125, -.1], [-.3, 0], [-.15, .2]]);
          c.closePath();
          return circ(c, 0, .35, .30);
        }
      },
      names: function() {
        var name, results, val;
        results = [];
        for (name in this) {
          if (!hasProp.call(this, name)) continue;
          val = this[name];
          if ((val.rotate != null) && (val.draw != null)) {
            results.push(name);
          }
        }
        return results;
      },
      add: function(name, rotate, draw, shortcut) {
        var s;
        s = this[name] = u.isFunction(draw) ? {
          rotate: rotate,
          draw: draw
        } : {
          rotate: rotate,
          img: draw,
          draw: function(c) {
            return cimg(c, .5, .5, 1, this.img);
          }
        };
        if ((s.img != null) && !s.rotate) {
          s.shortcut = function(c, x, y, s) {
            return cimg(c, x, y, s, this.img);
          };
        }
        if (shortcut != null) {
          return s.shortcut = shortcut;
        }
      },
      poly: poly,
      circ: circ,
      ccirc: ccirc,
      cimg: cimg,
      csq: csq,
      spriteSheets: spriteSheets,
      draw: function(ctx, shape, x, y, size, rad, color, strokeColor) {
        if (shape.shortcut != null) {
          if (shape.img == null) {
            ctx.fillStyle = color.css;
          }
          shape.shortcut(ctx, x, y, size);
        } else {
          ctx.save();
          ctx.translate(x, y);
          if (size !== 1) {
            ctx.scale(size, size);
          }
          if (rad !== 0) {
            ctx.rotate(rad);
          }
          if (shape.img != null) {
            shape.draw(ctx);
          } else {
            ctx.fillStyle = color.css;
            if (strokeColor) {
              ctx.strokeStyle = strokeColor.css;
            }
            ctx.beginPath();
            shape.draw(ctx);
            ctx.closePath();
            ctx.fill();
          }
          ctx.restore();
        }
        return shape;
      },
      drawSprite: function(ctx, s, x, y, size, rad) {
        if (rad === 0) {
          ctx.drawImage(s.ctx.canvas, s.x, s.y, s.spriteSize, s.spriteSize, x - size / 2, y - size / 2, size, size);
        } else {
          ctx.save();
          ctx.translate(x, y);
          ctx.rotate(rad);
          ctx.drawImage(s.ctx.canvas, s.x, s.y, s.spriteSize, s.spriteSize, -size / 2, -size / 2, size, size);
          ctx.restore();
        }
        return s;
      },
      shapeToSprite: function(name, color, size, strokeColor) {
        var ctx, foundSlot, img, index, shape, slot, spriteSize, x, y;
        color = Color.convertColor(color, "css");
        if (strokeColor != null) {
          strokeColor = Color.convertColor(strokeColor, "css");
        }
        spriteSize = Math.ceil(size);
        shape = this[name];
        index = shape.img != null ? name : name + "-" + color;
        ctx = spriteSheets[spriteSize];
        if (ctx == null) {
          spriteSheets[spriteSize] = ctx = u.createCtx(spriteSize * 10, spriteSize);
          ctx.nextX = 0;
          ctx.nextY = 0;
          ctx.index = {};
        }
        if ((foundSlot = ctx.index[index]) != null) {
          return foundSlot;
        }
        if (spriteSize * ctx.nextX === ctx.canvas.width) {
          u.resizeCtx(ctx, ctx.canvas.width, ctx.canvas.height + spriteSize);
          ctx.nextX = 0;
          ctx.nextY++;
        }
        x = spriteSize * ctx.nextX;
        y = spriteSize * ctx.nextY;
        slot = {
          ctx: ctx,
          x: x,
          y: y,
          spriteSize: spriteSize,
          name: name,
          color: color,
          strokeColor: strokeColor,
          index: index
        };
        ctx.index[index] = slot;
        if ((img = shape.img) != null) {
          if (img.height !== 0) {
            fillSlot(slot, img);
          } else {
            img.onload = function() {
              return fillSlot(slot, img);
            };
          }
        } else {
          ctx.save();
          ctx.scale(spriteSize, spriteSize);
          ctx.translate(ctx.nextX + .5, ctx.nextY + .5);
          ctx.fillStyle = color;
          if (strokeColor) {
            ctx.strokeStyle = strokeColor;
          }
          ctx.beginPath();
          shape.draw(ctx);
          ctx.closePath();
          ctx.fill();
          ctx.restore();
        }
        ctx.nextX++;
        return slot;
      }
    };
  })();

  AgentSet = (function(superClass) {
    extend(AgentSet, superClass);

    AgentSet.asSet = function(a, setType) {
      var ref;
      if (setType == null) {
        setType = AgentSet;
      }
      a.__proto__ = (ref = setType.prototype) != null ? ref : setType.constructor.prototype;
      if (a[0] != null) {
        a.model = a[0].model;
      }
      return a;
    };

    function AgentSet(model, agentClass, name1, mainSet) {
      this.model = model;
      this.agentClass = agentClass;
      this.name = name1;
      this.mainSet = mainSet;
      AgentSet.__super__.constructor.call(this, 0);
      u.mixin(this, new Evented());
      if (this.mainSet == null) {
        this.breeds = [];
      }
      this.agentClass.prototype.breed = this;
      this.agentClass.prototype.model = this.model;
      this.ownVariables = [];
      if (this.mainSet == null) {
        this.ID = 0;
      }
    }

    AgentSet.prototype.create = function() {};

    AgentSet.prototype.add = function(o) {
      if (this.mainSet != null) {
        this.mainSet.add(o);
      } else {
        o.id = this.ID++;
      }
      this.push(o);
      return o;
    };

    AgentSet.prototype.remove = function(o) {
      if (this.mainSet != null) {
        u.removeItem(this.mainSet, o);
      }
      u.removeItem(this, o);
      return this;
    };

    AgentSet.prototype.setDefault = function(name, value) {
      return this.agentClass.prototype[name] = value;
    };

    AgentSet.prototype.getDefault = function(name) {
      return this.agentClass.prototype[name];
    };

    AgentSet.prototype.own = function(vars) {
      var len, m, name, ref;
      ref = vars.split(" ");
      for (m = 0, len = ref.length; m < len; m++) {
        name = ref[m];
        this.setDefault(name, null);
        this.ownVariables.push(name);
      }
      return this;
    };

    AgentSet.prototype.setBreed = function(a) {
      var k, proto, v;
      if (a.breed.mainSet != null) {
        u.removeItem(a.breed, a, "id");
      }
      if (this.mainSet != null) {
        u.insertItem(this, a, "id");
      }
      proto = a.__proto__ = this.agentClass.prototype;
      for (k in a) {
        if (!hasProp.call(a, k)) continue;
        v = a[k];
        if (proto[k] != null) {
          delete a[k];
        }
      }
      return a;
    };

    AgentSet.prototype.exclude = function(breeds) {
      var o;
      breeds = breeds.split(" ");
      return this.asSet((function() {
        var len, m, ref, results;
        results = [];
        for (m = 0, len = this.length; m < len; m++) {
          o = this[m];
          if (ref = o.breed.name, indexOf.call(breeds, ref) < 0) {
            results.push(o);
          }
        }
        return results;
      }).call(this));
    };

    AgentSet.prototype.uniq = function() {
      return u.uniq(this);
    };

    AgentSet.prototype.asSet = function(a, setType) {
      if (setType == null) {
        setType = AgentSet;
      }
      return AgentSet.asSet(a, setType);
    };

    AgentSet.prototype.isSet = function(name) {
      if (name == null) {
        name = "AgentSet";
      }
      return this.constructor.name === name;
    };

    AgentSet.prototype.isBreed = function(name) {
      if (this.agentClass != null) {
        return this.agentClass.name === name;
      } else {
        return this.isSet(name);
      }
    };

    AgentSet.prototype.asOrderedSet = function(a) {
      return this.asSet(a).sortById();
    };

    AgentSet.prototype.toString = function() {
      var a;
      return "[" + ((function() {
        var len, m, results;
        results = [];
        for (m = 0, len = this.length; m < len; m++) {
          a = this[m];
          results.push(a.toString());
        }
        return results;
      }).call(this)).join(", ") + "]";
    };

    AgentSet.prototype.getProp = function(prop) {
      return u.aProp(this, prop);
    };

    AgentSet.prototype.getPropWith = function(prop, value) {
      var o;
      return this.asSet((function() {
        var len, m, results;
        results = [];
        for (m = 0, len = this.length; m < len; m++) {
          o = this[m];
          if (o[prop] === value) {
            results.push(o);
          }
        }
        return results;
      }).call(this));
    };

    AgentSet.prototype.setProp = function(prop, value) {
      var aa, i, len, len1, m, o;
      if (u.isArray(value)) {
        for (i = m = 0, len = this.length; m < len; i = ++m) {
          o = this[i];
          o[prop] = value[i];
        }
        return this;
      } else {
        for (aa = 0, len1 = this.length; aa < len1; aa++) {
          o = this[aa];
          o[prop] = value;
        }
        return this;
      }
    };

    AgentSet.prototype.maxProp = function(prop) {
      return u.aMax(this.getProp(prop));
    };

    AgentSet.prototype.minProp = function(prop) {
      return u.aMin(this.getProp(prop));
    };

    AgentSet.prototype.histOfProp = function(prop, bin) {
      if (bin == null) {
        bin = 1;
      }
      return u.histOf(this, bin, prop);
    };

    AgentSet.prototype.shuffle = function() {
      return u.shuffle(this);
    };

    AgentSet.prototype.sortById = function() {
      return u.sortBy(this, "id");
    };

    AgentSet.prototype.clone = function() {
      return this.asSet(u.clone(this));
    };

    AgentSet.prototype.last = function() {
      return u.last(this);
    };

    AgentSet.prototype.any = function() {
      return u.any(this);
    };

    AgentSet.prototype.other = function(a) {
      var o;
      if (this.isSet()) {
        return u.removeItem(this, a);
      } else {
        return this.asSet((function() {
          var len, m, results;
          results = [];
          for (m = 0, len = this.length; m < len; m++) {
            o = this[m];
            if (o !== a) {
              results.push(o);
            }
          }
          return results;
        }).call(this));
      }
    };

    AgentSet.prototype.oneOf = function() {
      return u.oneOf(this);
    };

    AgentSet.prototype.nOf = function(n) {
      return this.asSet(u.nOf(this, n));
    };

    AgentSet.prototype.minOneOf = function(f, valueToo) {
      if (valueToo == null) {
        valueToo = false;
      }
      return u.minOneOf(this, f, valueToo);
    };

    AgentSet.prototype.maxOneOf = function(f, valueToo) {
      if (valueToo == null) {
        valueToo = false;
      }
      return u.maxOneOf(this, f, valueToo);
    };

    AgentSet.prototype.draw = function(ctx) {
      var len, m, o;
      u.clearCtx(ctx);
      for (m = 0, len = this.length; m < len; m++) {
        o = this[m];
        if (!o.hidden) {
          o.draw(ctx);
        }
      }
      return null;
    };

    AgentSet.prototype.show = function() {
      var len, m, o, results;
      results = [];
      for (m = 0, len = this.length; m < len; m++) {
        o = this[m];
        results.push(o.hidden = false);
      }
      return results;
    };

    AgentSet.prototype.hide = function() {
      var len, m, o, results;
      results = [];
      for (m = 0, len = this.length; m < len; m++) {
        o = this[m];
        results.push(o.hidden = true);
      }
      return results;
    };

    AgentSet.prototype.inRect = function(o, radius) {
      var a, checkTorus, len, m, maxX, maxY, minX, minY, outside, patches, rect, x, y;
      rect = [];
      minX = o.x - radius;
      maxX = o.x + radius;
      minY = o.y - radius;
      maxY = o.y + radius;
      patches = this.model.patches;
      outside = (minX < patches.minX) || (maxX > patches.maxX) || (minY < patches.minY) || (maxY > patches.maxY);
      checkTorus = patches.isTorus && outside;
      for (m = 0, len = this.length; m < len; m++) {
        a = this[m];
        x = a.x;
        y = a.y;
        if (checkTorus) {
          if (x < minX) {
            x += patches.numX;
          } else if (x > maxX) {
            x -= patches.numX;
          }
          if (y < minY) {
            y += patches.numY;
          } else if (y > maxY) {
            y -= patches.numY;
          }
        }
        if ((minX <= x && x <= maxX) && (minY <= y && y <= maxY)) {
          rect.push(a);
        }
      }
      return this.asSet(rect);
    };

    AgentSet.prototype.inRadius = function(o, radius) {
      var a, d2, h, w, x, y;
      d2 = radius * radius;
      x = o.x;
      y = o.y;
      if (this.model.patches.isTorus) {
        w = this.model.patches.numX;
        h = this.model.patches.numY;
        return this.asSet((function() {
          var len, m, results;
          results = [];
          for (m = 0, len = this.length; m < len; m++) {
            a = this[m];
            if (u.torusSqDistance(x, y, a.x, a.y, w, h) <= d2) {
              results.push(a);
            }
          }
          return results;
        }).call(this));
      } else {
        return this.asSet((function() {
          var len, m, results;
          results = [];
          for (m = 0, len = this.length; m < len; m++) {
            a = this[m];
            if (u.sqDistance(x, y, a.x, a.y) <= d2) {
              results.push(a);
            }
          }
          return results;
        }).call(this));
      }
    };

    AgentSet.prototype.inCone = function(o, radius, angle, heading) {
      var a, h, w, x, y;
      x = o.x;
      y = o.y;
      if (this.model.patches.isTorus) {
        w = this.model.patches.numX;
        h = this.model.patches.numY;
        return this.asSet((function() {
          var len, m, results;
          results = [];
          for (m = 0, len = this.length; m < len; m++) {
            a = this[m];
            if (u.inTorusCone(radius, angle, heading, x, y, a.x, a.y, w, h)) {
              results.push(a);
            }
          }
          return results;
        }).call(this));
      } else {
        return this.asSet((function() {
          var len, m, results;
          results = [];
          for (m = 0, len = this.length; m < len; m++) {
            a = this[m];
            if (u.inCone(radius, angle, heading, x, y, a.x, a.y)) {
              results.push(a);
            }
          }
          return results;
        }).call(this));
      }
    };

    AgentSet.prototype.ask = function(f) {
      var len, m, o;
      if (u.isString(f)) {
        eval("f=function(o){return " + f + ";}");
      }
      for (m = 0, len = this.length; m < len; m++) {
        o = this[m];
        f(o);
      }
      return this;
    };

    AgentSet.prototype["with"] = function(f) {
      var o;
      if (u.isString(f)) {
        eval("f=function(o){return " + f + ";}");
      }
      return this.asSet((function() {
        var len, m, results;
        results = [];
        for (m = 0, len = this.length; m < len; m++) {
          o = this[m];
          if (f(o)) {
            results.push(o);
          }
        }
        return results;
      }).call(this));
    };

    return AgentSet;

  })(Array);

  Patch = (function() {
    Patch.prototype.id = null;

    Patch.prototype.breed = null;

    Patch.prototype.x = null;

    Patch.prototype.y = null;

    Patch.prototype.n = null;

    Patch.prototype.n4 = null;

    Patch.prototype.hidden = false;

    Patch.prototype.label = null;

    Patch.prototype.labelOffset = [0, 0];

    Patch.prototype.pRect = null;

    function Patch(x3, y3) {
      this.x = x3;
      this.y = y3;
    }

    Patch.prototype.toString = function() {
      return "{id:" + this.id + " xy:" + [this.x, this.y] + " c:" + this.color + "}";
    };

    Patch.prototype.scaleColor = function(c, s) {
      u.deprecated("Patch.scaleColor: use ColorMaps ramps or closestColor");
      return this.color = ColorMaps.scaleColor(c, s);
    };

    Patch.prototype.scaleOpacity = function(c, s) {
      u.deprecated("Patch.scaleOpacity: use ColorMaps ramps");
      return this.color = u.scaleOpacity(c, s, this.color);
    };

    Patch.prototype.draw = function(ctx) {
      var ref, x, y;
      u.deprecated("Patch.draw not used, Patches.draw uses pixels");
      ctx.fillStyle = this.color.css;
      ctx.fillRect(this.x - .5, this.y - .5, 1, 1);
      if (this.label != null) {
        ref = this.breed.patchXYtoPixelXY(this.x, this.y), x = ref[0], y = ref[1];
        return u.ctxDrawText(ctx, this.label, x + this.labelOffset[0], y + this.labelOffset[1], this.labelColor.css);
      }
    };

    Patch.prototype.inRadius = function(agentSet, radius) {
      return agentSet.inRadius(this, radius);
    };

    Patch.prototype.turtlesHere = function() {
      var a, ref;
      if (!this.turtles) {
        u.deprecated("Patch.turtlesHere: make caching default");
      }
      return (ref = this.turtles) != null ? ref : (function() {
        var len, m, ref1, results;
        ref1 = this.model.turtles;
        results = [];
        for (m = 0, len = ref1.length; m < len; m++) {
          a = ref1[m];
          if (a.p === this) {
            results.push(a);
          }
        }
        return results;
      }).call(this);
    };

    Patch.prototype.breedsHere = function(breed) {
      var a, len, m, ref, results;
      ref = this.turtlesHere();
      results = [];
      for (m = 0, len = ref.length; m < len; m++) {
        a = ref[m];
        if (a.breed === breed) {
          results.push(a);
        }
      }
      return results;
    };

    Patch.prototype.isOnEdge = function() {
      return this.x === this.breed.minX || this.x === this.breed.maxX || this.y === this.breed.minY || this.y === this.breed.maxY;
    };

    Patch.prototype.sprout = function(num, breed, init) {
      if (num == null) {
        num = 1;
      }
      if (breed == null) {
        breed = this.model.turtles;
      }
      if (init == null) {
        init = function() {};
      }
      return breed.create(num, (function(_this) {
        return function(a) {
          a.setXY(_this.x, _this.y);
          init(a);
          return a;
        };
      })(this));
    };

    return Patch;

  })();

  colorMixin(Patch, "color", "black");

  colorMixin(Patch, "labelColor", "black");

  Patches = (function(superClass) {
    extend(Patches, superClass);

    Patches.prototype.drawWithPixels = true;

    function Patches() {
      var k, ref, v;
      Patches.__super__.constructor.apply(this, arguments);
      this.monochrome = false;
      ref = this.model.world;
      for (k in ref) {
        if (!hasProp.call(ref, k)) continue;
        v = ref[k];
        this[k] = v;
      }
      if (this.mainSet == null) {
        this.populate();
      }
    }

    Patches.prototype.populate = function() {
      var aa, m, ref, ref1, ref2, ref3, x, y;
      for (y = m = ref = this.maxY, ref1 = this.minY; m >= ref1; y = m += -1) {
        for (x = aa = ref2 = this.minX, ref3 = this.maxX; aa <= ref3; x = aa += 1) {
          this.add(new this.agentClass(x, y));
        }
      }
      if (this.hasNeighbors) {
        this.setNeighbors();
      }
      if (this.model.div != null) {
        return this.setPixels();
      }
    };

    Patches.prototype.cacheTurtlesHere = function() {
      var len, m, p;
      for (m = 0, len = this.length; m < len; m++) {
        p = this[m];
        p.turtles = [];
      }
      return null;
    };

    Patches.prototype.usePixels = function() {
      return u.deprecated("Patches.usePixels: pixels always used (color.pixel)");
    };

    Patches.prototype.cacheRect = function(radius, meToo) {
      var len, m, p;
      if (meToo == null) {
        meToo = true;
      }
      for (m = 0, len = this.length; m < len; m++) {
        p = this[m];
        p.pRect = this.patchRect(p, radius, radius, meToo);
        p.pRect.radius = radius;
      }
      return null;
    };

    Patches.prototype.setNeighbors = function() {
      var len, m, n, p;
      for (m = 0, len = this.length; m < len; m++) {
        p = this[m];
        p.n = this.patchRect(p, 1, 1, false);
        p.n4 = this.asSet((function() {
          var aa, len1, ref, results;
          ref = p.n;
          results = [];
          for (aa = 0, len1 = ref.length; aa < len1; aa++) {
            n = ref[aa];
            if (n.x === p.x || n.y === p.y) {
              results.push(n);
            }
          }
          return results;
        })());
      }
      return null;
    };

    Patches.prototype.setPixels = function() {
      var ctx;
      ctx = this.model.contexts.patches;
      u.setCtxSmoothing(ctx, false);
      if (this.size === 1) {
        this.pixelsCtx = ctx;
      } else {
        this.pixelsCtx = u.createCtx(this.numX, this.numY);
      }
      this.pixelsImageData = this.pixelsCtx.getImageData(0, 0, this.numX, this.numY);
      this.pixelsData = this.pixelsImageData.data;
      if (this.drawWithPixels) {
        return this.pixelsData32 = new Uint32Array(this.pixelsData.buffer);
      }
    };

    Patches.prototype.draw = function(ctx) {
      if (this.monochrome) {
        return u.fillCtx(ctx, this.agentClass.prototype.color);
      } else {
        return this.drawScaledPixels(ctx);
      }
    };

    Patches.prototype.patchIndex = function(x, y) {
      return x - this.minX + this.numX * (this.maxY - y);
    };

    Patches.prototype.patchXY = function(x, y) {
      return this[this.patchIndex(x, y)];
    };

    Patches.prototype.clamp = function(x, y) {
      return [u.clamp(x, this.minXcor, this.maxXcor), u.clamp(y, this.minYcor, this.maxYcor)];
    };

    Patches.prototype.wrap = function(x, y) {
      return [u.wrap(x, this.minXcor, this.maxXcor), u.wrap(y, this.minYcor, this.maxYcor)];
    };

    Patches.prototype.coord = function(x, y) {
      if (this.isTorus) {
        return this.wrap(x, y);
      } else {
        return this.clamp(x, y);
      }
    };

    Patches.prototype.isOnWorld = function(x, y) {
      return this.isTorus || ((this.minXcor <= x && x <= this.maxXcor) && (this.minYcor <= y && y <= this.maxYcor));
    };

    Patches.prototype.patch = function(x, y) {
      var ref;
      ref = this.coord(x, y), x = ref[0], y = ref[1];
      x = u.clamp(Math.round(x), this.minX, this.maxX);
      y = u.clamp(Math.round(y), this.minY, this.maxY);
      return this.patchXY(x, y);
    };

    Patches.prototype.randomPt = function() {
      return [u.randomFloat2(this.minXcor, this.maxXcor), u.randomFloat2(this.minYcor, this.maxYcor)];
    };

    Patches.prototype.toBits = function(p) {
      return p * this.size;
    };

    Patches.prototype.fromBits = function(b) {
      return b / this.size;
    };

    Patches.prototype.patchRect = function(p, dx, dy, meToo) {
      var aa, m, pnext, rect, ref, ref1, ref2, ref3, x, y;
      if (dy == null) {
        dy = dx;
      }
      if (meToo == null) {
        meToo = true;
      }
      if ((p.pRect != null) && (p.pRect.radius === dx) && (dx === dy)) {
        return p.pRect;
      }
      rect = [];
      for (y = m = ref = p.y - dy, ref1 = p.y + dy; m <= ref1; y = m += 1) {
        for (x = aa = ref2 = p.x - dx, ref3 = p.x + dx; aa <= ref3; x = aa += 1) {
          if (this.isTorus || ((this.minX <= x && x <= this.maxX) && (this.minY <= y && y <= this.maxY))) {
            if (this.isTorus) {
              if (x < this.minX) {
                x += this.numX;
              } else if (x > this.maxX) {
                x -= this.numX;
              }
              if (y < this.minY) {
                y += this.numY;
              } else if (y > this.maxY) {
                y -= this.numY;
              }
            }
            pnext = this.patchXY(x, y);
            if (meToo || p !== pnext) {
              rect.push(pnext);
            }
          }
        }
      }
      return this.asSet(rect);
    };

    Patches.prototype.inRect = function(agent, radius) {
      var ref;
      return this.patchRect((ref = agent.p) != null ? ref : agent, Math.ceil(radius));
    };

    Patches.prototype.inRadius = function(agent, radius) {
      var pset, ref;
      pset = this.patchRect((ref = agent.p) != null ? ref : agent, Math.ceil(radius));
      return pset.inRadius(agent, radius);
    };

    Patches.prototype.inCone = function(agent, radius, angle, heading) {
      var pset, ref;
      pset = this.patchRect((ref = agent.p) != null ? ref : agent, Math.ceil(radius));
      return pset.inRadius(agent, radius, angle, heading);
    };

    Patches.prototype.turtlesOnRect = function(p, dx, dy) {
      if (dy == null) {
        dy = dx;
      }
      return this.turtlesOnPatches(this.patchRect(p, dx, dy, true));
    };

    Patches.prototype.turtlesOnPatches = function(patches) {
      var array, len, m, p;
      array = [];
      if (patches.length !== 0) {
        if (patches[0].turtles == null) {
          u.error("turtlesOnPatches: no cached turtles.");
        }
        for (m = 0, len = patches.length; m < len; m++) {
          p = patches[m];
          Array.prototype.push.apply(array, p.turtles);
        }
      }
      return this.asSet(array);
    };

    Patches.prototype.patchesOf = function(aset) {
      var a, ref;
      if (aset.length == null) {
        return this.asSet([(ref = aset.p) != null ? ref : aset]);
      }
      return this.asSet((function() {
        var len, m, ref1, results;
        results = [];
        for (m = 0, len = aset.length; m < len; m++) {
          a = aset[m];
          results.push((ref1 = a.p) != null ? ref1 : a);
        }
        return results;
      })()).sortById().uniq();
    };

    Patches.prototype.turtlesOf = function(aset) {
      return this.turtlesOnPatches(this.patchesOf(aset));
    };

    Patches.prototype.importDrawing = function(imageSrc, f) {
      return u.importImage(imageSrc, (function(_this) {
        return function(img) {
          _this.installDrawing(img);
          if (f != null) {
            return f();
          }
        };
      })(this));
    };

    Patches.prototype.installDrawing = function(img, ctx) {
      if (ctx == null) {
        ctx = this.model.contexts.drawing;
      }
      u.setIdentity(ctx);
      ctx.drawImage(img, 0, 0, ctx.canvas.width, ctx.canvas.height);
      return ctx.restore();
    };

    Patches.prototype.pixelByteIndex = function(p) {
      return 4 * p.id;
    };

    Patches.prototype.pixelWordIndex = function(p) {
      return p.id;
    };

    Patches.prototype.pixelXYtoPatchXY = function(x, y) {
      return [this.minXcor + (x / this.size), this.maxYcor - (y / this.size)];
    };

    Patches.prototype.patchXYtoPixelXY = function(x, y) {
      return [(x - this.minXcor) * this.size, (this.maxYcor - y) * this.size];
    };

    Patches.prototype.importColors = function(imageSrc, f, map) {
      return u.importImage(imageSrc, (function(_this) {
        return function(img) {
          _this.installColors(img, map);
          if (f != null) {
            return f();
          }
        };
      })(this));
    };

    Patches.prototype.installColors = function(img, map) {
      var data, i, len, m, p;
      u.setIdentity(this.pixelsCtx);
      this.pixelsCtx.drawImage(img, 0, 0, this.numX, this.numY);
      data = this.pixelsCtx.getImageData(0, 0, this.numX, this.numY).data;
      for (m = 0, len = this.length; m < len; m++) {
        p = this[m];
        i = this.pixelByteIndex(p);
        p.color = map != null ? map[i] : [data[i++], data[i++], data[i]];
      }
      return this.pixelsCtx.restore();
    };

    Patches.prototype.drawScaledPixels = function(ctx) {
      var aa, data, len, len1, m, p, ref;
      if (this.size !== 1) {
        u.setIdentity(ctx);
      }
      data = (ref = this.pixelsData32) != null ? ref : this.pixelsData;
      if (this.pixelsData32 != null) {
        for (m = 0, len = this.length; m < len; m++) {
          p = this[m];
          data[p.id] = p.color.pixel;
        }
      } else {
        for (aa = 0, len1 = this.length; aa < len1; aa++) {
          p = this[aa];
          data.set(p.color, p.id * 4);
        }
      }
      this.pixelsCtx.putImageData(this.pixelsImageData, 0, 0);
      if (this.size === 1) {
        return;
      }
      ctx.drawImage(this.pixelsCtx.canvas, 0, 0, this.pxWidth, this.pxHeight);
      if (this.size !== 1) {
        return ctx.restore();
      }
    };

    Patches.prototype.diffuse = function(v, rate, color) {
      var aa, ab, ac, dv, dv8, len, len1, len2, len3, m, n, nn, p, ref;
      if (this[0]._diffuseNext == null) {
        for (m = 0, len = this.length; m < len; m++) {
          p = this[m];
          p._diffuseNext = 0;
        }
      }
      for (aa = 0, len1 = this.length; aa < len1; aa++) {
        p = this[aa];
        dv = p[v] * rate;
        dv8 = dv / 8;
        nn = p.n.length;
        p._diffuseNext += p[v] - dv + (8 - nn) * dv8;
        ref = p.n;
        for (ab = 0, len2 = ref.length; ab < len2; ab++) {
          n = ref[ab];
          n._diffuseNext += dv8;
        }
      }
      for (ac = 0, len3 = this.length; ac < len3; ac++) {
        p = this[ac];
        p[v] = p._diffuseNext;
        p._diffuseNext = 0;
        if (color != null) {
          p.color = ColorMaps.scaleColor(color, p[v]);
        }
      }
      return null;
    };

    return Patches;

  })(AgentSet);

  Turtle = (function() {
    Turtle.prototype.id = null;

    Turtle.prototype.breed = null;

    Turtle.prototype.x = 0;

    Turtle.prototype.y = 0;

    Turtle.prototype.p = null;

    Turtle.prototype.size = 1;

    Turtle.prototype.color = null;

    Turtle.prototype.strokeColor = null;

    Turtle.prototype.shape = "default";

    Turtle.prototype.hidden = false;

    Turtle.prototype.label = null;

    Turtle.prototype.labelColor = [0, 0, 0];

    Turtle.prototype.labelOffset = [0, 0];

    Turtle.prototype.penDown = false;

    Turtle.prototype.penSize = 1;

    Turtle.prototype.heading = null;

    Turtle.prototype.sprite = null;

    Turtle.prototype.useSprites = false;

    Turtle.prototype.cacheLinks = false;

    Turtle.prototype.links = null;

    function Turtle() {
      this.x = this.y = 0;
      this.p = this.model.patches.patch(this.x, this.y);
      if (this.color == null) {
        this.color = u.randomColor();
      }
      if (this.heading == null) {
        this.heading = u.randomFloat(Math.PI * 2);
      }
      if (this.p.turtles != null) {
        this.p.turtles.push(this);
      }
      if (this.cacheLinks) {
        this.links = [];
      }
    }

    Turtle.prototype.scaleColor = function(c, s) {
      u.deprecated("Turtle.scaleColor: use ColorMaps ramps or closestColor");
      return this.color = ColorMaps.scaleColor(c, s);
    };

    Turtle.prototype.scaleOpacity = function(c, s) {
      u.deprecated("Turtle.scaleOpacity: use ColorMaps ramps");
      return this.color = u.scaleOpacity(c, s, this.color);
    };

    Turtle.prototype.toString = function() {
      var h;
      return "{id:" + this.id + " xy:" + (u.aToFixed([this.x, this.y])) + " c:" + this.color.css + " h: " + (h = this.heading.toFixed(2)) + "/" + (Math.round(u.radToDeg(h))) + "}";
    };

    Turtle.prototype.setXY = function(x, y) {
      var drawing, p, ref, ref1, x0, y0;
      if (this.penDown) {
        ref = [this.x, this.y], x0 = ref[0], y0 = ref[1];
      }
      ref1 = this.model.patches.coord(x, y), this.x = ref1[0], this.y = ref1[1];
      p = this.p;
      this.p = this.model.patches.patch(this.x, this.y);
      if ((p.turtles != null) && p !== this.p) {
        u.removeItem(p.turtles, this);
        this.p.turtles.push(this);
      }
      if (this.penDown) {
        drawing = this.model.drawing;
        drawing.strokeStyle = this.color.css;
        drawing.lineWidth = this.model.patches.fromBits(this.penSize);
        drawing.beginPath();
        drawing.moveTo(x0, y0);
        drawing.lineTo(x, y);
        return drawing.stroke();
      }
    };

    Turtle.prototype.moveTo = function(a) {
      return this.setXY(a.x, a.y);
    };

    Turtle.prototype.forward = function(d) {
      return this.setXY(this.x + d * Math.cos(this.heading), this.y + d * Math.sin(this.heading));
    };

    Turtle.prototype.rotate = function(rad) {
      return this.heading = u.wrap(this.heading + rad, 0, Math.PI * 2);
    };

    Turtle.prototype.right = function(rad) {
      return this.rotate(-rad);
    };

    Turtle.prototype.left = function(rad) {
      return this.rotate(rad);
    };

    Turtle.prototype.draw = function(ctx) {
      var rad, ref, shape, x, y;
      shape = Shapes[this.shape];
      rad = shape.rotate ? this.heading : 0;
      if ((this.sprite != null) || this.useSprites) {
        if (this.sprite == null) {
          this.setSprite();
        }
        Shapes.drawSprite(ctx, this.sprite, this.x, this.y, this.size, rad);
      } else {
        Shapes.draw(ctx, shape, this.x, this.y, this.size, rad, this.color, this.strokeColor);
      }
      if (this.label != null) {
        ref = this.model.patches.patchXYtoPixelXY(this.x, this.y), x = ref[0], y = ref[1];
        return u.ctxDrawText(ctx, this.label, x + this.labelOffset[0], y + this.labelOffset[1], this.labelColor);
      }
    };

    Turtle.prototype.setSprite = function(sprite) {
      var s;
      if ((s = sprite) != null) {
        this.sprite = s;
        this.color = s.color;
        this.strokeColor = s.strokeColor;
        this.shape = s.shape;
        return this.size = this.model.patches.fromBits(s.size);
      } else {
        return this.sprite = Shapes.shapeToSprite(this.shape, this.color, this.model.patches.toBits(this.size), this.strokeColor);
      }
    };

    Turtle.prototype.stamp = function() {
      return this.draw(this.model.drawing);
    };

    Turtle.prototype.distanceXY = function(x, y) {
      if (this.model.patches.isTorus) {
        return u.torusDistance(this.x, this.y, x, y, this.model.patches.numX, this.model.patches.numY);
      } else {
        return u.distance(this.x, this.y, x, y);
      }
    };

    Turtle.prototype.distance = function(o) {
      return this.distanceXY(o.x, o.y);
    };

    Turtle.prototype.torusPtXY = function(x, y) {
      return u.torusPt(this.x, this.y, x, y, this.model.patches.numX, this.model.patches.numY);
    };

    Turtle.prototype.torusPt = function(o) {
      return this.torusPtXY(o.x, o.y);
    };

    Turtle.prototype.face = function(o) {
      return this.heading = this.towards(o);
    };

    Turtle.prototype.towardsXY = function(x, y) {
      var ps;
      if ((ps = this.model.patches).isTorus) {
        return u.torusRadsToward(this.x, this.y, x, y, ps.numX, ps.numY);
      } else {
        return u.radsToward(this.x, this.y, x, y);
      }
    };

    Turtle.prototype.towards = function(o) {
      return this.towardsXY(o.x, o.y);
    };

    Turtle.prototype.patchAtHeadingAndDistance = function(h, d) {
      var dx, dy, ref;
      ref = u.polarToXY(d, h + this.heading), dx = ref[0], dy = ref[1];
      return this.patchAt(dx, dy);
    };

    Turtle.prototype.patchLeftAndAhead = function(dh, d) {
      return this.patchAtHeadingAndDistance(dh, d);
    };

    Turtle.prototype.patchRightAndAhead = function(dh, d) {
      return this.patchAtHeadingAndDistance(-dh, d);
    };

    Turtle.prototype.patchAhead = function(d) {
      return this.patchAtHeadingAndDistance(0, d);
    };

    Turtle.prototype.canMove = function(d) {
      return this.patchAhead(d) != null;
    };

    Turtle.prototype.patchAt = function(dx, dy) {
      var ps, x, y;
      x = this.x + dx;
      y = this.y + dy;
      if ((ps = this.model.patches).isOnWorld(x, y)) {
        return ps.patch(x, y);
      } else {
        return null;
      }
    };

    Turtle.prototype.die = function() {
      var l, m, ref;
      this.breed.remove(this);
      ref = this.myLinks();
      for (m = ref.length - 1; m >= 0; m += -1) {
        l = ref[m];
        l.die();
      }
      if (this.p.turtles != null) {
        u.removeItem(this.p.turtles, this);
      }
      return null;
    };

    Turtle.prototype.hatch = function(num, breed, init) {
      if (num == null) {
        num = 1;
      }
      if (breed == null) {
        breed = this.breed;
      }
      if (init == null) {
        init = function() {};
      }
      return breed.create(num, (function(_this) {
        return function(a) {
          var k, len, m, ref;
          a.setXY(_this.x, _this.y);
          a.color = _this.color;
          ref = breed.ownVariables;
          for (m = 0, len = ref.length; m < len; m++) {
            k = ref[m];
            if (a[k] === null) {
              a[k] = _this[k];
            }
          }
          init(a);
          return a;
        };
      })(this));
    };

    Turtle.prototype.inRadius = function(aset, radius) {
      return aset.inRadius(this, radius);
    };

    Turtle.prototype.inCone = function(aset, distance, angle) {
      return aset.inCone(this, distance, angle, this.heading);
    };

    Turtle.prototype.hitTest = function(x, y) {
      return this.distanceXY(x, y) < this.size;
    };

    Turtle.prototype.otherEnd = function(l) {
      if (l.end1 === this) {
        return l.end2;
      } else {
        return l.end1;
      }
    };

    Turtle.prototype.myLinks = function() {
      var l, ref;
      return (ref = this.links) != null ? ref : (function() {
        var len, m, ref1, results;
        ref1 = this.model.links;
        results = [];
        for (m = 0, len = ref1.length; m < len; m++) {
          l = ref1[m];
          if ((l.end1 === this) || (l.end2 === this)) {
            results.push(l);
          }
        }
        return results;
      }).call(this);
    };

    Turtle.prototype.linkNeighbors = function() {
      var l, len, m, ref, results;
      ref = this.myLinks();
      results = [];
      for (m = 0, len = ref.length; m < len; m++) {
        l = ref[m];
        results.push(this.otherEnd(l));
      }
      return results;
    };

    Turtle.prototype.myInLinks = function() {
      var l, len, m, ref, results;
      ref = this.myLinks();
      results = [];
      for (m = 0, len = ref.length; m < len; m++) {
        l = ref[m];
        if (l.end2 === this) {
          results.push(l);
        }
      }
      return results;
    };

    Turtle.prototype.inLinkNeighbors = function() {
      var l, len, m, ref, results;
      ref = this.myLinks();
      results = [];
      for (m = 0, len = ref.length; m < len; m++) {
        l = ref[m];
        if (l.end2 === this) {
          results.push(l.end1);
        }
      }
      return results;
    };

    Turtle.prototype.myOutLinks = function() {
      var l, len, m, ref, results;
      ref = this.myLinks();
      results = [];
      for (m = 0, len = ref.length; m < len; m++) {
        l = ref[m];
        if (l.end1 === this) {
          results.push(l);
        }
      }
      return results;
    };

    Turtle.prototype.outLinkNeighbors = function() {
      var l, len, m, ref, results;
      ref = this.myLinks();
      results = [];
      for (m = 0, len = ref.length; m < len; m++) {
        l = ref[m];
        if (l.end1 === this) {
          results.push(l.end2);
        }
      }
      return results;
    };

    return Turtle;

  })();

  colorMixin(Turtle, "color", null);

  colorMixin(Turtle, "strokeColor", null);

  colorMixin(Turtle, "labelColor", "black");

  Turtles = (function(superClass) {
    extend(Turtles, superClass);

    function Turtles() {
      Turtles.__super__.constructor.apply(this, arguments);
    }

    Turtles.prototype.cacheLinks = function() {
      return this.agentClass.prototype.cacheLinks = true;
    };

    Turtles.prototype.setUseSprites = function(useSprites) {
      if (useSprites == null) {
        useSprites = true;
      }
      u.deprecated('Turtles.setUseSprites: use turtles.setDefault("useSprites",bool)');
      return this.setDefault("useSprites", useSprites);
    };

    Turtles.prototype.create = function(num, init) {
      var i, m, ref, results;
      if (init == null) {
        init = function() {};
      }
      results = [];
      for (i = m = 1, ref = num; m <= ref; i = m += 1) {
        results.push((function(o) {
          init(o);
          return o;
        })(this.add(new this.agentClass)));
      }
      return results;
    };

    Turtles.prototype.clear = function() {
      while (this.any()) {
        this.last().die();
      }
      return null;
    };

    Turtles.prototype.breedsIn = function(array) {
      var o;
      return this.asSet((function() {
        var len, m, results;
        results = [];
        for (m = 0, len = array.length; m < len; m++) {
          o = array[m];
          if (o.breed === this) {
            results.push(o);
          }
        }
        return results;
      }).call(this));
    };

    Turtles.prototype.inPatches = function(patches) {
      var array, len, m, p;
      array = [];
      for (m = 0, len = patches.length; m < len; m++) {
        p = patches[m];
        array.push.apply(array, p.turtlesHere());
      }
      if (this.mainSet != null) {
        return this.breedsIn(array);
      } else {
        return this.asSet(array);
      }
    };

    Turtles.prototype.inRect = function(p, dx, dy) {
      var rect;
      if (dy == null) {
        dy = dx;
      }
      rect = this.model.patches.patchRect(p, dx, dy);
      return this.inPatches(rect);
    };

    Turtles.prototype.inRadius = function(agent, radius) {
      var as, ref;
      as = this.inRect((ref = agent.p) != null ? ref : agent, Math.ceil(radius));
      return as.inRadius(agent, radius);
    };

    Turtles.prototype.inCone = function(agent, radius, angle, heading) {
      var as, ref;
      as = this.inRect((ref = agent.p) != null ? ref : agent, Math.ceil(radius));
      return as.inCone(agent, radius, angle, heading);
    };

    Turtles.prototype.setDraggable = function() {
      this.on('dragstart', (function(_this) {
        return function(mouseEvent) {
          return mouseEvent.target.dragging = true;
        };
      })(this));
      this.on('dragend', (function(_this) {
        return function(mouseEvent) {
          return mouseEvent.target.dragging = false;
        };
      })(this));
      return this.on('drag', (function(_this) {
        return function(mouseEvent) {
          return mouseEvent.target.setXY(mouseEvent.patchX, mouseEvent.patchY);
        };
      })(this));
    };

    return Turtles;

  })(AgentSet);

  Link = (function() {
    Link.prototype.id = null;

    Link.prototype.breed = null;

    Link.prototype.end1 = null;

    Link.prototype.end2 = null;

    Link.prototype.color = [130, 130, 130];

    Link.prototype.thickness = 2;

    Link.prototype.hidden = false;

    Link.prototype.label = null;

    Link.prototype.labelColor = [0, 0, 0];

    Link.prototype.labelOffset = [0, 0];

    function Link(end11, end21) {
      this.end1 = end11;
      this.end2 = end21;
      if (this.end1.links != null) {
        this.end1.links.push(this);
        this.end2.links.push(this);
      }
    }

    Link.prototype.draw = function(ctx) {
      var pt, ref, ref1, x, x0, y, y0;
      ctx.save();
      ctx.strokeStyle = this.color.css;
      ctx.lineWidth = this.model.patches.fromBits(this.thickness);
      ctx.beginPath();
      if (!this.model.patches.isTorus) {
        ctx.moveTo(this.end1.x, this.end1.y);
        ctx.lineTo(this.end2.x, this.end2.y);
      } else {
        pt = this.end1.torusPt(this.end2);
        ctx.moveTo(this.end1.x, this.end1.y);
        ctx.lineTo.apply(ctx, pt);
        if (pt[0] !== this.end2.x || pt[1] !== this.end2.y) {
          pt = this.end2.torusPt(this.end1);
          ctx.moveTo(this.end2.x, this.end2.y);
          ctx.lineTo.apply(ctx, pt);
        }
      }
      ctx.closePath();
      ctx.stroke();
      ctx.restore();
      if (this.label != null) {
        ref = u.lerp2(this.end1.x, this.end1.y, this.end2.x, this.end2.y, .5), x0 = ref[0], y0 = ref[1];
        ref1 = this.model.patches.patchXYtoPixelXY(x0, y0), x = ref1[0], y = ref1[1];
        return u.ctxDrawText(ctx, this.label, x + this.labelOffset[0], y + this.labelOffset[1], this.labelColor);
      }
    };

    Link.prototype.die = function() {
      this.breed.remove(this);
      if (this.end1.links != null) {
        u.removeItem(this.end1.links, this);
      }
      if (this.end2.links != null) {
        u.removeItem(this.end2.links, this);
      }
      return null;
    };

    Link.prototype.hitTest = function(x, y) {
      var a, distance;
      distance = u.aSum((function() {
        var len, m, ref, results;
        ref = this.bothEnds();
        results = [];
        for (m = 0, len = ref.length; m < len; m++) {
          a = ref[m];
          results.push(a.distanceXY(x, y));
        }
        return results;
      }).call(this));
      return distance - this.length() < 0.05 / this.model.patches.size;
    };

    Link.prototype.bothEnds = function() {
      return [this.end1, this.end2];
    };

    Link.prototype.length = function() {
      return this.end1.distance(this.end2);
    };

    Link.prototype.otherEnd = function(a) {
      if (this.end1 === a) {
        return this.end2;
      } else {
        return this.end1;
      }
    };

    return Link;

  })();

  colorMixin(Link, "color", [130, 130, 130]);

  colorMixin(Link, "labelColor", "black");

  Links = (function(superClass) {
    extend(Links, superClass);

    function Links() {
      Links.__super__.constructor.apply(this, arguments);
    }

    Links.prototype.create = function(from, to, init) {
      var a, len, m, results;
      if (init == null) {
        init = function() {};
      }
      if (to.length == null) {
        to = [to];
      }
      results = [];
      for (m = 0, len = to.length; m < len; m++) {
        a = to[m];
        results.push((function(o) {
          init(o);
          return o;
        })(this.add(new this.agentClass(from, a))));
      }
      return results;
    };

    Links.prototype.clear = function() {
      while (this.any()) {
        this.last().die();
      }
      return null;
    };

    Links.prototype.allEnds = function() {
      var l, len, m, n;
      n = this.asSet([]);
      for (m = 0, len = this.length; m < len; m++) {
        l = this[m];
        n.push(l.end1, l.end2);
      }
      return n;
    };

    Links.prototype.nodes = function() {
      return this.allEnds().sortById().uniq();
    };

    Links.prototype.layoutCircle = function(list, radius, startAngle, direction) {
      var a, dTheta, i, len, m;
      if (startAngle == null) {
        startAngle = Math.PI / 2;
      }
      if (direction == null) {
        direction = -1;
      }
      dTheta = 2 * Math.PI / list.length;
      for (i = m = 0, len = list.length; m < len; i = ++m) {
        a = list[i];
        a.setXY(0, 0);
        a.heading = startAngle + direction * dTheta * i;
        a.forward(radius);
      }
      return null;
    };

    Links.prototype.setDraggable = function() {
      this.on('dragstart', (function(_this) {
        return function(mouseEvent) {
          return mouseEvent.target.dragging = true;
        };
      })(this));
      this.on('dragend', (function(_this) {
        return function(mouseEvent) {
          return mouseEvent.target.dragging = false;
        };
      })(this));
      return this.on('drag', (function(_this) {
        return function(mouseEvent) {
          var end1, end2;
          end1 = mouseEvent.target.end1;
          end2 = mouseEvent.target.end2;
          end1.setXY(end1.x - mouseEvent.dx, end1.y - mouseEvent.dy);
          return end2.setXY(end2.x - mouseEvent.dx, end2.y - mouseEvent.dy);
        };
      })(this));
    };

    return Links;

  })(AgentSet);

  Model = (function() {
    Model.prototype.contextsInit = {
      patches: {
        z: 10,
        ctx: "2d"
      },
      drawing: {
        z: 20,
        ctx: "2d"
      },
      links: {
        z: 30,
        ctx: "2d"
      },
      turtles: {
        z: 40,
        ctx: "2d"
      },
      spotlight: {
        z: 50,
        ctx: "2d"
      }
    };

    Model.nonWorldOptions = ["div"];

    Model.defaultOptions = function() {
      return {
        div: null,
        size: 13,
        minX: -16,
        maxX: 16,
        minY: -16,
        maxY: 16,
        isTorus: false,
        hasNeighbors: true
      };
    };

    function Model(args) {
      var ctx, k, options, ref, s, v;
      options = Model.defaultOptions();
      if (!u.isObject(args)) {
        console.log("option defaults:", options);
        u.error("Model constructor: use options object; see console for defaults.");
      }
      if (args.isHeadless != null) {
        u.deprecated("Model: isHeadless no longer used");
      }
      for (k in args) {
        v = args[k];
        if (options[k] === void 0) {
          u.error("Bad Model arg: " + k + ": " + v);
        }
        options[k] = v;
      }
      this.setWorld(options);
      u.mixin(this, new Evented());
      this.contexts = {};
      if (options.div != null) {
        this.div = document.getElementById(options.div);
        s = this.div.style;
        s.position = "relative";
        s.width = this.world.pxWidth;
        s.height = this.world.pxHeight;
        ref = this.contextsInit;
        for (k in ref) {
          if (!hasProp.call(ref, k)) continue;
          v = ref[k];
          this.contexts[k] = ctx = u.createLayer(this.div, this.world.pxWidth, this.world.pxHeight, v.z, v.ctx);
          if (ctx.canvas != null) {
            this.setCtxTransform(ctx);
          }
          if (ctx.canvas != null) {
            ctx.canvas.style.pointerEvents = 'none';
          }
          u.elementTextParams(ctx, "10px sans-serif", "center", "middle");
        }
        this.drawing = this.contexts.drawing;
        this.drawing.clear = (function(_this) {
          return function() {
            return u.clearCtx(_this.drawing);
          };
        })(this);
        this.contexts.spotlight.globalCompositeOperation = "xor";
      }
      this.anim = new Animator(this);
      this.refreshLinks = this.refreshTurtles = this.refreshPatches = true;
      this.Patch = u.cloneClass(Patch);
      this.Turtle = u.cloneClass(Turtle);
      this.Link = u.cloneClass(Link);
      this.patches = new Patches(this, this.Patch, "patches");
      this.turtles = new Turtles(this, this.Turtle, "turtles");
      this.links = new Links(this, this.Link, "links");
      this.debugging = false;
      this.modelReady = false;
      this.startup();
      u.waitOnFiles((function(_this) {
        return function() {
          _this.modelReady = true;
          return _this.setupAndEmit();
        };
      })(this));
    }

    Model.prototype.setWorld = function(opts) {
      var k, v, w;
      w = {};
      for (k in opts) {
        if (!hasProp.call(opts, k)) continue;
        v = opts[k];
        if (indexOf.call(Model.nonWorldOptions, k) < 0) {
          w[k] = v;
        }
      }
      w.numX = w.maxX - w.minX + 1;
      w.numY = w.maxY - w.minY + 1;
      w.pxWidth = w.numX * w.size;
      w.pxHeight = w.numY * w.size;
      w.minXcor = w.minX - .5;
      w.maxXcor = w.maxX + .5;
      w.minYcor = w.minY - .5;
      w.maxYcor = w.maxY + .5;
      return this.world = w;
    };

    Model.prototype.setCtxTransform = function(ctx) {
      ctx.canvas.width = this.world.pxWidth;
      ctx.canvas.height = this.world.pxHeight;
      ctx.save();
      ctx.scale(this.world.size, -this.world.size);
      return ctx.translate(-this.world.minXcor, -this.world.maxYcor);
    };

    Model.prototype.setFastPatches = function() {
      return this.patches.usePixels();
    };

    Model.prototype.setMonochromePatches = function() {
      return this.patches.monochrome = true;
    };

    Model.prototype.setCacheTurtlesHere = function() {
      return this.patches.cacheTurtlesHere();
    };

    Model.prototype.setCacheMyLinks = function() {
      return this.turtles.cacheLinks();
    };

    Model.prototype.startup = function() {};

    Model.prototype.setup = function() {};

    Model.prototype.step = function() {};

    Model.prototype.start = function() {
      u.waitOn(((function(_this) {
        return function() {
          return _this.modelReady;
        };
      })(this)), ((function(_this) {
        return function() {
          return _this.anim.start();
        };
      })(this)));
      return this;
    };

    Model.prototype.stop = function() {
      return this.anim.stop();
    };

    Model.prototype.once = function() {
      if (!this.anim.stopped) {
        this.stop();
      }
      return this.anim.once();
    };

    Model.prototype.reset = function(restart) {
      var k, ref, v;
      if (restart == null) {
        restart = false;
      }
      console.log("reset: anim");
      this.anim.reset();
      console.log("reset: contexts");
      ref = this.contexts;
      for (k in ref) {
        v = ref[k];
        if (v.canvas != null) {
          v.restore();
          this.setCtxTransform(v);
        }
      }
      console.log("reset: patches");
      this.patches = new Patches(this, this.Patch, "patches");
      console.log("reset: turtles");
      this.turtles = new Turtles(this, this.Turtle, "turtles");
      console.log("reset: links");
      this.links = new Links(this, this.Link, "links");
      Shapes.spriteSheets.length = 0;
      console.log("reset: setup");
      this.setupAndEmit();
      if (restart) {
        return this.start();
      }
    };

    Model.prototype.draw = function(force) {
      if (force == null) {
        force = this.anim.stopped || this.anim.draws === 1;
      }
      if (this.debugging) {
        if (this.anim.draws % 100 === 0) {
          console.log(this.anim.toString());
        }
        if (this.anim.draws === 2) {
          this.showSpriteSheet();
        }
      }
      if (this.div != null) {
        if (force || this.refreshPatches) {
          this.patches.draw(this.contexts.patches);
        }
        if (force || this.refreshLinks) {
          this.links.draw(this.contexts.links);
        }
        if (force || this.refreshTurtles) {
          this.turtles.draw(this.contexts.turtles);
        }
        if (this.spotlightTurtle != null) {
          this.drawSpotlight(this.spotlightTurtle, this.contexts.spotlight);
        }
      }
      return this.emit('draw');
    };

    Model.prototype.toggleDrawing = function() {
      if (this.div != null) {
        this.div0 = this.div;
        return this.div = null;
      } else {
        this.div = this.div0;
        return this.div0 = null;
      }
    };

    Model.prototype.setupAndEmit = function() {
      this.setup();
      return this.emit('setup');
    };

    Model.prototype.stepAndEmit = function() {
      this.step();
      return this.emit('step');
    };

    Model.prototype.exportLayerDataUrl = function(name, format, quality) {
      var ctx;
      if (format == null) {
        format = "png";
      }
      if (quality == null) {
        quality = 0.92;
      }
      ctx = this.contexts[name];
      return ctx.canvas.toDataURL("image/" + format, quality);
    };

    Model.prototype.exportWorldDataUrl = function(format, quality) {
      var ctx, name, ref, worldCtx;
      if (format == null) {
        format = "png";
      }
      if (quality == null) {
        quality = 0.92;
      }
      worldCtx = u.createCtx(this.world.pxWidth, this.world.pxHeight);
      ref = this.contexts;
      for (name in ref) {
        ctx = ref[name];
        worldCtx.drawImage(ctx.canvas, 0, 0);
      }
      return worldCtx.canvas.toDataURL("image/" + format, quality);
    };

    Model.prototype.dataUrlToImage = function(dataURL) {
      var img;
      img = new Image();
      img.src = dataURL;
      return img;
    };

    Model.prototype.foo = function() {
      return console.log('foo');
    };

    Model.prototype.setSpotlight = function(spotlightTurtle) {
      this.spotlightTurtle = spotlightTurtle;
      if (this.spotlightTurtle == null) {
        return u.clearCtx(this.contexts.spotlight);
      }
    };

    Model.prototype.drawSpotlight = function(turtle, ctx) {
      u.clearCtx(ctx);
      u.fillCtx(ctx, Color.typedColor(0, 0, 0, .6 * 255));
      ctx.beginPath();
      ctx.arc(turtle.x, turtle.y, 3, 0, 2 * Math.PI, false);
      return ctx.fill();
    };

    Model.prototype.createBreeds = function(breedNames, baseClass, baseSet) {
      var breed, breedClass, breedName, breeds, className, len, m, ref;
      breeds = [];
      breeds.classes = {};
      breeds.sets = {};
      ref = breedNames.split(" ");
      for (m = 0, len = ref.length; m < len; m++) {
        breedName = ref[m];
        className = u.titleCase(breedName);
        breedClass = u.cloneClass(baseClass, className);
        breed = this[breedName] = new baseSet(this, breedClass, breedName, baseClass.prototype.breed);
        breeds.push(breed);
        breeds.sets[breedName] = breed;
        breeds.classes[breedName + "Class"] = breedClass;
      }
      return breeds;
    };

    Model.prototype.patchBreeds = function(breedNames) {
      return this.patches.breeds = this.createBreeds(breedNames, this.Patch, Patches);
    };

    Model.prototype.agentBreeds = function(breedNames) {
      return this.turtles.breeds = this.createBreeds(breedNames, this.Turtle, Turtles);
    };

    Model.prototype.linkBreeds = function(breedNames) {
      return this.links.breeds = this.createBreeds(breedNames, this.Link, Links);
    };

    Model.prototype.asSet = function(a, setType) {
      if (setType == null) {
        setType = AgentSet;
      }
      return AgentSet.asSet(a, setType);
    };

    Model.prototype.debug = function(debugging) {
      this.debugging = debugging != null ? debugging : true;
      window[u.camelCase(this.constructor.name)] = this;
      return this;
    };

    Model.prototype.setRootVars = function() {};

    Model.prototype.showSpriteSheet = function(divName) {
      var sheet;
      if (Shapes.spriteSheets.length !== 0) {
        sheet = Util.last(Shapes.spriteSheets);
        if (divName != null) {
          return document.getElementById(divName).appendChild(sheet.canvas);
        } else {
          sheet.canvas.setAttribute("style", "float:right");
          return this.div.parentElement.insertBefore(sheet.canvas, this.div);
        }
      } else {
        return console.log("showSpriteSheet: not using sprites");
      }
    };

    return Model;

  })();

  this.ABM = {
    Util: Util,
    Color: Color,
    ColorMaps: ColorMaps,
    colorMixin: colorMixin,
    Shapes: Shapes,
    AgentSet: AgentSet,
    Patch: Patch,
    Patches: Patches,
    Turtle: Turtle,
    Turtles: Turtles,
    Link: Link,
    Links: Links,
    Animator: Animator,
    Evented: Evented,
    Model: Model
  };

  Animator = (function() {
    function Animator(model, rate1, multiStep) {
      this.model = model;
      this.rate = rate1 != null ? rate1 : 30;
      this.multiStep = multiStep != null ? multiStep : false;
      this.animateDraws = bind(this.animateDraws, this);
      this.animateSteps = bind(this.animateSteps, this);
      this.reset();
    }

    Animator.prototype.setRate = function(rate1, multiStep) {
      this.rate = rate1;
      this.multiStep = multiStep != null ? multiStep : false;
      return this.resetTimes();
    };

    Animator.prototype.start = function() {
      if (!this.stopped) {
        return;
      }
      this.resetTimes();
      this.stopped = false;
      return this.animate();
    };

    Animator.prototype.stop = function() {
      this.stopped = true;
      if (this.animHandle != null) {
        cancelAnimationFrame(this.animHandle);
      }
      if (this.timeoutHandle != null) {
        clearTimeout(this.timeoutHandle);
      }
      if (this.intervalHandle != null) {
        clearInterval(this.intervalHandle);
      }
      return this.animHandle = this.timerHandle = this.intervalHandle = null;
    };

    Animator.prototype.resetTimes = function() {
      this.startMS = this.now();
      this.startTick = this.ticks;
      return this.startDraw = this.draws;
    };

    Animator.prototype.reset = function() {
      this.stop();
      return this.ticks = this.draws = 0;
    };

    Animator.prototype.step = function() {
      this.ticks++;
      return this.model.stepAndEmit();
    };

    Animator.prototype.draw = function() {
      this.draws++;
      return this.model.draw();
    };

    Animator.prototype.once = function() {
      this.step();
      return this.draw();
    };

    Animator.prototype.now = function() {
      return (typeof performance !== "undefined" && performance !== null ? performance : Date).now();
    };

    Animator.prototype.ms = function() {
      return this.now() - this.startMS;
    };

    Animator.prototype.ticksPerSec = function() {
      var dt;
      if ((dt = this.ticks - this.startTick) === 0) {
        return 0;
      } else {
        return Math.round(dt * 1000 / this.ms());
      }
    };

    Animator.prototype.drawsPerSec = function() {
      var dt;
      if ((dt = this.draws - this.startDraw) === 0) {
        return 0;
      } else {
        return Math.round(dt * 1000 / this.ms());
      }
    };

    Animator.prototype.toString = function() {
      return "ticks: " + this.ticks + ", draws: " + this.draws + ", rate: " + this.rate + " tps/dps: " + (this.ticksPerSec()) + "/" + (this.drawsPerSec());
    };

    Animator.prototype.animateSteps = function() {
      this.step();
      if (!this.stopped) {
        return this.timeoutHandle = setTimeout(this.animateSteps, 10);
      }
    };

    Animator.prototype.animateDraws = function() {
      if (this.drawsPerSec() < this.rate) {
        if (!this.multiStep) {
          this.step();
        }
        this.draw();
      }
      if (!this.stopped) {
        return this.animHandle = requestAnimationFrame(this.animateDraws);
      }
    };

    Animator.prototype.animate = function() {
      if (this.multiStep) {
        this.animateSteps();
      }
      return this.animateDraws();
    };

    return Animator;

  })();

}).call(this);
