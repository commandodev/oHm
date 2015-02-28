{ mkDerivation, aeson, base, bytestring, containers, contravariant
, ghcjs-base, ghcjs-dom, ghcjs-prim, lens, mtl, mvc, pipes
, pipes-concurrency, profunctors, split, stdenv, stm, time
, transformers, virtual-dom
}:
mkDerivation {
  pname = "oHm";
  version = "0.1.0.1";
  src = ./.;
  buildDepends = [
    aeson base bytestring containers contravariant ghcjs-base ghcjs-dom
    ghcjs-prim lens mtl mvc pipes pipes-concurrency profunctors split
    stm time transformers virtual-dom
  ];
  license = stdenv.lib.licenses.bsd3;
}
