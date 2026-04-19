# AGENTS.md

This file provides guidance to AGENTS when working with code in this repository.

## Overview

This is a Nix Flakes-based dotfiles configuration for macOS on Apple Silicon (aarch64-darwin). It uses:
- **Nix-Darwin** for macOS system-level configuration
- **Home-Manager** for user environment and application configuration
- **Nix-Homebrew** for managing Homebrew packages through Nix
- **1Password shell plugins** for SSH agent and CLI secret injection

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
flake.nix                          # Main entry point - defines inputs, outputs, machine config
darwin/configuration.nix           # macOS system config: Homebrew, system packages, fonts, defaults
home/home.nix                      # User config: packages, aliases, shell integration
home/modules/
  ├── git.nix                      # Git config, aliases, delta diff viewer
  ├── zsh.nix                      # Zsh shell: history, completions, Powerlevel10k, keybindings
  ├── ssh.nix                      # SSH config with 1Password agent integration
  ├── p10k/p10k.zsh               # Powerlevel10k theme config
  ├── aerospace/aerospace.toml     # AeroSpace tiling window manager
  └── env/envrc                    # Shared env variables for ~/code projects (direnv)
```

## Key Patterns

- **Machine target**: `mbp` (defined in flake.nix outputs)
- **Username**: `carlos` (parametrized throughout configs)
- **Modular home-manager**: Each tool gets its own module in `home/modules/`
- **`mkOutOfStoreSymlink`**: Used for configs that need to remain writable outside the Nix store (aerospace, envrc). Required when tools (e.g. direnv) need to modify file timestamps.
- **1Password integration**: SSH agent socket at `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`, plus `op read` in envrc for injecting secrets via direnv.
## Adding New Configuration

- **System packages/apps**: Add to `darwin/configuration.nix` (Homebrew casks/formulae or nixpkgs)
- **User packages**: Add to `home/home.nix` in `home.packages`
- **New tool config**: Create module in `home/modules/` and import in `home/home.nix`
- **Editable config files**: Use `mkOutOfStoreSymlink` when the file must be writable at runtime
- **macOS defaults**: Add to `system.defaults` in `darwin/configuration.nix`
