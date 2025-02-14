# Nixpkgs

Files in this directory are our nixpkgs configuration that serves to easily replicate my development setup in different devices and environments.

## Starting from scratch

### MacOS

1. Install nix using the DeterminateSystems installer:
  ```
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```
1. Get nix configuration from github:
  ```
  TBD
  ```
1. First home-manager run:
  ```
  nix run github:nix-community/home-manager -- switch --flake .
  ``` 

## Home Manager

Together with home manager nixpkgs helps manage dotfiles as well. So ideally I do not need to maintain a separate repository for dotfile configurations.

## Experimental

I am currently testing this setup and hopefully it will result in an easy to use pattern for current and future setups.

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