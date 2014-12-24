{ cabal, aeson, ghcjsBase, ghcjsDom, ghcjsPrim, lens, mvc, pipes
, pipesConcurrency, profunctors, stm, time
}:

cabal.mkDerivation (self: {
  pname = "oHm";
  version = "0.1.0.0";
  src = ./.;
  buildDepends = [
    aeson ghcjsBase ghcjsDom ghcjsPrim lens mvc pipes pipesConcurrency
    profunctors stm time
  ];
  meta = {
    license = self.stdenv.lib.licenses.unfree;
    platforms = self.ghc.meta.platforms;
  };
})
