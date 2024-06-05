{
  description = "NixOS systems and tools by mitchellh";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Build a custom WSL installer
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other packages
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flakes
    dagger = {
      url = "github:dagger/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Non-flakes
    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter/v0.9.1";
      flake = false;
    };

    vim-copilot = {
      url = "github:github/copilot.vim/v1.32.0";
      flake = false;
    };

    vim-marked = {
      url = "github:itspriddle/vim-marked/v1.0.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs: let
    # Overlays is the list of overlays we want to apply from flake inputs.
    overlays = [
      inputs.zig.overlays.default
    ];

    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
      system = "aarch64-linux";
      user   = "slim";
    };

    nixosConfigurations.vm-aarch64-prl = mkSystem "vm-aarch64-prl" rec {
      system = "aarch64-linux";
      user   = "slim";
    };

    nixosConfigurations.vm-aarch64-utm = mkSystem "vm-aarch64-utm" rec {
      system = "aarch64-linux";
      user   = "mitchellh";
    };

    nixosConfigurations.vm-intel = mkSystem "vm-intel" rec {
      system = "x86_64-linux";
      user   = "slim";
    };

    nixosConfigurations.wsl = mkSystem "wsl" {
      system = "x86_64-linux";
      user   = "slim";
      wsl    = true;
    };

    darwinConfigurations.macbook-pro-m1 = mkSystem "macbook-pro-m1" {
      system = "aarch64-darwin";
      user   = "slim";
      darwin = true;
    };

    darwinConfigurations.macbook-pro-x86 = mkSystem "macbook-pro-x86" {
      system = "x86_64-darwin";
      user   = "slim";
      darwin = true;
    };
  };
}
