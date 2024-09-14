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

## Activate rescue mode

```
nix run .#activate-rescue-mode -- <server-ip>
```

## Generate hardware configuration

```
nix run .#generate-hardware-configuration -- <server-ip>
```

## Define remote systems

