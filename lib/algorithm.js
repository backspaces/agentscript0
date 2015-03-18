(function() {
  ABM.FloodFill = (function() {
    function FloodFill(startingSet, fCandidate, fJoin, fNeighbors) {
      this.fCandidate = fCandidate;
      this.fJoin = fJoin;
      this.fNeighbors = fNeighbors;
      this.nextFront = startingSet;
      this.prevFront = [];
      this.done = false;
    }

    FloodFill.prototype.nextStep = function() {
      var asetNext, n, p, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
      if (this.done) {
        return;
      }
      _ref = this.nextFront;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        this.fJoin(p, this.prevFront);
      }
      asetNext = [];
      _ref1 = this.nextFront;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        p = _ref1[_j];
        _ref2 = this.fNeighbors(p);
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          n = _ref2[_k];
          if (this.fCandidate(n, this.nextFront)) {
            if (asetNext.indexOf(n) < 0) {
              asetNext.push(n);
            }
          }
        }
      }
      this.prevFront = this.nextFront;
      this.nextFront = asetNext;
      if (this.nextFront.length === 0) {
        return this.done = true;
      }
    };

    FloodFill.prototype.go = function() {
      var _results;
      _results = [];
      while (!this.done) {
        _results.push(this.nextStep());
      }
      return _results;
    };

    return FloodFill;

  })();

}).call(this);
