#!/bin/sh
# export GHCJS_SOURCE_FILES="src/Virtual.hs src/Render.hs src/Main.hs src/Messages.hs src/Ajax.hs"

nix-shell -I . \
  --command 'ghcjs -O3 -Wall \
                   -o Main \
                   -outputdir build \
                   src/Francium/*.hs \
                   src/*.hs \
                   build/vendor.js'
