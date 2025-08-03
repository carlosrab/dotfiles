# Nixpkgs

Files in this directory are our nixpkgs configuration that serves to easily replicate my development setup in different devices and environments.

## Getting Started

### MacOS

1. Install xcode:

```
xcode-select --install
```

1. Install nix either through standard installation or determinate systems:
   1. Determinate systems:
  ```
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```

1. Get the nix flake from github:

```
git clone https://github.com/carlosrab/dotfiles.git
```

1. First nix darwin run:

```
nix run nix-darwin/nix-darwin-25.05#darwin-rebuild switch -- --flake=.#<flake name>
```


## Updating packages

1. Run nix update

```
nix flake update
```

2. Run rebuild command:

```
darwin-rebuild switch --flake .#<flake name>
```

## Garbage collection

```
nix-store --gc
```

## TODO

* [x] define a convention for dotfiles.
* [x] add git details and configure to push to gitlab/gh or other.
* [x] ensure zsh is part of the basic setup with the proper configuration.
* [x] stretch / break configuraiton into smaller modules if necessary
* [x] configure zsh ergonomics/plugins autocomplete, autosuggestion, ~fzf~, ~lazygit~, ~bat~, ~ripgrep~.
* [x] shell aliases
* [x] configure github/gitlab
* [x] autogenerate or autofill or something - ssh if possible or use 1password cli to get ssh key.
* [x] improve fzf integration with git, bat and z. https://www.youtube.com/watch?v=mmqDYw9C30I
* [ ] figure out a way to use nixpkgs but with my own dotfiles if possible. some home-manager configurations get tricky.
  * [ ] consider using an additional dotfiles folder that home-manager uses as reference or test if I do not even need to feed the dotfiles through home-manager. make sure to version control dotfiles.
* [ ] configure nvim
* [ ] configure tmux
* [ ] test pushing this configuration to a remote/virtual/or new machine. for this the easiest may involve making the repo public in github or gitlab.

## Sources

Followed: https://www.youtube.com/watch?v=Z8BL8mdzWHI

And these other sources:
* https://kristianfreeman.com/my-starter-macos-nix-config
* https://gist.github.com/jmatsushita/5c50ef14b4b96cb24ae5268dab613050
  * https://www.youtube.com/watch?v=KJgN0lnA5mk


### Useful pages

1. Nix directory: https://search.nixos.org/
2. For the nix-darwin manual run the `darwin-help` command.
3. Documentation regarding nix modules can be found in https://mynixos.com.

### Examples

1. https://github.com/schickling/dotfiles/tree/main
2. https://github.com/shelken/nix-config
3. https://github.com/fufexan/dotfiles/tree/main