with import <nixpkgs> {};
let haskellPackages = pkgs.haskellPackages_ghcjs.override {
      extension = self: super: {
        oHm = self.callPackage ./oHm {};
        mvc = self.callPackage ./oHm/mvc.nix {};
        ohmChatServer = self.callPackage ./chat-server.nix {};
        # client = self.callPackage ./. {};
        # cabal = self.callPackage ./cabal.nix {};
        # cabalInstall_1_22_0_0 = self.callPackage ./cabal-install.nix {};
      };
    };
    inherit (haskellPackages) ghc aeson ghcjsBase ghcjsDom ghcjsPrim
                              oHm ohmChatServer lens pipes pipesConcurrency mvc profunctors;
    npm = pkgs.nodePackages.npm;
    browserify = pkgs.nodePackages.browserify;

    client = stdenv.mkDerivation {  
        name = "chat-client";  
        version = "1.0";
        src = ./.;
        buildInputs = [ ghc aeson ghcjsBase ghcjsDom ghcjsPrim
                        oHm ohmChatServer lens pipes pipesConcurrency mvc profunctors
                        npm browserify closurecompiler
                      ];
        buildPhase = ''
          mkdir -p node_modules
          HOME=$(pwd) npm install
          mkdir -p build
          browserify src/deps.js -o build/vendor.js
          ghcjs -O3 -Wall       \
                -outputdir build \
                -DGHCJS_BROWSER \
                -o Main         \
                build/vendor.js \
                vendor/*.js \
                src/*.hs \
        '';
        installPhase = ''
          mkdir -p $out
          echo "mkdir"
          cp node_modules/twitter-bootstrap-3.0.0/dist/css/bootstrap.min.css $out
          echo "cp 1"
          cp src/index.html $out
          echo "cp 2"
          cp -R Main.jsexe/*.js $out/
          echo "cp 3"
         
          closure-compiler $out/all.js --compilation_level=ADVANCED_OPTIMIZATIONS > $out/all.min.js
          gzip --best -k $out/all.min.js
        '';
      };

in client 
  # { inherit (haskellPackages) ghc aeson ghcjsBase ghcjsDom ghcjsPrim
  #                             oHm ohmChatServer lens pipes pipesConcurrency mvc profunctors;
  #   inherit (pkg.nodePackages)  npm browserify;
  #   closurecompiler = pkgs.closurecompiler;
  # }