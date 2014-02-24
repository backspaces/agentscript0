//  ABM.DatGUI creates a minimal user interface for
//  an ABM.Model using dat.gui.
//
//  (requires [dat.gui.js](http://workshop.chromeexperiments.com/examples/gui/))

(function() {
  ABM.DatGUI = (function() {
    
    //  The constructor accepts either
    //  1. an [ABM.FirebaseUI](fbui.html) or
    //  2. an ABM.Model and a ui object, like:  
    //          {
    //            "Setup": {
    //              type: "button",
    //              setter: "setup"
    //            },
    //            "Background": {
    //              type: "choice",
    //              vals: ["image","aspect","slope"],
    //              val: "image",
    //              setter: "setBackground"
    //            },
    //            "Neighborhood": {
    //              type: "slider",
    //              min: 1,
    //              max: 10,
    //              step: 1,
    //              val: 3,
    //              smooth: false,
    //              setter: "setNeighborRadius"
    //            },
    //            "refreshLinks": {
    //              type: "switch",
    //              val: true
    //            }
    //          }

    // If you pass in a FirebaseUI object, all instances of
    // the model interface in all browsers will be in sync.

    // TODO: Allow a subset of ui elements to remain in sync.

    function DatGUI(fbuiOrModel, uiObject) {

      var self = this;
      this.gui = new dat.GUI();
      this.datGuiModel = {};

      var model, ui, fbui;
      if (arguments.length == 2) {
        model = this.model = fbuiOrModel;
        ui = this.ui = uiObject;
      }
      else {
        fbui = this.fbui = fbuiOrModel;
        ui = this.ui = fbui.ui;
      }

      for (var name in ui) {
        if (ui.hasOwnProperty(name)) {
          var uiEl = ui[name];
          if (uiEl.type != 'button') {
            this.datGuiModel[name] = uiEl.val;

            fbui && fbui.refs[name].child('val').on('value', function(valSnap) {
              self.datGuiModel[this.name] = valSnap.val();
              self.updateGui();
            }.bind({ name: name }));
          }

          var ctrl = null;
          // a uiEl can be of type "button", "choice", "switch", or "slider"
          switch(uiEl.type) {
            case 'button':
              this.datGuiModel[name] = self.fbui ?
                function() { self.fbui.setUIValue(name, true); } :
                function() { self.setModelValue(name); };
              this.gui.add(this.datGuiModel, name);
            break;
            case 'choice':
              ctrl = this.gui.add(this.datGuiModel, name, uiEl.vals);
            break;
            case 'switch':
              ctrl = this.gui.add(this.datGuiModel, name);
            break;
            case 'slider':
              ctrl = this.gui.add(this.datGuiModel, name, uiEl.min, uiEl.max).step(uiEl.step);
            break;
          }
          if (ctrl) {
            var callback;
            if (self.fbui) {
              callback = function(value) {
                self.fbui.setUIValue(this.name, value);
              }.bind({ name: name });
            }
            else {
              callback = function(value) {
                self.setModelValue(this.name, value);
              }.bind({ name: name }); 
            }
            // a slider can be 'smooth', in which case
            // the setter is called during a drag
            if (uiEl.smooth) {
              ctrl.onChange(callback);
            }
            // otherwise the setter is called at the end
            // of the drag
            else {
              ctrl.onFinishChange(callback);
            }
          }
        }
      }
    }

    DatGUI.prototype.setModelValue = function(name, value) {
      var setter = this.ui[name].setter;
      // if you specify a setter, DatGUI will look for
      // it in the model and call it with the new value
      if (setter) {
        this.model[setter](value);
      }
      // otherwise we assume the ui element name is
      // the name of a model variable
      else {
        this.model[name] = value;
      }
    }

    DatGUI.prototype.updateGui = function() {
      for (var i in this.gui.__controllers) {
        this.gui.__controllers[i].updateDisplay();
      }
    }
        
    return DatGUI;

  })();

}).call(this);