{ cabal, binary, deepseq, extensibleExceptions, filepath, HUnit
, QuickCheck, regexPosix, testFramework, testFrameworkHunit
, testFrameworkQuickcheck2, time
}:

cabal.mkDerivation (self: {
  pname = "Cabal";
  version = "1.22.0.0";
  src = ./Cabal;
  buildDepends = [ binary deepseq filepath time ];
  testDepends = [
    binary extensibleExceptions filepath HUnit QuickCheck regexPosix
    testFramework testFrameworkHunit testFrameworkQuickcheck2
  ];
  meta = {
    homepage = "http://www.haskell.org/cabal/";
    description = "A framework for packaging Haskell software";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
