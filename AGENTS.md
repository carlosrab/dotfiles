# AGENTS.md

This file provides guidance to AGENTS when working with code in this repository.

## Overview

This is a Nix Flakes-based dotfiles configuration for macOS on Apple Silicon (aarch64-darwin). It uses:
- **Nix-Darwin** for macOS system-level configuration
- **Home-Manager** for user environment and application configuration
- **Nix-Homebrew** for managing Homebrew packages through Nix

## Commands

```bash
# Apply configuration changes
darwin-rebuild switch --flake .#mbp

# Update all flake dependencies
nix flake update

# Garbage collection (clean up old derivations)
nix-store --gc

# macOS-specific help
darwin-help
```

## Architecture

```
flake.nix                    # Main entry point - defines inputs, outputs, machine config
darwin/configuration.nix     # macOS system config: Homebrew, system packages, fonts, defaults
home/home.nix               # User config: packages, aliases, shell integration
home/modules/
  ├── git.nix               # Git config, aliases, delta diff viewer
  ├── zsh.nix               # Zsh shell: history, completions, Powerlevel10k, keybindings
  ├── ssh.nix               # SSH config with 1Password agent integration
  └── p10k/p10k.zsh         # Powerlevel10k theme config
aerospace/aerospace.toml     # AeroSpace tiling window manager (symlinked via mkOutOfStoreSymlink)
```

## Key Patterns

- **Machine target**: `mbp` (defined in flake.nix outputs)
- **Username**: `carlos` (parametrized throughout configs)
- **Modular home-manager**: Each tool gets its own module in `home/modules/`
- **Aerospace symlink**: Uses `mkOutOfStoreSymlink` to keep config editable outside Nix store
- **1Password integration**: SSH agent socket at `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`

## Adding New Configuration

- **System packages/apps**: Add to `darwin/configuration.nix` (Homebrew casks/formulae or nixpkgs)
- **User packages**: Add to `home/home.nix` in `home.packages`
- **New tool config**: Create module in `home/modules/` and import in `home/home.nix`
- **macOS defaults**: Add to `system.defaults` in `darwin/configuration.nix`
