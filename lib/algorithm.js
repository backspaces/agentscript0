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
      var asetNext, i, j, k, len, len1, len2, n, p, ref, ref1, ref2;
      if (this.done) {
        return;
      }
      ref = this.nextFront;
      for (i = 0, len = ref.length; i < len; i++) {
        p = ref[i];
        this.fJoin(p, this.prevFront);
      }
      asetNext = [];
      ref1 = this.nextFront;
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        p = ref1[j];
        ref2 = this.fNeighbors(p);
        for (k = 0, len2 = ref2.length; k < len2; k++) {
          n = ref2[k];
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
      var results;
      results = [];
      while (!this.done) {
        results.push(this.nextStep());
      }
      return results;
    };

    return FloodFill;

  })();

}).call(this);
