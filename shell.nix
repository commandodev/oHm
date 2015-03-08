{ }:

with import <nixpkgs> {};
let haskellPackages = pkgs.haskellPackages_ghcjs.override {
      extension = self: super: {
        virtualDom = self.callPackage ./virtual-dom {};
        oHm = self.callPackage ./. {};
      };
    };

in pkgs.callPackage ./. {
     cabal = haskellPackages.cabal.override {
       extension = self: super: {
         buildTools = super.buildTools ++ [ haskellPackages.ghc.ghc.parent.cabalInstall ];
       };
     };
     inherit (haskellPackages) aeson ghcjsBase ghcjsDom ghcjsPrim virtualDom lens mvc pipes
                               pipesConcurrency profunctors stm time;
   }
