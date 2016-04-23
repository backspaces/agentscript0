(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  ABM.NLMouse = (function() {
    function NLMouse(model, callback) {
      this.model = model;
      this.callback = callback;
      this.handleMouseMove = bind(this.handleMouseMove, this);
      this.handleMouseUp = bind(this.handleMouseUp, this);
      this.handleMouseDown = bind(this.handleMouseDown, this);
      this.div = this.model.div;
      this.start();
    }

    NLMouse.prototype.resetParams = function() {
      this.x = this.y = NaN;
      return this.moved = this.down = false;
    };

    NLMouse.prototype.start = function() {
      this.div.addEventListener("mousedown", this.handleMouseDown, false);
      document.body.addEventListener("mouseup", this.handleMouseUp, false);
      this.div.addEventListener("mousemove", this.handleMouseMove, false);
      return this.resetParams();
    };

    NLMouse.prototype.stop = function() {
      this.div.removeEventListener("mousedown", this.handleMouseDown, false);
      document.body.removeEventListener("mouseup", this.handleMouseUp, false);
      this.div.removeEventListener("mousemove", this.handleMouseMove, false);
      return this.resetParams();
    };

    NLMouse.prototype.generalHandler = function(e, down, moved) {
      this.down = down;
      this.moved = moved;
      this.setXY(e);
      if (this.callback != null) {
        return this.callback(e);
      }
    };

    NLMouse.prototype.handleMouseDown = function(e) {
      return this.generalHandler(e, true, false);
    };

    NLMouse.prototype.handleMouseUp = function(e) {
      return this.generalHandler(e, false, false);
    };

    NLMouse.prototype.handleMouseMove = function(e) {
      return this.generalHandler(e, this.down, true);
    };

    NLMouse.prototype.setXY = function(e) {
      var pixX, pixY, rect, ref;
      rect = this.div.getBoundingClientRect();
      pixX = e.clientX - rect.left;
      pixY = e.clientY - rect.top;
      return ref = this.model.patches.pixelXYtoPatchXY(pixX, pixY), this.x = ref[0], this.y = ref[1], ref;
    };

    return NLMouse;

  })();

}).call(this);
