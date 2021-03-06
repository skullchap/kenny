#!/bin/bash

## This example shows usage of own defined functions as 2nd parameter.
## It also shows simple authentication example using
## predefined variables in kenny.sh like 
## "$method" for determing if request method was GET or POST; 
## "$cookie" if there was one in request header.
## 
## Function kennyquery defines variable equal to query param.
## For example if request had param like 'password', 
## 'kennyquery password' creates variable $password, and it will contain 
## param 'password' if it existed in request.
###########################################################################

. kenny.sh      # or 'source kenny.sh', "includes" kenny.sh in this file at top
# down below needed if webapp files NOT located in the root dir of kenny.sh

cd examples/ex2
###########################################################################
# user defined function like auth() below
#
auth() {
    if [[ "$method" == "GET" ]]; then
        if [[ "$cookie" == "sessionToken=abc123" ]]; then
            cat index.html
        else
            cat auth.html
        fi
    elif [[ "$method" == "POST" ]]; then
        kennyquery password
        if [[ "$password" == "123" ]]; then
            cat index.html
        else
            echo "Wrong Password."
        fi
    fi
}

# kenny functions get only two parameters, 1st is route at which execute 2nd parameter
# which is some command like cat or something else
# if you want more specific with method of route, you can use kennyget or kennypost

kenny / auth # execute auth() at "/" route

# kennylive needed to put at the end to execute everything above, 
# without kennylive its not going to work

kennylive
###########################################################################



