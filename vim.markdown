## Building a Neovim Installation in Nix

This uses a set of tools to build out up a neovim installation.  It's not full repeatable as a lot of plugins are 
loaded using lazy.

* the home-manager neovim program
* uses custom `vimUtils.buildVimPlugin` nix function to build plugins that aren't in nix
* also uses `Lazy` from `init.lua` to load a bunch of plugins (non-repeatable)

## TODO

- [ ] the fennel files are not in a nix package.  Besides this, the lazy lock file is also not in nix.
- [ ] there's a lazy bug below which makes it impossible to mix nix vim packges with lazy packages
- [ ] does vim-nix have anything useful

## Lazy Bug

There's a bug in Lazy that will alter the `runtimepath` significantly.  The plugins that had been loaded by nix no longer work at this point.

[awesome-vim]: https://github.com/rockerBOO/awesome-neovim?tab=readme-ov-file#search
[vim-section]: https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/vim.section.md
[nix-vim-utils]: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/vim-utils.nix#L408

