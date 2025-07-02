#!/bin/bash

# Set up Ruby gem environment for pixi
export GEM_HOME="${PIXI_PROJECT_ROOT}/.pixi/envs/default/share/rubygems"
export GEM_PATH="${GEM_HOME}:${PIXI_PROJECT_ROOT}/.pixi/envs/default/lib/ruby/gems/3.3.0"
export PATH="${GEM_HOME}/bin:${PATH}"