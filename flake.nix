{
  description = "ezhttp: HTTP client and server for Bend 2";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # bendlang/bend's flake at the commit that packages 2.0.36 (the v2.0.36 tag
  # still packages 2.0.35)
  inputs.bend = {
    url = "github:bendlang/bend/eebc18cd04daeade06c3f68c3c96c1faefd3462f";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ez 1.3.0's bend follows this flake's bend:
  # ez, `ez prove` and bolt all build on 2.0.36.
  inputs.ez = {
    url = "github:Emerging-Patterns/ez";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.bend.follows = "bend";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      version = "0.8.0"; # x-release-please-version
      ez = inputs.ez.lib.${system};
      ezBin = inputs.ez.packages.${system}.default;
      bend = inputs.bend.packages.${system}.default;
      bolt = ez.toolPackage { name = "bolt"; src = self; inherit bend; wrapFlags = [ "--gpu" "off" ]; };
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
        # ENTRY.bend states the laws on main.bend and client.bend, which
        # reach the wire effect, so its verdict is SOME PROOFS FAIL; its only
        # error may be the list of defs relying on foreign code.
        entry = pkgs.runCommand "ezhttp-entry" {
          nativeBuildInputs = [ bend ];
          BEND_LIB = ez.bendLib ./ez.lock.toml;
        } ''
          export HOME=$TMPDIR
          cp -r ${self} src && chmod -R u+w src && cd src
          out_entry=$(bend ENTRY.bend 2>&1 || true)
          echo "$out_entry" | head -n 2
          [ "$(echo "$out_entry" | sed -n 1p)" = "SOME PROOFS FAIL" ] || exit 1
          echo "$out_entry" | sed -n 2p \
            | grep -Eq '^Error: [0-9]+ defs? rel(y|ies) on unsafe or foreign code:$' || exit 1
          if echo "$out_entry" | tail -n +3 | grep -v '^- ' | grep -q .; then
            echo "$out_entry"; exit 1
          fi
          touch $out
        '';
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
          export EZ_LIBSSL=${pkgs.openssl.out}/lib/libssl.so
          export SSL_CERT_FILE=''${SSL_CERT_FILE:-${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt}
        '';
      };
    };
}
