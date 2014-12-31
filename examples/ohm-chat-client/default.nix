{ stdenv, aeson, ghc, oHm, ohmChatServer,
  lens, pipes, pipesConcurrency, ghcjsBase, ghcjsDom, ghcjsPrim, mvc, profunctors,
  npm, browserify, closurecompiler
}:

stdenv.mkDerivation rec {
  
  version = "1.0";
  name = "client";  
  src = ./.;
  buildInputs = [ ghc aeson ghcjsBase ghcjsDom ghcjsPrim
                  oHm ohmChatServer lens pipes pipesConcurrency mvc profunctors
                  npm browserify closurecompiler
                ];
  buildPhase = ''
    mkdir -p node_modules
    HOME=$(pwd) npm install
    mkdir -p build
    browserify src/deps.js -o build/vendor.js
    ghcjs -O3 -Wall       \
          -outputdir build \
          -DGHCJS_BROWSER \
          -o Main         \
          build/vendor.js \
          vendor/*.js \
          src/*.hs \
  '';
  installPhase = ''
    mkdir -p $out
    cp node_modules/twitter-bootstrap-3.0.0/dist/css/bootstrap.min.css $out
    cp src/index.html $out
    cp -R Main.jsexe/*.js $out/
    cp -R vendor/*.js $out/
    closure-compiler $out/all.js --compilation_level=ADVANCED_OPTIMIZATIONS > $out/all.min.js
    gzip --best -k $out/all.min.js
  '';
}
