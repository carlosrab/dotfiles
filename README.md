# Nixpkgs

Files in this directory are our nixpkgs configuration that serves to easily replicate my development setup in different devices and environments.

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
* [] configure github/gitlab
* [~] autogenerate or autofill or something - ssh if possible or use 1password cli to get ssh key.
* [] improve fzf integration with git, bat and z. https://www.youtube.com/watch?v=mmqDYw9C30I
* [] configure tmux
* [] configure nvim
* [] test pushing this configuration to a remote/virtual/or new machine.