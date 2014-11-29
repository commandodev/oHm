ALL_JS=Main.jsexe/all.js
JS_DEPS=src/deps.js
GHCJS_SOURCE_FILES=src/*.hs
VENDOR=build/vendor.js
DIST=dist/

all: site

hlint:
	hlint --cpp-define=HLINT=true $(GHCJS_SOURCE_FILES)

minified: $(ALL_JS)
	node_modules/closurecompiler/bin/ccjs  $(ALL_JS) --compilation_level=ADVANCED_OPTIMIZATIONS > $(DIST)/all.min.js
	gzip --best -k $(DIST)/all.min.js

site: $(DIST) $(DIST)/all.js $(DIST)/index.html $(DIST)/markets.json $(DIST)/bootstrap.min.css

$(DIST):
	@mkdir -p $(DIST)

$(DIST)/bootstrap.min.css:
	cp node_modules/twitter-bootstrap-3.0.0/dist/css/bootstrap.min.css $(DIST)

$(DIST)/all.js: $(ALL_JS)
	cp $< $(DIST)

$(DIST)/index.html: src/index.html
	cp $< $(DIST)

$(DIST)/markets.json: data/markets.json
	cp $< $(DIST)

.cabal-deps: bellringer.cabal
	cabal install --only-dependencies --ghcjs
	@touch .cabal-deps

.node-deps: package.json
	@mkdir -p node_modules
	npm install
	@touch .node-deps

$(VENDOR): .node-deps $(JS_DEPS)
	@mkdir -p build
	browserify $(JS_DEPS) -o $(VENDOR)

$(ALL_JS): $(VENDOR) .cabal-deps .node-deps $(GHCJS_SOURCE_FILES)
	ghcjs -Wall \
	  -outputdir build \
	  -DGHCJS_BROWSER \
	  -H16m \
	  -o Main \
      $(VENDOR) \
      $(GHCJS_SOURCE_FILES)
