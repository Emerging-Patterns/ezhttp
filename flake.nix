{
  description = "ezhttp: HTTP client and server for Bend 2";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # bendlang/bend's flake at the commit that packages 2.0.38 (the v2.0.38 tag
  # may still package 2.0.37)
  inputs.bend = {
    url = "github:bendlang/bend/042e797ebd1cfc060603e2682879909fe86fa8c2";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.ez = {
    url = "github:Emerging-Patterns/ez";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.bend.follows = "bend";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      version = "0.19.0"; # x-release-please-version
      ez = inputs.ez.lib.${system};
      ezBin = inputs.ez.packages.${system}.default;
      bend = inputs.bend.packages.${system}.default;
      bolt = ez.toolPackage { name = "bolt"; src = self; inherit bend; wrapFlags = ez.rtsFlags bend [ "--gpu" "off" ]; };
      bend-cc = ez.bend-cc;

      bench = import ./bench {
        inherit pkgs bend bend-cc self ez;
        lib = pkgs.lib;
      };
    in {
      packages.${system} = {
        inherit bend bend-cc;
        ez = ezBin;
        inherit bolt;
      } // bench.packages;

      apps.${system} = bench.apps;

      checks.${system} = {
        proofs = ez.mkProofs { ez = ezBin; src = self; };
        lint = ez.mkLint { src = self; };
      } // bench.checks;

      devShells.${system}.default = ez.mkShell {
        src = self;
        packages = [
          bend
          bend-cc
          ezBin
          pkgs.openssl
          pkgs.cacert
          pkgs.python3
          pkgs.hey
          bench.packages.ezhttp-bench-drv
          bench.packages.ezhttp-rust-ref
          bench.packages.ezhttp-http-check
          bench.packages.ezhttp-http-bench
        ];
        extraHook = ''
          export BEND_LIBSSL=${pkgs.openssl.out}/lib/libssl.so.3
          export SSL_CERT_FILE=''${SSL_CERT_FILE:-${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt}
        '';
      };
    };
}
