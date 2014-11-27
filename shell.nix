let
  pkgs = import <nixpkgs> {};
  node = pkgs.nodePackages;
  haskellPackages = pkgs.haskellPackages_ghcjs.override {
    extension = self: super: {
    };
  };
in pkgs.callPackage ./. {
     inherit (haskellPackages) ghc pipes pipesConcurrency ghcjsDom;
     inherit (node) npm browserify;
   }
