{
  description = "A MindWM clipboard actions manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
      let
        geoip = pkgs.fetchurl {
          url = "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat";
          sha256 = "sha256-7S3prdeWI+Ll28WTDuOcxwN6fG4OzVi6Uotvc9YUV7U=";
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = [ ];
          buildInputs = with pkgs; [
            ipcalc dnsutils libmaxminddb
            jq yq xq
            freeplane
          ] ++ (with pkgs.python3.pkgs; [
              grpcio
              protobuf
              pydantic
              pyyaml
          ]);
          shellHook = ''
            export GEOIP_DB="${geoip}"
          '';
        };
      };
      flake = {
      };
    };
}
