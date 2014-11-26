ALL_JS=Main.jsexe/all.js
JS_DEPS=src/deps.js
GHCJS_SOURCE_FILES=src/Virtual.hs src/Render.hs src/Main.hs src/Messages.hs
VENDOR=build/vendor.js
BOOTSTRAP=node_modules/twitter-bootstrap-3.0.0/dist/css/bootstrap.min.css

all: site

site: $(ALL_JS) $(BOOTSTRAP)
	mkdir -p dist
	cp $(BOOTSTRAP) dist/
	cp src/index.html dist/
	cp $(ALL_JS) dist/

$(BOOTSTRAP):
	mkdir -p node_modules
	npm install

$(VENDOR): $(JS_DEPS)
	mkdir -p build
	browserify $(JS_DEPS) -o $(VENDOR)

$(ALL_JS): $(VENDOR) $(GHCJS_SOURCE_FILES)
	ghcjs -Wall \
	  -O3 \
	  -o Main \
      $(VENDOR) \
      $(GHCJS_SOURCE_FILES)
