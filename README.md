# Nixpkgs

Nix Flakes-based dotfiles configuration for macOS on Apple Silicon. Uses nix-darwin, home-manager, and nix-homebrew.

## Getting Started

### macOS

1. Install xcode:

```
xcode-select --install
```

2. Install nix via Determinate Systems:

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

3. Clone the repo:

```
git clone https://github.com/carlosrab/dotfiles.git ~/code/dotfiles
```

4. First nix-darwin run:

```
nix run nix-darwin/master#darwin-rebuild switch -- --flake=.#mbp
```

5. Subsequent rebuilds:

```
darwin-rebuild switch --flake .#mbp
```

## Updating packages

```bash
# Update all flake inputs
nix flake update

# Rebuild
darwin-rebuild switch --flake .#mbp
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
