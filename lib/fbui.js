(function() {
  ABM.FirebaseUI = (function() {
    function FirebaseUI(fbname, model, ui) {
      var k, ref, ref1, v;
      this.fbname = fbname;
      this.model = model;
      this.ui = ui;
      this.fb = new Firebase(this.fbname);
      this.refs = {};
      ref = this.ui;
      for (k in ref) {
        v = ref[k];
        this.refs[k] = this.fb.child(k);
      }
      this.vals = {};
      ref1 = this.ui;
      for (k in ref1) {
        v = ref1[k];
        this.vals[k] = v.val;
      }
      this.resetModel();
      this.fb.set(this.ui, function(val) {
        return console.log(val != null ? "FB error: " + val : "FB ready");
      });
      this.fb.on('child_changed', (function(_this) {
        return function(snapshot) {
          console.log("childChange", snapshot.name(), snapshot.val().val);
          return _this.setModelValue(snapshot.name(), snapshot.val().val);
        };
      })(this));
      console.log("--- Firebase setup");
    }

    FirebaseUI.prototype.setModelValue = function(name, value) {
      var setter;
      console.log("setModelValue: " + name + ", " + value);
      this.vals[name] = value;
      if (this.ui[name].type === "button") {
        if (value) {
          this.setUIValue(name, false);
        } else {
          return;
        }
      }
      if ((setter = this.ui[name].setter) != null) {
        return this.model[setter](value);
      } else {
        return this.model[name] = value;
      }
    };

    FirebaseUI.prototype.setUIValue = function(name, value, push) {
      if (push == null) {
        push = false;
      }
      console.log("setUIValue: " + name + ", " + value + ", " + push);
      return this.refs[name].child('val')[push ? "push" : "set"](value);
    };

    FirebaseUI.prototype.getUIValue = function(name) {
      return this.vals[name];
    };

    FirebaseUI.prototype.resetModel = function() {
      var k, ref, results, v;
      ref = this.ui;
      results = [];
      for (k in ref) {
        v = ref[k];
        if (v.type !== "button") {
          results.push(this.setModelValue(k, v.val));
        }
      }
      return results;
    };

    FirebaseUI.prototype.resetUI = function() {
      var k, ref, results, v;
      ref = this.ui;
      results = [];
      for (k in ref) {
        v = ref[k];
        if (v.type !== "button") {
          results.push(this.setUIValue(k, v.val));
        }
      }
      return results;
    };

    return FirebaseUI;

  })();

}).call(this);
