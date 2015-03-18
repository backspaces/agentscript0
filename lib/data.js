(function() {
  var AscDataSet, DataSet, ImageDataSet, PatchDataSet, u,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  u = ABM.Util;

  ABM.DataSet = DataSet = (function() {
    DataSet.patchDataSet = function(f) {
      return new PatchDataSet(f);
    };

    DataSet.importImageDataSet = function(name, f, format, arrayType, rowsPerSlice) {
      var ds;
      if (format == null) {
        format = u.pixelByte(0);
      }
      if (arrayType == null) {
        arrayType = Uint8ClampedArray;
      }
      ds = new ImageDataSet(null, format, arrayType, rowsPerSlice);
      u.importImage(name, function(img) {
        ds.parse(img);
        if (f != null) {
          return f(ds);
        }
      });
      return ds;
    };

    DataSet.importAscDataSet = function(name, f) {
      var ds;
      ds = new AscDataSet();
      u.xhrLoadFile(name, "GET", "text", function(response) {
        ds.parse(response);
        if (f != null) {
          return f(ds);
        }
      });
      return ds;
    };

    function DataSet(width, height, data, model) {
      if (width == null) {
        width = 0;
      }
      if (height == null) {
        height = 0;
      }
      if (data == null) {
        data = [];
      }
      this.model = model;
      this.setDefaults();
      this.reset(width, height, data);
    }

    DataSet.prototype.reset = function(width, height, data) {
      this.width = width;
      this.height = height;
      this.data = data;
      if (data.length !== width * height) {
        u.error("DataSet: data array length error:\ndata.length: " + this.data.length + " width: " + this.width + " height: " + this.height);
      }
      return this;
    };

    DataSet.prototype.checkXY = function(x, y) {
      if (!((0 <= x && x <= this.width - 1) && (0 <= y && y <= this.height - 1))) {
        return u.error("x,y out of range: " + x + "," + y);
      }
    };

    DataSet.prototype.setDefaults = function() {
      this.useNearest = false;
      this.crop = false;
      this.normalizeImage = true;
      this.alpha = 255;
      return this.gray = true;
    };

    DataSet.prototype.setSampler = function(useNearest) {
      this.useNearest = useNearest;
    };

    DataSet.prototype.setConvolveCrop = function(crop) {
      this.crop = crop;
    };

    DataSet.prototype.setImageNormalize = function(normalizeImage) {
      this.normalizeImage = normalizeImage;
    };

    DataSet.prototype.setImageAlpha = function(alpha) {
      this.alpha = alpha;
    };

    DataSet.prototype.setImageGray = function(gray) {
      this.gray = gray;
    };

    DataSet.prototype.setModel = function(model) {
      this.model = model;
    };

    DataSet.prototype.sample = function(x, y) {
      if (this.useNearest) {
        return this.nearest(x, y);
      } else {
        return this.bilinear(x, y);
      }
    };

    DataSet.prototype.nearest = function(x, y) {
      return this.getXY(Math.round(x), Math.round(y));
    };

    DataSet.prototype.bilinear = function(x, y) {
      var dx, dy, f00, f01, f10, f11, i, w, x0, y0, _ref, _ref1, _ref2;
      this.checkXY(x, y);
      x0 = Math.floor(x);
      y0 = Math.floor(y);
      i = this.toIndex(x0, y0);
      w = this.width;
      x = x - x0;
      y = y - y0;
      dx = 1 - x;
      dy = 1 - y;
      f00 = this.data[i];
      f01 = (_ref = this.data[i + w]) != null ? _ref : 0;
      f10 = (_ref1 = this.data[++i]) != null ? _ref1 : 0;
      f11 = (_ref2 = this.data[i + w]) != null ? _ref2 : 0;
      return f00 * dx * dy + f10 * x * dy + f01 * dx * y + f11 * x * y;
    };

    DataSet.prototype.toIndex = function(x, y) {
      return x + y * this.width;
    };

    DataSet.prototype.toXY = function(i) {
      return [i % this.width, Math.floor(i / this.width)];
    };

    DataSet.prototype.getXY = function(x, y) {
      this.checkXY(x, y);
      return this.data[this.toIndex(x, y)];
    };

    DataSet.prototype.setXY = function(x, y, num) {
      this.checkXY(x, y);
      return this.data[this.toIndex(x, y)] = num;
    };

    DataSet.prototype.toString = function(p, sep) {
      var data, i, s, _i, _ref;
      if (p == null) {
        p = 2;
      }
      if (sep == null) {
        sep = ", ";
      }
      s = "width: " + this.width + " height: " + this.height + " data:";
      data = p < 0 ? this.data : u.aToFixed(this.data, p);
      for (i = _i = 0, _ref = this.height; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        s += "\n" + ("" + i + ": " + (data.slice(i * this.width, (i + 1) * this.width)));
      }
      return s.replace(/,/g, sep);
    };

    DataSet.prototype.toImage = function() {
      return this.toContext().canvas;
    };

    DataSet.prototype.toContext = function() {
      var ctx, d, data, i, idata, j, num, ta, _i, _len;
      ctx = u.createCtx(this.width, this.height);
      idata = ctx.getImageData(0, 0, this.width, this.height);
      ta = idata.data;
      if (this.normalizeImage) {
        data = this.gray ? u.normalize8(this.data) : u.normalizeInt(this.data, 0, Math.pow(2, 24) - 1);
      } else {
        data = (function() {
          var _i, _len, _ref, _results;
          _ref = this.data;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            d = _ref[_i];
            _results.push(Math.round(d));
          }
          return _results;
        }).call(this);
      }
      for (i = _i = 0, _len = data.length; _i < _len; i = ++_i) {
        num = data[i];
        j = 4 * i;
        if (this.gray) {
          ta[j] = ta[j + 1] = ta[j + 2] = Math.floor(num);
          ta[j + 3] = this.alpha;
        } else {
          ta[j] = (num >> 16) & 0xff;
          ta[j + 1] = (num >> 8) & 0xff;
          ta[j + 2] = num & 0xff;
          ta[j + 3] = this.normalizeImage ? this.alpha : ta[j + 3] = (num >> 24) & 0xff;
        }
      }
      ctx.putImageData(idata, 0, 0);
      return ctx;
    };

    DataSet.prototype.toDataUrl = function() {
      return u.ctxToDataUrl(this.toContext());
    };

    DataSet.prototype.toDrawing = function(model) {
      var img;
      if (model == null) {
        model = this.model;
      }
      model.patches.installDrawing(img = this.toImage());
      return img;
    };

    DataSet.prototype.toPatchColors = function(model) {
      var img;
      if (model == null) {
        model = this.model;
      }
      model.patches.installColors(img = this.toImage());
      return img;
    };

    DataSet.prototype.toPatchVar = function(name, model) {
      var i, p, ps, _i, _j, _len, _len1;
      if (model == null) {
        model = this.model;
      }
      if ((ps = model.patches).length === this.data.length) {
        for (i = _i = 0, _len = ps.length; _i < _len; i = ++_i) {
          p = ps[i];
          p[name] = this.data[i];
        }
      } else {
        for (_j = 0, _len1 = ps.length; _j < _len1; _j++) {
          p = ps[_j];
          p[name] = this.patchSample(p.x, p.y, model);
        }
      }
      return null;
    };

    DataSet.prototype.coordSample = function(x, y, tlx, tly, w, h) {
      var xs, ys;
      xs = (x - tlx) * (this.width - 1) / w;
      ys = (tly - y) * (this.height - 1) / h;
      return this.sample(xs, ys);
    };

    DataSet.prototype.patchSample = function(px, py, model) {
      var w;
      if (model == null) {
        model = this.model;
      }
      w = model.world;
      return this.coordSample(px, py, w.minXcor, w.maxYcor, w.numX, w.numY);
    };

    DataSet.prototype.normalize = function(lo, hi) {
      return new DataSet(this.width, this.height, u.normalize(this.data, lo, hi), this.model);
    };

    DataSet.prototype.normalize8 = function() {
      return new DataSet(this.width, this.height, u.normalize8(this.data), this.model);
    };

    DataSet.prototype.resample = function(width, height) {
      var data, x, xScale, xs, y, yScale, ys, _i, _j;
      if (width === this.width && height === this.height) {
        return new DataSet(width, height, this.data, this.model);
      }
      data = [];
      xScale = (this.width - 1) / (width - 1);
      yScale = (this.height - 1) / (height - 1);
      for (y = _i = 0; _i < height; y = _i += 1) {
        for (x = _j = 0; _j < width; x = _j += 1) {
          xs = x * xScale;
          ys = y * yScale;
          data.push(this.sample(xs, ys));
        }
      }
      return new DataSet(width, height, data, this.model);
    };

    DataSet.prototype.neighborhood = function(x, y, array) {
      var dx, dy, x0, y0, _i, _j;
      if (array == null) {
        array = [];
      }
      array.length = 0;
      for (dy = _i = -1; _i <= 1; dy = ++_i) {
        for (dx = _j = -1; _j <= 1; dx = ++_j) {
          x0 = u.clamp(x + dx, 0, this.width - 1);
          y0 = u.clamp(y + dy, 0, this.height - 1);
          array.push(this.data[this.toIndex(x0, y0)]);
        }
      }
      return array;
    };

    DataSet.prototype.convolve = function(kernel, factor) {
      var array, h, n, w, x, x0, y, y0, _i, _j;
      if (factor == null) {
        factor = 1;
      }
      array = [];
      n = [];
      if (this.crop) {
        x0 = y0 = 1;
        h = this.height - 1;
        w = this.width - 1;
      } else {
        x0 = y0 = 0;
        h = this.height;
        w = this.width;
      }
      for (y = _i = y0; _i < h; y = _i += 1) {
        for (x = _j = x0; _j < w; x = _j += 1) {
          this.neighborhood(x, y, n);
          array.push(u.aSum(u.aPairMul(kernel, n)) * factor);
        }
      }
      return new DataSet(w - x0, h - y0, array, this.model);
    };

    DataSet.prototype.dzdx = function(n, factor) {
      if (n == null) {
        n = 2;
      }
      if (factor == null) {
        factor = 1 / 8;
      }
      return this.convolve([-1, 0, 1, -n, 0, n, -1, 0, 1], factor);
    };

    DataSet.prototype.dzdy = function(n, factor) {
      if (n == null) {
        n = 2;
      }
      if (factor == null) {
        factor = 1 / 8;
      }
      return this.convolve([1, n, 1, 0, 0, 0, -1, -n, -1], factor);
    };

    DataSet.prototype.laplace8 = function() {
      return this.convolve([-1, -1, -1, -1, 8, -1, -1, -1, -1]);
    };

    DataSet.prototype.laplace4 = function() {
      return this.convolve([0, -1, 0, -1, 4, -1, 0, -1, 0]);
    };

    DataSet.prototype.blur = function(factor) {
      if (factor == null) {
        factor = 0.0625;
      }
      return this.convolve([1, 2, 1, 2, 4, 2, 1, 2, 1], factor);
    };

    DataSet.prototype.edge = function() {
      return this.convolve([1, 1, 1, 1, -7, 1, 1, 1, 1]);
    };

    DataSet.prototype.filter = function(f) {
      var d;
      return new DataSet(this.width, this.height, (function() {
        var _i, _len, _ref, _results;
        _ref = this.data;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          d = _ref[_i];
          _results.push(f(d));
        }
        return _results;
      }).call(this), this.model);
    };

    DataSet.prototype.slopeAndAspect = function(noNaNs, posAngle) {
      var aspect, dzdx, dzdy, gx, gy, h, rad, slope, w, x, y, _i, _j;
      if (noNaNs == null) {
        noNaNs = true;
      }
      if (posAngle == null) {
        posAngle = true;
      }
      dzdx = this.dzdx();
      dzdy = this.dzdy();
      aspect = [];
      slope = [];
      h = dzdx.height;
      w = dzdx.width;
      for (y = _i = 0; _i < h; y = _i += 1) {
        for (x = _j = 0; _j < w; x = _j += 1) {
          gx = dzdx.getXY(x, y);
          gy = dzdy.getXY(x, y);
          slope.push(Math.atan(Math.sqrt(gx * gx + gy * gy)));
          while (noNaNs && gx === gy) {
            gx += u.randomNormal(0, .0001);
            gy += u.randomNormal(0, .0001);
          }
          rad = (gx === gy && gy === 0) ? NaN : Math.atan2(-gy, -gx);
          if (posAngle && rad < 0) {
            rad += 2 * Math.PI;
          }
          aspect.push(rad);
        }
      }
      slope = new DataSet(w, h, slope, this.model);
      aspect = new DataSet(w, h, aspect, this.model);
      return u.aToObj([slope, aspect, dzdx, dzdy], ["slope", "aspect", "dzdx", "dzdy"]);
    };

    DataSet.prototype.subset = function(x, y, width, height) {
      var data, i, j, _i, _j, _ref, _ref1;
      if (x + width > this.width || y + height > this.height) {
        u.error("subSet: params out of range");
      }
      data = [];
      for (j = _i = y, _ref = y + height; _i < _ref; j = _i += 1) {
        for (i = _j = x, _ref1 = x + width; _j < _ref1; i = _j += 1) {
          data.push(this.getXY(i, j));
        }
      }
      return new DataSet(width, height, data, this.model);
    };

    return DataSet;

  })();

  ABM.AscDataSet = AscDataSet = (function(_super) {
    __extends(AscDataSet, _super);

    function AscDataSet(str, model) {
      this.str = str != null ? str : "";
      this.model = model;
      AscDataSet.__super__.constructor.call(this);
      if (this.str.length === 0) {
        return;
      }
      this.parse(this.str);
    }

    AscDataSet.prototype.parse = function(str) {
      var i, keyVal, nums, textData, _i, _j, _k, _ref, _ref1;
      this.str = str;
      textData = str.split("\n");
      this.header = {};
      for (i = _i = 0; _i <= 5; i = ++_i) {
        keyVal = textData[i].split(/\s+/);
        this.header[keyVal[0].toLowerCase()] = parseFloat(keyVal[1]);
      }
      for (i = _j = 0, _ref = this.header.nrows; _j < _ref; i = _j += 1) {
        nums = textData[6 + i].trim().split(" ");
        for (i = _k = 0, _ref1 = nums.length; 0 <= _ref1 ? _k < _ref1 : _k > _ref1; i = 0 <= _ref1 ? ++_k : --_k) {
          nums[i] = parseFloat(nums[i]);
        }
        this.data = this.data.concat(nums);
      }
      return this.reset(this.header.ncols, this.header.nrows, this.data);
    };

    return AscDataSet;

  })(DataSet);

  ABM.ImageDataSet = ImageDataSet = (function(_super) {
    __extends(ImageDataSet, _super);

    function ImageDataSet(img, f, arrayType, rowsPerSlice, model) {
      this.f = f != null ? f : u.pixelByte(0);
      this.arrayType = arrayType != null ? arrayType : Uint8ClampedArray;
      this.rowsPerSlice = rowsPerSlice;
      this.model = model;
      ImageDataSet.__super__.constructor.call(this);
      if (img == null) {
        return;
      }
      this.parse(img);
    }

    ImageDataSet.prototype.parse = function(img) {
      var data;
      this.rowsPerSlice || (this.rowsPerSlice = img.height);
      data = u.imageRowsToData(img, this.rowsPerSlice, this.f, this.arrayType);
      return this.reset(img.width, img.height, data);
    };

    return ImageDataSet;

  })(DataSet);

  ABM.PatchDataSet = PatchDataSet = (function(_super) {
    __extends(PatchDataSet, _super);

    function PatchDataSet(f, arrayType, model) {
      var data, i, p, ps, _i, _len;
      if (arrayType == null) {
        arrayType = Array;
      }
      this.model = model;
      data = new arrayType((ps = this.model.patches).length);
      if (u.isString(f)) {
        f = u.propFcn(f);
      }
      for (i = _i = 0, _len = ps.length; _i < _len; i = ++_i) {
        p = ps[i];
        data[i] = f(p);
      }
      PatchDataSet.__super__.constructor.call(this, ps.numX, ps.numY, data);
      this.useNearest = true;
    }

    PatchDataSet.prototype.toPatchVar = function(name) {
      var i, p, _i, _len, _ref;
      _ref = this.model.patches;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        p = _ref[i];
        p[name] = this.data[i];
      }
      return null;
    };

    return PatchDataSet;

  })(DataSet);

}).call(this);
