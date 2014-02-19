### AgentScript

AgentScript is a minimalist Agent Based Modeling (ABM) framework based on [NetLogo](http://ccl.northwestern.edu/netlogo/) agent semantics.  Its goal is to promote the Agent Oriented Programming model in a highly deployable [CoffeeScript](http://coffeescript.org/)/JavaScript implementation. Please drop by our [Google Group](https://groups.google.com/forum/?hl=en#!forum/agentscript) to get involved. We have a gh-pages site [agentscript.org](http://agentscript.org/).

#### Documentation

Currently the documentation is hosted directly on our [GitHub Pages](http://backspaces.github.io/agentscript) or directly from [agentscript.org](http://agentscript.org/) from the docco generated html found in the doc/ directory.

[**util.coffee**](docs/1-util.html): is the base module for all of the miscellaneous functions used by the rest of the project.

[**shapes.coffee**](docs/2-shapes.html): is a simple agent shapes module containing the default shapes and a few functions for getting the named shapes and adding your own shapes.

[**agentset.coffee**](docs/3-agentset.html) is the core array subclass used by patches, agents, and links.

[**agentsets.coffee**](docs/4-agentsets.html) contains the three subclasses of AgentSet: Patches, Agents, and Links along with the three classes they manage: Patch, Agent, and Link.

[**model.coffee**](docs/5-model.html) is the top level integration for all the agentsets and is subclassed by all user models. 

[**template.html**](docs/6-template.html) is a trivial subclass of Model showing the basic structure how you build your own models.  In addition, the models/ directory contains 10 simple models used in teaching NetLogo. You can [run the model here.](models/template.html) 

#### Add-ons

The extras/ directory contains libraries that are too specialized to be in the core AgentScript but are essential for certain applications.  They are compiled to JavaScript in the lib/ directory.

[**data.coffee**](docs/data.html) A 2D DataSet library for data best expressed as an array of numbers.  It includes the ability to treat Images as data, to parse GIS elevation .asc files, to create datasets from patch variables etc.  It includes analytic abilities like nearest neighbor and bilinear sampling, convolution with 3x3 kernels, and resampling datasets to different resolutions.

[**fbui.coffee**](docs/fbui.html) A simple start at a User Interface abstraction, with JSON representing buttons, sliders, switches and menus.  Each item in the JSON tree modifies the state of the model, either directly by setting Model variables or indirectly by calling a method in class Model.

[**mouse.coffee**](docs/mouse.html) A trivial event based interface to the mouse, mainly for direct interaction with the model's graphic layers.  It converts the mouse raw coordinates into patch coordinates.

#### Sample Models

The models/ directory contains tiny models used to test the system and offer examples to get started with.  These also are our our GitHub pages.  They usually print to the console.log, so opening the developer's JavaScript console will show model information.

[**ants.html**](models/ants.html) Ant foraging with nest and food pheromone diffusion. 

[**buttons.html**](models/buttons.html) Stuart Kauffman's example of randomly connecting pairs of buttons in a pile resulting in a tipping point.

[**diffusion.html**](models/diffusion.html) Agents randomly flying on a patch grid dropping a color which is diffused over the grid.

[**fire.html**](models/fire.html) A CA based spread of fire showing burn behavior.

[**flock.html**](models/flock.html) The classic "boids" model where agents use three simple rules resulting in realistic flocking.

[**gridpath.html**](models/gridpath.html) One of Knuth's great puzzles on the probability of all Manhattan  traversals diagonally traversing a grid.

[**linktravel.html**](models/linktravel.html) Agents traversing a graph of nodes and links.

[**nbody.html**](models/nbody.html) Nonlinear gravitation of n bodies.

[**prefattach.html**](models/prefattach.html) Example of a dynamic graph with new links preferentially attaching to nodes with most links.  This results in a power-law distribution.

[**tspga.html**](models/tspga.html) A Traveling Sales Person solution via a Genetic Algorithm showing the rapid conversion of stochastic methods.

[**droplets.html**](models/droplets.html) A simple GIS model based on ESRI asc elevation file with droplets agents which seek lowest elevation. Uses the data.js extension.

#### Sample Models Format

Our example models use CoffeeScript directly within the browser via `text/coffeescript` [script tags](http://coffeescript.org/#scripts):

      <html>
        <head>
          <title>AgentScript Model</title>
          <script src="agentscript.js"></script>
          <script src="coffee-script.js"></script>
          <script type="text/coffeescript">
          class MyModel extends ABM.Model
                ...
          model = new MyModel "layers", 13, -16, 16, -16, 16
                ...
          </script>
        </head>
        <body>
          <div id="layers"></div>
        </body>
      </html>

You may see this by running a sample model, then use the browser's View Page Source.

Often the models will print to the "JavaScript console" while they run.

#### Building a Model

Class Model is an "abstract class" with three abscract methods:

    startup() Called from Model ctor for loading files needed by model.
    setup()   Called during startup and by Model.reset()
    step()    Called by animator to advance the model one step

CoffeeScript modelers simply subclass ABM.Model, supplying the three abstract methods.  All the sample models do this, as does the docs/ template example.

JavaScript modelers can simply replace the empty ABM.Model abstract methods:

    myModel = function () {
      var u = ABM.util; // useful alias for utilities
      ABM.Model.prototype.startup = function () {...};
      ABM.Model.prototype.setup = function () {...};
      ABM.Model.prototype.step = function () {...};

      // Startup like CoffeeScript examples
      var model = new ABM.Model("layers", 13, -16, 16, -16, 16, true)
        .debug() // Debug: Put Model vars in global name space
        .start();
    }

See [sketches/jsmodel.html](sketches/jsmodel.html) for a random walker in JavaScript.  We'll also have more of our models/ converted to JavaScript in the future.


#### Files
    
    Cakefile            cake file for build, docs etc.
    LICENSE             GPLv3 License
    README.md           This file
    docs/               Docco documentation
    extras/             AgentScript extensions
    lib/                All .js/min.js and .map files
    models/             Sample models
    sketches/           Very simple models showing gist-like hints
    src/                Component .coffee files for agentscript.coffee
    tools/              coffee-script.js and others
    
#### Build

Cake is used to build agentscript.coffee from individual source files, and to compile into lib/ as agentscript.js, agentscript.min.js, and agentscript.map.  The map file allows debugging in Chrome via CoffeeScript source.

The "extras" are libraries that augment agentscript and are individually compiled into lib/ as .js, .min.js, and .map files by Cake.  Here are the primary cake tasks:

    cake watch         # Watch for source file updates, invoke builds
    cake all           # Compile coffee, minify js, create docs
    cake git:diff      # git diff the core and extras .coffee files
    cake git:prep      # cake all; git add/status
    cake git:commit    # commit locally, push to github
    cake git:pages     # checkout gh-pages, merge master, push to gh-pages, checkout master


If you are forking/pulling agentscript, install the dev dependencies with

    npm install

and build with

    cake all

We're currently using [coffeescript](http://jashkenas.github.io/coffee-script/extras/coffee-script.js), [shelljs](https://github.com/arturadib/shelljs), [uglifyjs](https://github.com/mishoo/UglifyJS), and optionally [docco](http://jashkenas.github.io/docco/).

All forked repos must be aware that we have a gh-pages branch.  This somewhat complicates the build workflow.  You should also make sure you are in the master at all times; our cake tasks should take care of all gh-pages branch usage.

Before any commit, please make sure all the models work as expected, they are our "unit tests".  We'll be adding more, smaller tests, soon. Similarly make sure the docco files display correctly.  They can be built with "cake all" or "cake doc". Note that all single line comments are converted into docs, using Markdown.  Be careful not to mistakenly add a "code" comment to the docs!

Pull requests will be accepted without your building your own gh-pages as long as both the tests run and the README.md runs OK locally.  Generally the test models and docs will run locally with a file:// url but http://localhost is safer.  Sublime/Textmate markdown viewers should work for this.

The typical workflow looks like:

* cake watch - compile coffee files when they change.
* cake all - compile & minify all code, create docs. Done before git add to insure everything is ready for git.
* cake git:diff - diff all source and related files.  Good for creating complete commit comments.
* cake git:prep - in master, invokes "cake all", git add ., git status.  Used prior to commiting, stages all files.  Remember to git rm any files that are removed so that remote correctly sync'ed.
* cake git:commit - in master, commit locally and push to github
* cake git:pages - checkout gh-pages branch, merge master, push to github, change back to master.

The git:pages task should be run with no watch task running, otherwise unintential compiles will occur with changing to the gh-pages branch.  Similarly, be careful your editor isn't confused by the gh-pages change .. it completely changes your working directory.  The cake git:pages task will warn you to be careful, prompting for a go-ahead.


#### License

Copyright Owen Densmore, RedfishGroup LLC, 2012, 2013<br>
http://agentscript.org/<br>
AgentScript may be freely distributed under the GPLv3 license:

AgentScript is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program, see LICENSE within the distribution.
If not, see <http://www.gnu.org/licenses/>.
