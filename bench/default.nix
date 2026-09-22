# ureq/hyper vs ezhttp bench: native Bend driver + Rust ref + Nix-embedded harness.
# No checked-in *.py / *.rs — compare + Rust sources live in .nix and are written
# with pkgs.writeText at eval time.
#
# Fairness: client and server timings are in-process. hey generates load outside
# the servers. Timing is not part of the flake check.
{
  pkgs,
  lib,
  bend,
  bend-cc,
  self,
  ez,
}:

let
  llvm = pkgs.llvmPackages_19;
  bendLib = ez.bendLib (self + "/ez.lock.toml");

  # Sandbox-safe CC: nixpkgs clang (native ELF). BEND_LIB is the locked ezjson
  # tree, so ezhttp/json.bend resolves without a hub publish.
  drv = pkgs.stdenv.mkDerivation {
    pname = "ezhttp-bench-drv";
    version = "0.1.0";
    dontUnpack = true;
    nativeBuildInputs = [ bend llvm.clang ];
    buildPhase = ''
      cp -r ${self}/ezhttp ./ezhttp
      mkdir -p bench
      cp ${./main.bend} bench/main.bend
      cd bench
      export CC=${llvm.clang}/bin/clang
      export BEND_LIB=${bendLib}
      export BEND_NO_TELEMETRY=1
      bend main.bend -o ezhttp-bench
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp ezhttp-bench $out/bin/ezhttp-bench
    '';
    meta = {
      description = "Native ELF driver for ezhttp client/server/load benches";
      mainProgram = "ezhttp-bench";
    };
  };

  rustRef = import ./rust.nix { inherit pkgs lib; };

  compareText = import ./compare.nix {
    drvBin = "ezhttp-bench";
    rustBin = "ezhttp-rust-ref";
    heyBin = "hey";
  };
  comparePy = pkgs.writeText "ezhttp-http-compare.py" compareText;

  py = pkgs.python3;
  hey = pkgs.hey;

  makeRunner = mode: pkgs.writeShellApplication {
    name = if mode == "correctness" then "ezhttp-http-check" else "ezhttp-http-bench";
    runtimeInputs = [ drv rustRef py ] ++ lib.optional (mode != "correctness") hey;
    text = ''
      set -euo pipefail
      export EZHTTP_BENCH_DRV=${drv}/bin/ezhttp-bench
      export EZHTTP_BENCH_RUST=${rustRef}/bin/ezhttp-rust-ref
      export EZHTTP_BENCH_HEY=${hey}/bin/hey
      export EZHTTP_BENCH_WORK="''${EZHTTP_BENCH_WORK:-$(mktemp -d)}"
      export EZHTTP_BENCH_MODE=${mode}
      mkdir -p "$EZHTTP_BENCH_WORK"
      exec ${py}/bin/python ${comparePy} "$@"
    '';
  };

  checkBin = makeRunner "correctness";
  benchBin = makeRunner "all";

  # Flake check: correctness must pass. Timing is not part of this derivation.
  httpCheck = pkgs.runCommand "ezhttp-http-compare" {
    nativeBuildInputs = [ checkBin ];
  } ''
    export EZHTTP_BENCH_WORK="$PWD/work"
    mkdir -p "$EZHTTP_BENCH_WORK"
    ezhttp-http-check | tee $out
  '';
in
{
  inherit drv rustRef httpCheck;
  packages = {
    ezhttp-bench-drv = drv;
    ezhttp-rust-ref = rustRef;
    ezhttp-http-check = checkBin;
    ezhttp-http-bench = benchBin;
  };
  apps = {
    http-check = {
      type = "app";
      program = "${checkBin}/bin/ezhttp-http-check";
    };
    http-bench = {
      type = "app";
      program = "${benchBin}/bin/ezhttp-http-bench";
    };
  };
  checks = {
    http = httpCheck;
  };
}
