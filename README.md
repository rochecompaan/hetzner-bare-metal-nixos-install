# Nixos on Hetzner Dedicate Servers

Install Nixos on Hetzner dedicated servers with nixos-anywhere.

## Set up sops-nix

1. Create a directory named `keys/users` and put the GPG public keys for admins
   that will manage serves insided it.

2. Find the fingerprints of the GPG keys you want to add:

```shell
❯ gpg --list-keys roche@upfrontsoftware.co.za
sec   rsa4096 2023-12-17 [SC]
      CB28EBC0DBFF630B85BE20E0807ACF787AC92BEE
uid           [ultimate] Roché Compaan <roche@upfrontsoftware.co.za>
ssb   rsa4096 2023-12-17 [E]
```
The fingerprint is `CB28EBC0DBFF630B85BE20E0807ACF787AC92BEE`.

2. Create a `.sops.yaml` configuration and add the key fingerprints to it.
```yaml
keys:
  - &admin_roche CB28EBC0DBFF630B85BE20E0807ACF787AC92BEE
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - pgp:
      - *admin_roche
```

3. Create Hetzner Robot username and password secrets:

```shell
sops secrets/hetzner.json
```

Add your username and password:
```json
{
	"hetzner_robot_username": "your-user-name",
	"hezner_robot_password": "your-password"
}
```

## SSH fingerprint

NOTE: I was hoping to use the same GPG fingerprint to SSH into servers in rescue
mode don't have that working yet.

1. Upload your SSH public key to Hetzner and take note of the fingerprint.

2. Open `.sops.yaml` and it a new sections for fingerprints:
```
keys:
  - &admin_roche CB28EBC0DBFF630B85BE20E0807ACF787AC92BEE
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - pgp:
      - *admin_roche
fingerprints:
  - 1f:33:88:ff:1e:89:a9:c6:4e:88:ec:ff:15:04:e8:53
```

## Create flake.nix
```
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
    hetzner-deploy-scripts.url = "github:rochecompaan/hetzner-nixos-deploy";
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
          program = "${self.packages.x86_64-linux.activate-rescue-mode}/bin/activate-rescue-mode";
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
```

## Activate rescue mode

```
nix run .#activate-rescue-mode -- <server-ip>
```

## Generate hardware configuration

```
nix run .#generate-hardware-configuration -- <server-ip>
```

## Define remote systems

Create modules/base.nix with the common server config.

Update your flake with the list of servers:
```nix
servers = {
  server1 = {
    networking = {
      publicIP = "192.168.0.1";
      privateIP = "10.0.0.1";
      defaultGateway = "192.0.2.254";
      interfaceName = "ens3";
    };
  };

  mycity2 = {
    networking = {
      publicIP = "192.168.0.2";
      privateIP = "10.0.0.2";
      defaultGateway = "192.0.2.254";
      interfaceName = "ens3";
    };
  };
```
