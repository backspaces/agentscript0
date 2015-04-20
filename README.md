### AgentScript

AgentScript is a minimalist Agent Based Modeling (ABM) framework based on [NetLogo](http://ccl.northwestern.edu/netlogo/) agent semantics.  Its goal is to promote the Agent Oriented Programming model in a highly deployable [CoffeeScript](http://coffeescript.org/)/JavaScript implementation. Please drop by our [Google Group](https://groups.google.com/forum/?hl=en#!forum/agentscript) to get involved. We have a gh-pages site [agentscript.org](http://agentscript.org/).

#### Documentation

Currently the documentation is hosted directly on our [GitHub Pages](http://backspaces.github.io/agentscript) or directly from [agentscript.org](http://agentscript.org/) from the docco generated html found in the doc/ directory.

[**util.coffee**](docs/util.html) The base module for all of the miscellaneous functions used by the rest of the project.

[**color.coffee**](docs/color.html) The color module for all browser colortypes: css strings, pixels, and rgba typed arrays.

[**colormaps.coffee**](docs/colormaps.html) The color maps module for creating color arrays of any type and size.

[**colormixin.coffee**](docs/colormixin.html) Utility to automatically add a new color to a class or object.

[**shapes.coffee**](docs/shapes.html) A simple turtle shapes module containing the default shapes and a few functions for getting at named shapes and adding your own shapes.

[**evented.coffee**](docs/evented.html) Our tiny and elegant Pub/Sub event module.

[**agentset.coffee**](docs/agentset.html) The core Array subclass used by Patches, Turtles, and Links.

[**patch.coffee**](docs/patch.html) The Patch class. Patches represent autonomous regions of space that other agents can read/write to. Patches are commonly treated as grid cells in cellular automata models.

[**patches.coffee**](docs/patches.html) The Agentset subclass for class Patches.

[**turtle.coffee**](docs/turtle.html) The Turtle class. Turtles are autonomous, often mobile entities. In many models, they are the main interacting unit.

[**turtles.coffee**](docs/turtles.html) The Agentset subclass for class Turtles.

[**link.coffee**](docs/link.html) The Link class. Links are connections between agents. They are often used to build models with graph or network structures.

[**links.coffee**](docs/links.html) The Agentset subclass for class Links.

[**model.coffee**](docs/model.html) The top level integration for all the agentsets, subclassed by all user models.

[**animator.coffee**](docs/animator.html) The clock that steps and draws models.

[**template.html**](docs/template.html) A trivial subclass of Model showing the basic structure for how you build your own models.  In addition, the models/ directory contains 10 simple models used in teaching NetLogo. You can [run the template model here.](models/template.html)

#### Add-ons

The extras/ directory contains libraries that are too specialized to be in the core AgentScript but are essential for certain applications.  They are compiled to JavaScript in the lib/ directory.

[**data.coffee**](docs/data.html) A 2D DataSet library for data best expressed as an array of numbers.  It includes the ability to treat Images as data, to parse GIS elevation .asc files, to create datasets from patch variables etc.  It includes analytic abilities like nearest neighbor and bilinear sampling, convolution with 3x3 kernels, and resampling datasets to different resolutions.

[**data.tile.js**](docs/data.tile.html) An addon to the DataSet library for creating datasets from data tiles. It includes methods for embedding a [Leaflet](http://leafletjs.com) map, and for binding a dataset to tiles loaded by a Leaflet layer. See the [tiledroplets model](models/tiledroplets.html) for an example.

[**fbui.coffee**](docs/fbui.html) A simple start at a User Interface abstraction, with JSON representing buttons, sliders, switches and menus.  Each item in the JSON tree modifies the state of the model, either directly by setting Model variables or indirectly by calling a method in class Model.

[**as.dat.gui.js**](docs/as.dat.gui.html) A [dat.GUI](https://code.google.com/p/dat-gui/) based UI using the JSON tree mentioned above to specify the UI. This gives AgentScript a sophisticated HTML/CSS/JavaScript as well as the distributed fbui above. See the [flock model](models/flock.html) for an example.

[**mouse.coffee**](docs/mouse.html) A trivial event based interface to the mouse, mainly for direct interaction with the model's graphic layers.  It converts raw mouse coordinates into patch coordinates.

#### Sample Models

The models/ directory contains tiny models used both as unit tests and as examples to get started with.  They usually print to the console.log, so opening the developer's JavaScript console will show model information. Often they are translations from NetLogo's model library.

[**ants.html**](models/ants.html) A model of ant foraging behavior incorporating a nest location and food pheromone diffusion.

[**buttons.html**](models/buttons.html) Stuart Kauffman's example of randomly connecting pairs of buttons in a pile resulting in a tipping point.

[**diffusion.html**](models/diffusion.html) Turtles randomly flying on a patch grid dropping a color which is diffused over the grid.

[**fire.html**](models/fire.html) A CA (cellular automata) based model of fire spreading and burn behavior.

[**flock.html**](models/flock.html) The classic "boids" model where turtles each follow three simple rules resulting in realistic flocking.

[**flockui.html**](models/flockui.html) The flock model with the as.dat.gui.js extra.

[**headlessflock.html**](models/headlessflock.html) The same classic "boids" model as above, only this time turtles are rendered as DOM elements instead of being drawn to a canvas.

[**gridpath.html**](models/gridpath.html) One of Knuth's great puzzles on the probability of all Manhattan traversals diagonally traversing a grid.

[**linktravel.html**](models/linktravel.html) Turtles traversing a graph of nodes and links.

[**nbody.html**](models/nbody.html) A simulation of the nonlinear gravitation of n bodies.

[**prefattach.html**](models/prefattach.html) An example of a dynamic graph where new links preferentially attach to the nodes that have the most links.  This results in a power-law distribution.

[**tspga.html**](models/tspga.html) A Traveling Sales Person solution via a Genetic Algorithm showing the rapid conversion of stochastic methods.

[**droplets.html**](models/droplets.html) A simple GIS model based on an ESRI asc elevation file where droplet turtles seek low-elevation patches. This example uses the data.js extra.

[**tiledroplets.html**](models/tiledroplets.html) A model similar to the above droplets.html, but here the droplets move on top of a Leaflet map, and elevation data is loaded from a tileserver as the map is panned. This example uses the data.js, data.tile.js, and as.dat.gui.js extras.

[**life.html**](models/life.html) An implementation of [Conway's Game of Life](http://en.wikipedia.org/wiki/Conway's_Game_of_Life) with a twist. This example demonstrates running multiple models on the same page and uses a small as.dat.gui.js interface.

[**wallfollower.html**](models/wallfollower.html) An interesting wall following model from NetLogo. A set of "buildings" are created on the patches. Turtles find them, then follow the wall, half of them to the right, the others to the left.

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
          model = new MyModel {
            div: "layers",
            size: 6,
            minX: -40,
            maxX: 40,
            minY: -40,
            maxY: 40
          }
                ...
          </script>
        </head>
        <body>
          <div id="layers"></div>
        </body>
      </html>

You can see this by running a sample model, then using the browser's View Page Source.

Often the models will print to the "JavaScript console" while they run.

#### Building a Model

Class Model is an "abstract class" with three abscract methods:

    startup() Called from Model ctor for loading files needed by model.
    setup()   Called during startup and by Model.reset()
    step()    Called by animator to advance the model one step

CoffeeScript modelers simply subclass ABM.Model, supplying the three abstract methods.  All the sample models do this, including the docs/ template example.

JavaScript modelers can simply replace the empty ABM.Model abstract methods:

    myModel = function () {
      var u = ABM.Util; // useful alias for utilities
      ABM.Model.prototype.startup = function () {...};
      ABM.Model.prototype.setup = function () {...};
      ABM.Model.prototype.step = function () {...};

      // Startup like CoffeeScript examples
      var model = new MyModel({
        div: "layers",
        size: 6,
        minX: -40,
        maxX: 40,
        minY: -40,
        maxY: 40
      })
      .debug() // Debug: Put Model vars in global name space
      .start();
    }

See [sketches/jsmodel.html](sketches/jsmodel.html) for a random walker in JavaScript.  We'll also have more of our models/ converted to JavaScript in the future.


#### Files

    Gulpfile.js         Gulp file for build, docs etc.
    LICENSE             GPLv3 License
    README.md           This file
    package.json        NPM Package file, see npm install below
    docs/               Docco documentation
    extras/             AgentScript extensions
    lib/                All .js/min.js files
    models/             Sample models
    sketches/           Very simple models showing gist-like hints
    src/                Component .coffee files for agentscript.coffee
    tools/              coffee-script.js and others

#### Build

If you are forking/pulling agentscript, install the dev dependencies with

    npm install

and build with

    npm run all

We're currently using [gulp](http://gulpjs.com/), along with several plugins:

    ls node_modules/

We rely on no globally installed npm modules.  We recommend you do *not* globally install gulp ([local/global discussion]( http://goo.gl/OhdWvO)).

There are two ways to run tasks:

* NPM: run build commands via the npm scripts installed in package.json.  For example,

        npm run docs

    will create the documentation from the source files.  This is equivalent to "gulp docs".  See the "scripts" section of package.json for all "npm run" commands.

* Gulp: run gulp commands directly.  If gulp is not installed globally (our default) you can easily run gulp by including "./node_modules/.bin" in your PATH or by calling it directly with `./node_modules/.bin/gulp`.  To see the available gulp tasks, simply run "gulp" which will list them.

Gulp is used to compile src/ and extras/ into lib/ as .js and .min.js source. We allow both .js and .coffee in our project.  We currently do not provide sourcemaps for the .coffee files.

Our primary tasks are run via `npm run <task>` where tasks are:

    watch         # Watch for source file updates, invoke build
    build         # compile and minify src/ and extras/ to lib/
    docs          # use docco on sources to create docs/
    all           # Compile coffee, minify js, create docs

We also have a few git tasks:

    git-diff      # git diff the core files
    git-prep      # build all, git add ., git status
    git-commit    # git commit, push to github
    git-pages     # checkout gh-pages, merge master, push to gh-pages, checkout master



#### Contribute

Before any commit, please make sure all the models work as expected; they are our "unit tests."  We'll be adding more, smaller tests, soon.  Generally the test models will run locally with a file:// url, but http://localhost is safer.

Similarly, make sure the docco files display correctly.  They can be built with `npm run docs`.  Use your browser on docs/ to test.  Note that all single line comments are converted into docs using Markdown.  Be careful not to mistakenly add a "code" comment to the docs!

Pull requests will be accepted without your building your own gh-pages as long as the tests run OK locally.  However, if you want to be awesome, once your pull request is accepted, merge your changes into the gh-pages branch, update the README.md, and send another pull request!

The typical workflow looks like:

* npm run watch - process files when they change.
* npm run all - compile & minify all code, create docs. Done before git add to insure everything is ready for git.
* npm run git-diff - diff all source and related files.  Good for creating complete commit comments. You may want to pipe this into your editor.
* npm run git-prep - in master, invokes "gulp all", git add ., git status.  Used prior to commiting, stages all files.  Remember to git rm any files that are removed so that remote correctly sync'ed.
* npm run git-commit - in master, commit locally and push to github
* npm run git-pages - checkout gh-pages branch, merge master, push to github, change back to master.

The git:pages task should be run with no watch task running, otherwise unintentional compiles will occur when changing to the gh-pages branch, bummer!  Similarly, be careful your editor isn't confused by the gh-pages change .. it completely changes your working directory twice!


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
