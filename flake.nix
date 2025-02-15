{
  description = "Slurm: A Highly Scalable Workload Manager";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        application = version: sha256:
          pkgs.stdenv.mkDerivation rec {
            pname = "slurm";
            inherit version;

            # N.B. We use github release tags instead of https://www.schedmd.com/downloads.php
            # because the latter does not keep older releases.
            src = pkgs.fetchFromGitHub {
              owner = "SchedMD";
              repo = "slurm";
              # The release tags use - instead of .
              rev =
                "${pname}-${builtins.replaceStrings [ "." ] [ "-" ] version}";
              inherit sha256;
            };

            outputs = [ "out" "dev" ];
            nativeBuildInputs = with pkgs; [ pkg-config libtool python3 perl ];
            buildInputs = with pkgs; [ munge libmysqlclient ];

            configureFlags = with pkgs; [
              "--with-munge=${munge}"
              "--sysconfdir=/etc/slurm"
            ];

            preConfigure = ''
              patchShebangs ./doc/html/shtml2html.py
              patchShebangs ./doc/man/man2html.py
            '';

            postInstall = ''
              rm -f $out/lib/*.la $out/lib/slurm/*.la
            '';

            enableParallelBuilding = true;
          };

      in {
        packages = rec {
          v23_02 = application "23.02.4.1"
            "sha256-sNZqC6F7Q05AqkKVVUG4mCO3JXRjVZBppt3VgRHf5+o=";
          default = v23_02;
        };
      });
}
