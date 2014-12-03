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
      ABM.Util.mixin(this, new ABM.Evented())
      this.gui = new dat.GUI();
      this.datGuiModel = {};
      this.datGuiControllers = {};

      var model, ui, fbui;
      if (arguments.length == 2) {
        model = this.model = fbuiOrModel;
        ui = this.ui = uiObject;
      }
      else {
        fbui = this.fbui = fbuiOrModel;
        ui = this.ui = fbui.ui;
      }

      this.initUIElements(ui, this.gui);
    }

    DatGUI.prototype.initUIElements = function(ui, folder) {
      var self = this;
      for (var name in ui) {
        if (ui.hasOwnProperty(name)) {
          var uiEl = ui[name];
          
          if (isFolder(uiEl)) {
            // You can group ui elements into folders by nesting objects. E.g.:

            //     {
            //       "Moose stuff": {
            //         "Create a moose": {
            //           type: "button"
            //         },
            //         "Moose color": {
            //           type: "choice",
            //           vals: ["brown", "dark brown"]
            //         }
            //       },
            //       "Goat stuff": {
            //         "Look for a goat": {
            //           type: "button"
            //         },
            //         "Goat size": {
            //           type: "slider",
            //           min: 1,
            //           max: 9000
            //         }
            //       }
            //     }

            // Element names should still be unique across folders.

            var subFolder = folder.addFolder(name);
            this.initUIElements(uiEl, subFolder);
            continue;
          }
          
          if (uiEl.type != 'button') {
            // The state of all non-button elements is stored in `this.datGuiModel`.
            this.datGuiModel[name] = uiEl.val;

            if (typeof fbui != 'undefined') {
              fbui.refs[name].child('val').on('value', function(valSnap) {
                self.datGuiModel[this.name] = valSnap.val();
                self.updateGui();
              }.bind({ name: name }));
            }
          }

          var ctrl = null;
          // A uiEl can be of type `"button"`, `"choice"`, `"switch"`, or `"slider"`.
          switch(uiEl.type) {
            case 'button':
              this.datGuiModel[name] = self.fbui ?
                function() { 
                  self.fbui.setUIValue(this.name, true); 
                }.bind({ name: name }) :
                function() {
                  self.setModelValue(this.name, null, this.setter);
                }.bind({ name: name, setter: ui[name].setter });
              folder.add(this.datGuiModel, name);
            break;
            case 'choice':
              ctrl = folder.add(this.datGuiModel, name, uiEl.vals);
            break;
            case 'switch':
              ctrl = folder.add(this.datGuiModel, name);
            break;
            case 'slider':
              ctrl = folder.add(this.datGuiModel, name, uiEl.min, uiEl.max).step(uiEl.step);
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
                self.setModelValue(this.name, value, this.setter);
              }.bind({ name: name, setter: ui[name].setter });
            }
            // A slider can be `"smooth"`, in which case
            // the setter is called during a drag.
            if (uiEl.smooth) {
              ctrl.onChange(callback);
            }
            // Otherwise, the setter is called at the end
            // of the drag.
            else {
              ctrl.onFinishChange(callback);
            }
            this.datGuiControllers[name] = ctrl;
          }
        }
      }
    }

    DatGUI.prototype.setModelValue = function(name, value, setter) {
      if (setter) {
        this.model[setter](value);
      }
      // If you don't specify a setter, we assume the ui element name is
      // the name of a model variable.
      else {
        this.model[name] = value;
      }
      // ABM.DatGUI will emit a `'change'` event
      // whenever part of its model changes.
      this.emit('change', { name: name, value: value });
    }

    // Use `update` to set the current state of the UI. E.g.:
    DatGUI.prototype.update = function(uiObject) {
      //     myUI.update({
      //       "Moose color": "brown",
      //       "Goat size": 500
      //     })
      for (var name in uiObject) {
        var curCtrl = this.datGuiControllers[name];
        if (curCtrl) {
          curCtrl.setValue(uiObject[name]);
          var changeFun = curCtrl.__onChange || curCtrl.__onFinishChange;
          changeFun(this.datGuiModel[name]);
        }
      }
    }

    DatGUI.prototype.updateGui = function() {
      for (var i in this.gui.__controllers) {
        this.gui.__controllers[i].updateDisplay();
      }
    }

    function isFolder(obj) {
      return typeof obj.type == 'undefined';
    }
        
    return DatGUI;

  })();

}).call(this);