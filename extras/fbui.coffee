# FirebaseUI is a distributed UI manager via Firebase.com's JSON technology.
# Our UI via Firebase is "alpha" at this point and uses the NetLogo design.
class ABM.FirebaseUI
  # Create UI object via Firebase url, the model, and a json UI tree:
  #
  #     uiData:
  #       go:          type:"button", setter:"toggle", val: false
  #       background:  type:"choice", vals: ["black","red","random"], val: "red"
  #       useConsole:  type:"switch", val: true
  #       population:  type:"slider", min:25,  step:25,  max:1000, val:500
  #       filename:    type:"input",  val:"test.png"
  #       result:      type:"output"  val: json
  #       vision:
  #         type:"slider", setter:"setVision", min:.5, step:.5, max:10, val:3
  #
  # Rules:
  #
  # * Each ui element is a name/object pair
  # * If the ui object has a setter, it is called with the current value: model.name(val)
  # * If not, its name is a property, which is set to the value: model.name = val
  # * If the ui object is a button, it is a boolean which must have a setter
  # * The button's setter is called on the false -> true transition
  
  constructor: (@fbname, @model, @ui) ->
    @fb = new Firebase @fbname
    @refs = {}; @refs[k] = @fb.child(k) for k,v of @ui
    @vals = {}; @vals[k] = v.val for k,v of @ui
    @resetModel()
    @fb.set @ui, (val)->console.log if val? then "FB error: #{val}" else "FB ready"
    @fb.on 'child_changed', (snapshot) =>
      console.log "childChange", snapshot.name(), snapshot.val().val
      @setModelValue snapshot.name(), snapshot.val().val
    console.log "--- Firebase setup"
  # Use the json tree to set the model's instance variables
  setModelValue: (name, value) ->
    console.log "setModelValue: #{name}, #{value}"
    @vals[name] = value
    if @ui[name].type is "button"
      if value then @setUIValue name, false else return
    if (setter=@ui[name].setter)? then @model[setter](value) else @model[name]=value
  # Set the Firebase json value 
  setUIValue: (name, value, push=false) ->
    console.log "setUIValue: #{name}, #{value}, #{push}"
    # @refs[name].child('val').set(value)
    @refs[name].child('val')[if push then "push" else "set"](value)
  # Get the current UI value for the given model property
  getUIValue: (name) -> @vals[name] # last value from callback
  # Reset the model instance variables to initial json tree.
  # Useful for resetting the model back to its defaults.
  resetModel: ->
    @setModelValue k, v.val for k,v of @ui when v.type isnt "button"
  # Reset the Firebase json tree to initial ui object's values.
  # Will cause FB events for those values that differ from initial values.
  resetUI: ->
    @setUIValue k, v.val for k,v of @ui when v.type isnt "button"
