#!/bin/bash

## This example is a "hello world" of kenny.sh framework
## it only requires 3 lines to run simple webpages at specific route
###########################################################################

. kenny.sh      # or 'source kenny.sh', "includes" kenny.sh in this file at top
# down below needed if webapp files NOT located in the root dir of kenny.sh

cd examples/ex1
###########################################################################
# kenny functions get only two parameters, 1st is route at which execute 2nd parameter
# which is some command like cat or something else
# if you want more specific with method of route, you can use kennyget or kennypost

kenny / cat index.html
# kennylive needed to put at the end to execute everything above, 
# without kennylive its not going to work

kennylive
###########################################################################



