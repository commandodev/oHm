#!/bin/sh
# export GHCJS_SOURCE_FILES="src/Virtual.hs src/Render.hs src/Main.hs src/Messages.hs src/Ajax.hs"

nix-shell -I . shell.nix \
  --command 'ghcjs -O3 -Wall \
                   -outputdir build \
                   src/Ohm/Internal/*.hs \
                   src/Ohm/*.hs \
                   build/vendor.js'
