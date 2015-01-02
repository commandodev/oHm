with import <nixpkgs> {};
let haskellPackages = pkgs.haskellPackages_ghcjs.override {
      extension = self: super: {
        oHm = self.callPackage ./oHm {};
        mvc = self.callPackage ./oHm/mvc.nix {};
        ohmChatServer = self.callPackage ./chat-server.nix {};
        client = self.callPackage ./. {};
        # cabal = self.callPackage ./cabal.nix {};
        # cabalInstall_1_22_0_0 = self.callPackage ./cabal-install.nix {};
      };
    };
 
in pkgs.lib.overrideDerivation haskellPackages.client (attrs: {
     buildInputs = [ haskellPackages.cabalInstall_HEAD ] ++ attrs.buildInputs;
   })


# in pkgs.callPackage ./. {
#      cabal = haskellPackages.cabal.override {
#        extension = self: super: { 
#          buildTools = super.buildTools ++ [ haskellPackages.ghc.ghc.parent.cabalInstall_HEAD ]; 
#        };
#      }; 
#      inherit (haskellPackages) aeson ghcjsBase ghcjsDom ghcjsPrim oHm ohmChatServer lens mvc pipes
#                                pipesConcurrency profunctors stm;
     
#    }
