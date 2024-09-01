{
  description = "Nix flake to activate rescue mode on Hetzner servers and deploy NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-anywhere.url = "github:numtide/nixos-anywhere";
  };

  outputs = { self, nixpkgs, sops-nix, nixos-anywhere, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
    in
    {
      packages.x86_64-linux = {
        devShells.x86_64-linux.default = pkgs.mkShell {
          shellHook = ''
            echo ""
            echo "Welcome to NixOS deployment shell"
            echo "================================="
            echo ""
            echo "Getting Started"
            echo "---------------"
            echo ""
            echo " 1. Set up sops-nix and add your Hetzner Robot username and password to it."
            echo ""
          '';
          nativeBuildInputs = with pkgs; [
            curl
            git
            jq
            sops
          ];
        };

        # Package for activating rescue mode
        activate-rescue-mode = pkgs.writeShellScriptBin "activate-rescue-mode" ''
          #!/usr/bin/env bash

          echo "Decrypting secrets..."
          HETZNER_INSTALLIMAGE_WEBSERVICE_USERNAME=$(sops -d ./secrets/hetzner_username.sops)
          HETZNER_INSTALLIMAGE_WEBSERVICE_PASSWORD=$(sops -d ./secrets/hetzner_password.sops)

          echo "Activating rescue mode on all servers and deploying NixOS configurations..."

          for SERVER_IP in ${toString fingerprints}; do
            echo "Activating rescue mode for $SERVER_IP..."
            ./scripts/activate-rescue-mode.sh $HETZNER_INSTALLIMAGE_WEBSERVICE_USERNAME $HETZNER_INSTALLIMAGE_WEBSERVICE_PASSWORD $SERVER_IP

            echo "Deploying NixOS configuration to $SERVER_IP..."
            nixos-anywhere --flake .#mySystem --target-host root@$SERVER_IP --use-remote-sudo --ask-pass --build-on-remote
          done
        '';

        # Placeholder for additional scripts
        another-script = pkgs.writeShellScriptBin "another-script" ''
          #!/usr/bin/env bash
          echo "This is another script. Add your logic here."
        '';
      };

      apps = {
        activate-rescue-mode = {
          type = "app";
          program = "${self.packages.x86_64-linux.activate-rescue-mode}/bin/activate-rescue-mode";
        };
        another-script = {
          type = "app";
          program = "${self.packages.x86_64-linux.another-script}/bin/another-script";
        };
      };
    };
}
