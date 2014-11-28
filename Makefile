ALL_JS=Main.jsexe/all.js
JS_DEPS=src/deps.js
GHCJS_SOURCE_FILES=src/*.hs
VENDOR=build/vendor.js
BOOTSTRAP=node_modules/twitter-bootstrap-3.0.0/dist/css/bootstrap.min.css
DIST=dist

all: site

hlint:
	hlint --cpp-define=HLINT=true $(GHCJS_SOURCE_FILES)

minified: $(ALL_JS)
	node_modules/closurecompiler/bin/ccjs  $(ALL_JS) --compilation_level=ADVANCED_OPTIMIZATIONS > $(DIST)/all.min.js
	gzip --best -k $(DIST)/all.min.js

site: $(ALL_JS) $(BOOTSTRAP)
	mkdir -p $(DIST)
	cp $(BOOTSTRAP) $(DIST)/
	cp src/index.html $(DIST)/
	cp data/markets.json $(DIST)/
	cp $(ALL_JS) $(DIST)/

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
	  -DGHCJS_BROWSER \
	  -H16m \
	  -o Main \
      $(VENDOR) \
      $(GHCJS_SOURCE_FILES)
