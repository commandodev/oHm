{ }:

with import <nixpkgs> {};
let haskellPackages = pkgs.haskellPackages_ghcjs.override {
      extension = self: super: {
        oHm = self.callPackage ./. {};
        mvc = self.callPackage ./mvc.nix {};
        # cabal = self.callPackage ./cabal.nix {};
        # cabalInstall_1_22_0_0 = self.callPackage ./cabal-install.nix {};
      };
    };
in pkgs.callPackage ./. {
     inherit (haskellPackages) cabal aeson ghcjsBase ghcjsDom ghcjsPrim lens mvc pipes
 pipesConcurrency profunctors stm time;
   }


# in lib.overrideDerivation haskellPackages.oHm (attrs: {
#      buildInputs = [ haskellPackages.cabalInstall_1_20_0_3 ] ++ attrs.buildInputs;
#    })
