(function() {
  var u,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  u = ABM.util;

  ABM.Mouse = (function() {
    function Mouse(model, callback) {
      this.model = model;
      this.callback = callback;
      this.delegateMouseOverAndOutEvents = bind(this.delegateMouseOverAndOutEvents, this);
      this.delegateDragEvents = bind(this.delegateDragEvents, this);
      this.computeEventTypes = bind(this.computeEventTypes, this);
      this.handleMouseEvent = bind(this.handleMouseEvent, this);
      this.handleStep = bind(this.handleStep, this);
      this.handleMouseMove = bind(this.handleMouseMove, this);
      this.handleMouseUp = bind(this.handleMouseUp, this);
      this.handleMouseDown = bind(this.handleMouseDown, this);
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
      var eventPos, ref;
      eventPos = this.getEventPos(e);
      this.lastX = this.x;
      this.lastY = this.y;
      this.pixX = eventPos.x;
      this.pixY = eventPos.y;
      ref = this.model.patches.pixelXYtoPatchXY(this.pixX, this.pixY), this.x = ref[0], this.y = ref[1];
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
      var curPatch, i, len, results, type;
      curPatch = this.model.patches.patch(x, y);
      results = [];
      for (i = 0, len = eventTypes.length; i < len; i++) {
        type = eventTypes[i];
        results.push(this.emitAgentEvent(type, curPatch, this.mouseEvent(curPatch, e)));
      }
      return results;
    };

    Mouse.prototype.delegateEventsToAgentsAtPoint = function(eventTypes, x, y, e) {
      var agent, curPatch, i, j, k, len, len1, len2, patch, ref, ref1, type;
      curPatch = this.model.patches.patch(x, y);
      ref = curPatch.n.concat(curPatch);
      for (i = 0, len = ref.length; i < len; i++) {
        patch = ref[i];
        ref1 = patch.agentsHere();
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          agent = ref1[j];
          if (agent.hitTest(x, y)) {
            for (k = 0, len2 = eventTypes.length; k < len2; k++) {
              type = eventTypes[k];
              this.emitAgentEvent(type, agent, this.mouseEvent(agent, e));
            }
            return agent;
          }
        }
      }
    };

    Mouse.prototype.delegateEventsToLinksAtPoint = function(eventTypes, x, y, e) {
      var i, j, len, len1, link, mouseEvent, ref, type;
      ref = this.model.links;
      for (i = 0, len = ref.length; i < len; i++) {
        link = ref[i];
        if (link.hitTest(x, y)) {
          mouseEvent = this.mouseEvent(link, e);
          for (j = 0, len1 = eventTypes.length; j < len1; j++) {
            type = eventTypes[j];
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
      var agent, i, len, mouseEvent, ref;
      ref = this.draggingAgents;
      for (i = 0, len = ref.length; i < len; i++) {
        agent = ref[i];
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
      var agent, agentId, agents, agentsHere, breedname, curPatch, i, j, len, len1, name, patch, ref;
      agentsHere = {};
      agents = [];
      curPatch = this.model.patches.patch(x, y);
      agents = u.clone(this.model.links);
      ref = curPatch.n.concat(curPatch);
      for (i = 0, len = ref.length; i < len; i++) {
        patch = ref[i];
        agents = agents.concat(patch.agentsHere());
      }
      for (j = 0, len1 = agents.length; j < len1; j++) {
        agent = agents[j];
        if (agent.hitTest(x, y)) {
          if (agentsHere[name = agent.breed.name] == null) {
            agentsHere[name] = {};
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
