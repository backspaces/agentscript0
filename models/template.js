(function() {
  var Maps, MyModel, Shapes, log, model, u,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  u = ABM.Util;

  Shapes = ABM.Shapes;

  Maps = ABM.ColorMaps;

  log = function(arg) {
    return console.log(arg);
  };

  MyModel = (function(superClass) {
    extend(MyModel, superClass);

    function MyModel() {
      return MyModel.__super__.constructor.apply(this, arguments);
    }

    MyModel.prototype.startup = function() {
      Shapes.add("bowtie", true, function(c) {
        return Shapes.poly(c, [[-.5, -.5], [.5, .5], [-.5, .5], [.5, -.5]]);
      });
      if (window.location.protocol === "file:") {
        console.log("Warning: file:// protocol used!");
        console.log("This prevents two user defined image shapes from loading!");
        return console.log("Use http:// protocol to enable image shapes.");
      } else {
        Shapes.add("cc", true, u.importImage("data/coffee.png"));
        return Shapes.add("redfish", false, u.importImage("data/redfish64t.png"));
      }
    };

    MyModel.prototype.setup = function() {
      var a, i, j, k, len, len1, len2, num, p, ref, ref1, ref2, s;
      this.population = 100;
      this.size = 1.5;
      this.speed = .5;
      this.wiggle = u.degToRad(30);
      this.startCircle = true;
      this.agents.setDefault("size", this.size);
      this.agents.setUseSprites();
      this.anim.setRate(30, false);
      ref = this.patches;
      for (i = 0, len = ref.length; i < len; i++) {
        p = ref[i];
        p.color = Maps.randomGray(0, 100);
        if (p.x === 0 || p.y === 0) {
          p.color = "blue";
        }
      }
      ref1 = this.agents.create(this.population);
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        a = ref1[j];
        a.shape = u.oneOf(Shapes.names());
        if (this.startCircle) {
          a.forward(this.patches.maxX / 2);
        } else {
          a.setXY.apply(a, this.patches.randomPt());
        }
      }
      log("total agents: " + this.agents.length + ", total patches: " + this.patches.length);
      ref2 = Shapes.names();
      for (k = 0, len2 = ref2.length; k < len2; k++) {
        s = ref2[k];
        num = this.agents.getPropWith("shape", s).length;
        log(num + " " + s);
      }
      return console.log("Patch(0,0): ", this.patches.patchXY(0, 0));
    };

    MyModel.prototype.step = function() {
      var a, i, j, len, len1, p, ref, ref1;
      ref = this.agents;
      for (i = 0, len = ref.length; i < len; i++) {
        a = ref[i];
        this.updateAgents(a);
      }
      if (this.anim.ticks % 100 === 0) {
        ref1 = this.patches;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          p = ref1[j];
          this.updatePatches(p);
        }
        this.reportInfo();
        this.refreshPatches = true;
        if (this.anim.ticks === 300) {
          this.setSpotlight(this.agents.oneOf());
        }
        if (this.anim.ticks === 600) {
          this.setSpotlight(null);
        }
      } else {
        this.refreshPatches = false;
      }
      if (this.anim.draws === 2) {
        this.showSpriteSheet();
      }
      if (this.anim.ticks % 100 === 0) {
        log(this.anim.toString());
      }
      if (this.anim.ticks === 1000) {
        log("..stopping, restart by app.start()");
        return this.stop();
      }
    };

    MyModel.prototype.updateAgents = function(a) {
      a.rotate(u.randomCentered(this.wiggle));
      return a.forward(this.speed);
    };

    MyModel.prototype.updatePatches = function(p) {
      if (p.x !== 0 && p.y !== 0) {
        return p.color = Maps.randomColor();
      }
    };

    MyModel.prototype.reportInfo = function() {
      var avgHeading, headings;
      headings = this.agents.getProp("heading");
      avgHeading = (headings.reduce(function(a, b) {
        return a + b;
      })) / this.agents.length;
      return log("average heading of agents: " + (avgHeading.toFixed(2)) + " radians, " + (u.radToDeg(avgHeading).toFixed(2)) + " degrees");
    };

    return MyModel;

  })(ABM.Model);

  model = new MyModel({
    div: "layers",
    size: 13,
    minX: -16,
    maxX: 16,
    minY: -16,
    maxY: 16,
    isTorus: true,
    hasNeighbors: false
  }).debug().start();

}).call(this);
