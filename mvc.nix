{ cabal, async, contravariant, managed, mmorph, pipes
, pipesConcurrency, transformers
}:

cabal.mkDerivation (self: {
  pname = "mvc";
  version = "1.0.2";
  src = ./deps/mvc;
  buildDepends = [
    async contravariant managed mmorph pipes pipesConcurrency
    transformers
  ];
  meta = {
    description = "Model-view-controller";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
