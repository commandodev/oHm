{ cabal, aeson, ghcjsBase, mvc, pipes, pipesConcurrency, stm, time
}:

cabal.mkDerivation (self: {
  pname = "oHm";
  version = "0.1.0.0";
  src = ./.;
  buildDepends = [
    aeson ghcjsBase mvc pipes pipesConcurrency stm time
  ];
  meta = {
    license = self.stdenv.lib.licenses.unfree;
    platforms = self.ghc.meta.platforms;
  };
})
