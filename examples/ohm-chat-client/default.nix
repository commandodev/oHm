{ cabal, aeson, ghcjsBase, ghcjsDom, ghcjsPrim, lens, mvc, oHm
, ohmChatServer, pipes, pipesConcurrency, profunctors, stm, time
}:

cabal.mkDerivation (self: {
  pname = "ohm-chat-client";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  buildDepends = [
    aeson ghcjsBase ghcjsDom ghcjsPrim lens mvc oHm ohmChatServer pipes
    pipesConcurrency profunctors stm time
  ];
  meta = {
    license = self.stdenv.lib.licenses.unfree;
    platforms = self.ghc.meta.platforms;
  };
})
