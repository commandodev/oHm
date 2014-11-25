FINAL_JS=Main.jsexe/all.js
JS_DEPS=src/deps.js
GHCJS_SOURCE_FILES=src/Main.hs
VENDOR=build/vendor.js

all: $(FINAL_JS)

$(VENDOR): $(JS_DEPS)
	-mkdir build
	browserify $(JS_DEPS) -o $(VENDOR)

$(FINAL_JS): $(VENDOR) $(GHCJS_SOURCE_FILES)
	ghcjs -Wall \
	  -O3 \
	  -o Main \
      $(VENDOR) \
      $(GHCJS_SOURCE_FILES)
