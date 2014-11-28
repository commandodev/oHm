{ stdenv, ghc, pipes, pipesConcurrency, ghcjsDom, mvc, mvcUpdates, npm, browserify
}:
stdenv.mkDerivation {
  name = "bell-ringer";
  version = "1.0";
  src = ./.;
  buildInputs = [ ghc ghcjsDom pipes pipesConcurrency mvc mvcUpdates npm browserify];
  buildPhase = ''
    mkdir -p node_modules
    HOME=$(pwd) npm install
    mkdir -p build
    browserify src/deps.js -o build/vendor.js
    ghcjs -O3 -Wall       \
          -DGHCJS_BROWSER \
          -o Main         \
          build/vendor.js \
          src/*.hs 
          
  '';
  installPhase = ''
    mkdir -p $out
    cp node_modules/twitter-bootstrap-3.0.0/dist/css/bootstrap.min.css $out
    cp src/index.html $out
    cp -R Main.jsexe/all.js $out/
  '';
}
