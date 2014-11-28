let
  pkgs = import <nixpkgs> {};
  node = pkgs.nodePackages;
  haskellPackages = pkgs.haskellPackages_ghcjs.override {
    extension = self: super: {
      mvc = self.callPackage ./mvc.nix {};
      mvcUpdates = self.callPackage ./mvc-updates.nix {};
    };
  };
in pkgs.callPackage ./. {
     inherit (haskellPackages) ghc pipes pipesConcurrency ghcjsDom mvc mvcUpdates;
     inherit (node) npm browserify;
   }
