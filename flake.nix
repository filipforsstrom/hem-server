{
  description = "Hem server";

  inputs = {
    go-nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    go-nixpkgs,
    flake-utils,
  }: let
    nixosModule = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.services.hem-server = {
        enable = lib.mkEnableOption "Hem server";

        port = lib.mkOption {
          type = lib.types.port;
          default = 8080;
          description = "Port to listen on";
        };
      };

      config = lib.mkIf config.services.hem-server.enable {
        systemd.services.hem-server = {
          description = "Hem server";
          wantedBy = ["multi-user.target"];
          after = ["network.target"];
          serviceConfig = {
            ExecStart = "${self.packages.${pkgs.system}.default}/bin/hem-server";
            Restart = "always";
            Type = "simple";
            DynamicUser = "yes";
          };
          environment = {
            PORT = toString config.services.hem-server.port;
          };
        };
      };
    };
  in
    (flake-utils.lib.eachDefaultSystem (system: let
      gopkg = go-nixpkgs.legacyPackages.${system};
    in {
      packages.default = gopkg.buildGoModule {
        pname = "hem-server";
        version = "0.1.0";
        src = ./.;
        vendorHash = null;
      };

      apps.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/hem-server";
      };

      devShell = gopkg.mkShell {
        buildInputs = with gopkg; [go];
      };
    }))
    // {
      nixosModules.default = nixosModule;
    };
}
