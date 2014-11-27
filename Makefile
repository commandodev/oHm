ALL_JS=Main.jsexe/all.js
JS_DEPS=src/deps.js
GHCJS_SOURCE_FILES=src/Virtual.hs src/Render.hs src/Main.hs src/Messages.hs src/Ajax.hs src/HTML.hs
VENDOR=build/vendor.js
BOOTSTRAP=node_modules/twitter-bootstrap-3.0.0/dist/css/bootstrap.min.css

all: site

minified: $(ALL_JS)
	node_modules/closurecompiler/bin/ccjs  $(ALL_JS) --compilation_level=ADVANCED_OPTIMIZATIONS > dist/all.min.js
	gzip --best -k dist/all.min.js

site: $(ALL_JS) $(BOOTSTRAP)
	mkdir -p dist
	cp $(BOOTSTRAP) dist/
	cp src/index.html dist/
	cp $(ALL_JS) dist/

.cabal-deps: bellringer.cabal
	cabal install --only-dependencies --ghcjs
	touch .cabal-deps

$(BOOTSTRAP):
	mkdir -p node_modules
	npm install

$(VENDOR): $(JS_DEPS)
	mkdir -p build
	browserify $(JS_DEPS) -o $(VENDOR)

$(ALL_JS): $(VENDOR) .cabal-deps $(GHCJS_SOURCE_FILES)
	ghcjs -Wall \
	  -O3 \
	  -DGHCJS_BROWSER \
	  -o Main \
      $(VENDOR) \
      $(GHCJS_SOURCE_FILES)
