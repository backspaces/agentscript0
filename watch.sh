#!/bin/bash

files="util.coffee shapes.coffee agentset.coffee agentsets.coffee model.coffee"
coffee --watch --map --join agentscript.coffee --compile $files &

exit

files="util.coffee shapes.coffee agentset.coffee agentsets.coffee model.coffee"
coffee  -cwlj agentscript.coffee -c $files

FILES="foo.coffee bar.coffee"
coffee  -cwlj baz.coffee -c $FILES



# coffee -mj agentscript.js -c $files