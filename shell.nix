{ }:

with import <nixpkgs> {};
let haskellPackages = pkgs.haskellPackages_ghcjs.override {
      extension = self: super: {
        oHm = self.callPackage ./. {};
        mvc = self.callPackage ./mvc.nix {};
      };
    };
in lib.overrideDerivation haskellPackages.oHm (attrs: {
     buildInputs = [ haskellPackages.cabalInstall ] ++ attrs.buildInputs;
   })
