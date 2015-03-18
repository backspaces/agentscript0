(function() {
  var u,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  u = ABM.util;

  ABM.Mouse = (function() {
    function Mouse(model, callback) {
      this.model = model;
      this.callback = callback;
      this.delegateMouseOverAndOutEvents = __bind(this.delegateMouseOverAndOutEvents, this);
      this.delegateDragEvents = __bind(this.delegateDragEvents, this);
      this.computeEventTypes = __bind(this.computeEventTypes, this);
      this.handleMouseEvent = __bind(this.handleMouseEvent, this);
      this.handleStep = __bind(this.handleStep, this);
      this.handleMouseMove = __bind(this.handleMouseMove, this);
      this.handleMouseUp = __bind(this.handleMouseUp, this);
      this.handleMouseDown = __bind(this.handleMouseDown, this);
      this.lastX = Infinity;
      this.lastY = Infinity;
      this.div = this.model.div;
      this.lastAgentsHovered = [];
      this.draggingAgents = [];
      this.divOffset = this.model.div.getBoundingClientRect();
      this.start();
    }

    Mouse.prototype.start = function() {
      this.div.addEventListener("mousedown", this.handleMouseDown, false);
      document.body.addEventListener("mouseup", this.handleMouseUp, false);
      this.div.addEventListener("mousemove", this.handleMouseMove, false);
      this.model.on('step', this.handleStep);
      this.lastX = this.lastY = this.x = this.y = this.pixX = this.pixY = NaN;
      return this.moved = this.down = false;
    };

    Mouse.prototype.stop = function() {
      this.div.removeEventListener("mousedown", this.handleMouseDown, false);
      document.body.removeEventListener("mouseup", this.handleMouseUp, false);
      this.div.removeEventListener("mousemove", this.handleMouseMove, false);
      this.model.off('step', this.handleStep);
      this.lastX = this.lastY = this.x = this.y = this.pixX = this.pixY = NaN;
      return this.moved = this.down = false;
    };

    Mouse.prototype.handleMouseDown = function(e) {
      this.down = true;
      this.moved = false;
      return this.handleMouseEvent(e);
    };

    Mouse.prototype.handleMouseUp = function(e) {
      this.down = false;
      this.moved = false;
      return this.handleMouseEvent(e);
    };

    Mouse.prototype.handleMouseMove = function(e) {
      this.setXY(e);
      this.moved = true;
      return this.handleMouseEvent(e);
    };

    Mouse.prototype.handleStep = function() {
      if (!isNaN(this.x)) {
        return this.delegateMouseOverAndOutEvents(this.x, this.y);
      }
    };

    Mouse.prototype.handleMouseEvent = function(e) {
      var eventTypes;
      eventTypes = this.computeEventTypes();
      this.delegateEventsToAllAgents(eventTypes, e);
      if (this.callback != null) {
        return this.callback(e);
      }
    };

    Mouse.prototype.getEventPos = function(e) {
      var xPos, yPos;
      xPos = 0;
      yPos = 0;
      if (e.pageX || e.pageY) {
        xPos = e.pageX;
        yPos = e.pageY;
      } else if (e.clientX || e.clientY) {
        xPos = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
        yPos = e.clientY + document.body.scrollTop + document.documentElement.scrollTop;
      }
      return {
        x: xPos - this.divOffset.left,
        y: yPos - this.divOffset.top
      };
    };

    Mouse.prototype.setXY = function(e) {
      var eventPos, _ref;
      eventPos = this.getEventPos(e);
      this.lastX = this.x;
      this.lastY = this.y;
      this.pixX = eventPos.x;
      this.pixY = eventPos.y;
      _ref = this.model.patches.pixelXYtoPatchXY(this.pixX, this.pixY), this.x = _ref[0], this.y = _ref[1];
      this.dx = this.lastX - this.x;
      return this.dy = this.lastY - this.y;
    };

    Mouse.prototype.computeEventTypes = function() {
      var eventTypes;
      eventTypes = [];
      if (this.down && !this.moved) {
        eventTypes.push('mousedown');
      }
      if (!this.down && !this.moved) {
        eventTypes.push('mouseup');
      }
      if (this.down && this.moved) {
        if (!this.dragging) {
          eventTypes.push('dragstart');
        }
        this.dragging = true;
      }
      if (!this.down && this.dragging) {
        this.dragging = false;
        this.dragEnd = true;
      }
      if (this.moved) {
        eventTypes.push('mousemove');
      }
      return eventTypes;
    };

    Mouse.prototype.delegateEventsToAllAgents = function(types, e) {
      var delegatedAgent;
      delegatedAgent = this.delegateEventsToAgentsAtPoint(types, this.x, this.y, e);
      if (!delegatedAgent) {
        delegatedAgent = this.delegateEventsToLinksAtPoint(types, this.x, this.y, e);
      }
      if (!delegatedAgent) {
        this.delegateEventsToPatchAtPoint(types, this.x, this.y, e);
      }
      this.delegateDragEvents(this.x, this.y, e);
      return this.delegateMouseOverAndOutEvents(this.x, this.y, e);
    };

    Mouse.prototype.delegateEventsToPatchAtPoint = function(eventTypes, x, y, e) {
      var curPatch, type, _i, _len, _results;
      curPatch = this.model.patches.patch(x, y);
      _results = [];
      for (_i = 0, _len = eventTypes.length; _i < _len; _i++) {
        type = eventTypes[_i];
        _results.push(this.emitAgentEvent(type, curPatch, this.mouseEvent(curPatch, e)));
      }
      return _results;
    };

    Mouse.prototype.delegateEventsToAgentsAtPoint = function(eventTypes, x, y, e) {
      var agent, curPatch, patch, type, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
      curPatch = this.model.patches.patch(x, y);
      _ref = curPatch.n.concat(curPatch);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        patch = _ref[_i];
        _ref1 = patch.agentsHere();
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          agent = _ref1[_j];
          if (agent.hitTest(x, y)) {
            for (_k = 0, _len2 = eventTypes.length; _k < _len2; _k++) {
              type = eventTypes[_k];
              this.emitAgentEvent(type, agent, this.mouseEvent(agent, e));
            }
            return agent;
          }
        }
      }
    };

    Mouse.prototype.delegateEventsToLinksAtPoint = function(eventTypes, x, y, e) {
      var link, mouseEvent, type, _i, _j, _len, _len1, _ref;
      _ref = this.model.links;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        link = _ref[_i];
        if (link.hitTest(x, y)) {
          mouseEvent = this.mouseEvent(link, e);
          for (_j = 0, _len1 = eventTypes.length; _j < _len1; _j++) {
            type = eventTypes[_j];
            this.emitAgentEvent(type, link, mouseEvent);
          }
          return link;
        }
      }
    };

    Mouse.prototype.emitAgentEvent = function(eventType, agent, mouseEvent) {
      if (eventType === 'dragstart') {
        this.draggingAgents.push(agent);
      }
      agent.breed.emit(eventType, mouseEvent);
      if (agent.breed.mainSet != null) {
        return agent.breed.mainSet.emit(eventType, mouseEvent);
      }
    };

    Mouse.prototype.delegateDragEvents = function(x, y, e) {
      var agent, mouseEvent, _i, _len, _ref;
      _ref = this.draggingAgents;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        agent = _ref[_i];
        mouseEvent = this.mouseEvent(agent, e);
        if (this.moved) {
          this.emitAgentEvent('drag', agent, mouseEvent);
        }
        if (this.dragEnd) {
          this.emitAgentEvent('dragend', agent, mouseEvent);
        }
      }
      if (this.dragEnd) {
        this.draggingAgents = [];
        return this.dragEnd = false;
      }
    };

    Mouse.prototype.delegateMouseOverAndOutEvents = function(x, y, e) {
      var agent, agentId, agents, agentsHere, breedname, curPatch, patch, _i, _j, _len, _len1, _name, _ref;
      agentsHere = {};
      agents = [];
      curPatch = this.model.patches.patch(x, y);
      agents = u.clone(this.model.links);
      _ref = curPatch.n.concat(curPatch);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        patch = _ref[_i];
        agents = agents.concat(patch.agentsHere());
      }
      for (_j = 0, _len1 = agents.length; _j < _len1; _j++) {
        agent = agents[_j];
        if (agent.hitTest(x, y)) {
          if (agentsHere[_name = agent.breed.name] == null) {
            agentsHere[_name] = {};
          }
          agentsHere[agent.breed.name][agent.id] = agent;
          if (!this.lastAgentsHovered[agent.breed.name] || !(agent.id in this.lastAgentsHovered[agent.breed.name])) {
            this.emitAgentEvent('mouseover', agent, this.mouseEvent(agent, e));
          }
        }
      }
      for (breedname in this.lastAgentsHovered) {
        for (agentId in this.lastAgentsHovered[breedname]) {
          if (!agentsHere[breedname] || !(agentId in agentsHere[breedname])) {
            agent = this.lastAgentsHovered[breedname][agentId];
            this.emitAgentEvent('mouseout', agent, this.mouseEvent(agent, e));
          }
        }
      }
      return this.lastAgentsHovered = agentsHere;
    };

    Mouse.prototype.mouseEvent = function(agent, e) {
      return {
        target: agent,
        patchX: this.x,
        patchY: this.y,
        dx: this.dx,
        dy: this.dy,
        originalEvent: e
      };
    };

    return Mouse;

  })();

}).call(this);
