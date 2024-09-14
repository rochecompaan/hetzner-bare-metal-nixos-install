{
  description = "Nix flake to activate rescue mode on Hetzner servers and deploy NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    nixos-anywhere.url = "github:numtide/nixos-anywhere";
    sops-nix.url = "github:Mic92/sops-nix";
    hetzner-deploy-scripts.url = "github:rochecompaan/hetzner-deploy-scripts";
  };

  outputs = { self, nixpkgs, disko, deploy-rs, nixos-anywhere, sops-nix, hetzner-deploy-scripts }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      formatter.x86_64-linux = pkgs.alejandra;

      packages.x86_64-linux = {
        activate-rescue-mode = hetzner-deploy-scripts.packages.x86_64-linux.activate-rescue-mode;
        generate-hardware-config = hetzner-deploy-scripts.packages.x86_64-linux.generate-hardware-config;
      };

      apps = {
        activate-rescue-mode = {
          type = "app";
          program = "${self.packages.x86_64-linux.activate-and-deploy}/bin/activate-rescue-mode";
        };

        generate-hardware-config = {
          type = "app";
          program = "${self.packages.x86_64-linux.generate-hardware-config}/bin/generate-hardware-config";
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      # Development shell with curl, git, yq, and sops
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [
          pkgs.curl
          pkgs.git
          pkgs.yq
          pkgs.sops
        ];
      };
    };
}
