let
  pkgs = import <nixpkgs> {};
  haskellPackages = pkgs.haskellPackages.override {
    extension = self: super: {
      engineIo = self.callPackage <engine.io/engine-io> {};
      socketIo = self.callPackage <engine.io/socket-io> {};
      engineIoSnap = self.callPackage <engine.io/engine-io-snap> {};
      #engineIoYesod = self.callPackage ../../engine-io-yesod {};
      example = self.callPackage ./. {};
    };
  };

in pkgs.lib.overrideDerivation haskellPackages.example (attrs: {
     buildInputs = [ haskellPackages.cabalInstall ] ++ attrs.buildInputs;
   })
