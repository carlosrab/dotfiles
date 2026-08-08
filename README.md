# Nixpkgs

Nix Flakes-based dotfiles configuration for macOS on Apple Silicon. Uses nix-darwin, home-manager, and nix-homebrew.

## Bootstrap A New Mac

This configuration targets Apple Silicon macOS and assumes the primary user is
`carlos`. Some Home Manager files are out-of-store symlinks back into this repo,
so clone it to the expected path:

```
~/code/dotfiles
```

### 1. Install Xcode Command Line Tools

```
xcode-select --install
```

### 2. Install Nix

Install Nix with the Determinate Systems installer:

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Open a new shell after the installer completes so Nix is available in `PATH`.

### 3. Clone This Repo

```
mkdir -p ~/code
git clone https://github.com/carlosrab/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
```

### 4. Validate Before Activating

Build the system derivation without applying it:

```
darwin-rebuild build --flake .#mbp
```

This catches most flake/package errors without changing the machine and without
requiring a sudo password.

On a brand-new machine, `darwin-rebuild` may not be installed yet. In that case,
skip this validation step until after the first activation.

### 5. First Activation

Use `nix run` to run `darwin-rebuild` before it is installed on the machine:

```
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#mbp
```

After this succeeds, `darwin-rebuild` is available directly.

### 6. Subsequent Changes

Validate:

```
darwin-rebuild build --flake .#mbp
```

Apply:

```
sudo darwin-rebuild switch --flake .#mbp
```

### 7. Manual Post-Activation Steps

Some macOS setup cannot be fully automated by nix-darwin:

- Sign in to 1Password and enable the 1Password SSH agent.
- Make sure the `dev` vault contains the items referenced by
  `home/modules/env/envrc`.
- Run `direnv allow ~/code` after confirming the generated `~/code/.envrc`.
- Grant macOS privacy/accessibility permissions for tools that request them,
  such as AeroSpace, LinearMouse, Google Drive, and Mullvad VPN.
- Sign in to GUI apps installed through Homebrew casks.

## Updating packages

```bash
# Update all flake inputs
nix flake update

# Validate
darwin-rebuild build --flake .#mbp

# Apply
sudo darwin-rebuild switch --flake .#mbp
```

## Garbage collection

```
nix-store --gc
```

## TODO

- [ ] configure nvim
- [ ] configure tmux
- [ ] test pushing this configuration to a new machine

## Sources

Followed: https://www.youtube.com/watch?v=Z8BL8mdzWHI

Other sources:
- https://kristianfreeman.com/my-starter-macos-nix-config
- https://gist.github.com/jmatsushita/5c50ef14b4b96cb24ae5268dab613050

### Useful pages

1. Nix package search: https://search.nixos.org/
2. For the nix-darwin manual run `darwin-help`.
3. Nix module options: https://mynixos.com
